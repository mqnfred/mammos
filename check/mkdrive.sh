#! /usr/bin/env sh


echo "the root action can be found in $0"


function generate_partitions_file
{
    CHUNK=$1; COUNT=$2

    dd if=/dev/zero of=tmpdrive bs=${CHUNK} count=${COUNT}
    fdisk tmpdrive
    dd if=tmpdrive of=${PARTITIONS} bs=512 count=1
    /bin/rm -rf tmpdrive
}


function generate_drive
{
    CHUNK=$1; COUNT=$2

    dd if=/dev/zero of=${DRIVE} bs=${CHUNK} count=${COUNT}
    dd if=${PARTITIONS} of=${DRIVE} bs=1 count=512 conv=notrunc
    dd if=${STAGE1} of=${DRIVE} bs=1 count=436 conv=notrunc
    dd if=${STAGE2} of=${DRIVE} bs=512 seek=1 count=63 conv=notrunc
}


function enable_loopdevice
{
    if [ -n "`lsmod | grep loop`" ]; then
        sudo modprobe loop
    fi
}


function format_drive
{
    function apply_format
    {
        OFFSET=$1; BLOCKS=$2; BINARY="false";

        if [ "$3" -eq "80" ]; then
            BINARY="mkfs.minix -1";
        elif [ "$3" -eq "6" ]; then
            BINARY="mkfs.fat -v";
        fi

        ls /dev/loop0;
        if [ ! "$?" -eq "0" ]; then
            sudo "rm /dev/loop0; mknod -m=0666 /dev/loop0 b 7 0"
        fi

        LOOP=`sudo losetup --find --show -o$((512 * ${OFFSET})) ${DRIVE}`;
        ${BINARY} ${LOOP} ${BLOCKS};

        mkdir -p check/mnt;
        sudo mount ${LOOP} check/mnt;

        # L flag important (follow symbolic links)
        sudo cp -Lr check/rootfs/* check/mnt;

        sudo umount check/mnt;
        sudo /bin/rm -rf check/mnt;

        sudo losetup --detach ${LOOP};
    }

    echo "`fdisk -l ${DRIVE} | grep -E "^${DRIVE}.*"`" | while read line; do
        line="`echo "${line}" | tr -d '*' | sed -re 's/ +/ /g'`";

        OFFSET="`echo "${line}" | cut -d ' ' -f 2`";
        BLOCKS="`echo "${line}" | cut -d ' ' -f 4`";
        SYSTEM="`echo "${line}" | cut -d ' ' -f 5`";

        echo offset=$OFFSET sectors, blocks=$BLOCKS, system=$SYSTEM;
        apply_format ${OFFSET} ${BLOCKS} ${SYSTEM};
    done
}


if [ "$1" = "partition" ]; then
    generate_partitions_file 1M 16
else
    enable_loopdevice
    generate_drive 1M 16
    format_drive
fi

