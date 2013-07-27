#! /usr/bin/env sh


if [ "$1" = "bochs" ]; then
    BIOS_ROM=`locate bochs | grep -E 'BIOS-bochs-latest$'`
    VGABIOS_ROM=`locate bochs | grep -E 'VGABIOS-lgpl-latest$'`

    echo 6 | bochs-local -q 'boot:disk' "ata0-master: type=disk, path=$(DRIVE)"\
        'gdbstub: enabled=1, port=1234, text_base=0, data_base=0, bss_base=0'\
        "romimage: file=${BIOS_ROM}" "vgaromimage: file=${VGABIOS_ROM}" &
elif [ "$1" = "qemu" ]; then
    qemu-system-i386 -m 128 -hda ${DRIVE} -s -S &
else
    exit 1;
fi

sleep 0.5
gdb -x check/gdbinit
killall bochs; killall qemu-system-i386
