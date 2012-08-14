# MAMMOS

This a mammoth OS for mammoths by mammoths.

# Specifications and limitations

The mammos is not a piece of work designed to be useful to anybody, except as a
scholar work for the people working on it. Considering this purpose, and in
order to simplify greatly the developpement, many a limitation have been
settled.

## Summary

The following is a summary of the limitations of mammos. For more information
about each limitation, please refer to the sections below.

    - Disk size of 32MBytes maximum.
    - Disk sectors of 512 bytes
    - Block size of 1024 bytes, 2 sectors.
    - Minix filesystem v1.

## Disk and file system

First off, the sector size of each disk is considered to be 512 bytes. It is
not such an issue considering this is the setup of most HDD nowadays.

In order not to bother too much about 32 bit arithmetics in realmode, it has
been decided that supported hard disk drives be limited to 32 MBytes. This
allows the LBA to hold in one 16-bit register, explanations:

2 ^ 16 is the number of 512 bytes sectors which can be addressed. The size of a
sector being 512 bytes, the number of bytes reachable with a LBA of 16 bits is
exactly 2 ^ 16 * 0x400 = 0x2400 bytes. 0x2400 / 1024 / 1024 = 32MBytes.

The reading of the filesystem in realmode assembly turning out to be pretty
complex when trying to support multiple file systems/sector sizes/block sizes,
the only file system handled by mammos is the same as the first Linux kernels,
meaning Minix file system v1. A block size of 1024 bytes (2 sectors) is
assumed, unlike most actual filesystems (ext4 comes to mind) that determines a
block size of 4096 bytes.

## Memory

The memory is limited to 4GB, including the first MByte as well as the upper
GByte, reserved for I/O. The only endianness supported is little-endian.
