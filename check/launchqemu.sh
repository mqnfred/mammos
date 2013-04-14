#! /bin/sh


if [ -e qemu.pid ]; then
    kill -9 $(cat qemu.pid)
    rm qemu.pid
fi

qemu-system-i386 -m 4096 -s -S drive 2>&1 1>/dev/null &
echo $! > qemu.pid
