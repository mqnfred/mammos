# partitioning and MBR

use the old partition scheme (not GPT) with dead space before first partition.
partitioning using fdisk -c=nondos (default mode) which implies a dead space of
2047 sectors (offset of first partition 2048) the offset and sizes in the
following diagram are in sectors: offset on the left, size on the right.

                      0 +-----------------+
                        |       mbr       | 1
                      1 +-----------------+
                        |   dead space    | 2047
                   2048 +-----------------+
                        |   partition 1   | ...
                    ... +-----------------+
                        |   partition 2   | ...
                    ... +-----------------+
                        |   partition 3   | ...
                    ... +-----------------+
                        |   partition 4   | ...
                    ... +-----------------+

# a word about the drive creation utilities

the idea behind the check/mkdrive.sh script is to generate a bootable drive by
putting together everything our OS is composed of and needs: first, a partition
table adapted to our OS, which can be edited by calling fdisk via make
partitions. the second element is the blending of the MBR (stage1.bin) code in
the first 436 bytes of the drive. the third is the blending of the stage2.bin
code right after said MBR, for like 63 sectors atm (63*512 bytes is big
enough.)

the most complicated part is relative to the filesystems. the fs supported are
currently fat12/16 as well as minix v1. the system ids of those are 0x1, 0x6
and 0x80. if you chose something else than this whlie partitionning via fdisk,
everything will go wrong.

once the partition table is defined by you, the disk will be automatically
formated (that's why you need to sudo,) and check/rootfs/ will be copied in all
the partitions the same way.

# the mbr role

the first role of the mbr code (stage 1) is to setup the stack right at 0x7C00.

its second role is to load an arbitrary amount of dead space (stage 2, maybe
start with 63 sectors) at offset 0x7E00 thanks to unreal mode (%es with 4GB
limit). it's done by loading each sectors with the BIOS 0x13 syscall at an
arbitrary offset like 0x500 for example (right above the IVT and BDA.) and then
moving them to the appropriate address (thanks to %es) like 0x7E00 and beyond.

once the stage 2 is loaded at the correct offset, switch to protected mode and
jump into the 32bits new code at 0x7E00.

            0xFFFFF +-------------------------+
                    |      video memory       |
            0xA0000 +-------------------------+
                    |          EBDA           |
            0x80000 +-------------------------+
                    |           ...           |
                    |       stage 2 heap      |
         stage2_end +-------------------------+
                    |       stage 2 code      |
             0x7E00 +-------------------------+
                    |       stage 1 code      | 0x200 (512 bytes)
             0x7C00 +-------------------------+
                    |          stack          |
                    |           ...           |
               %esp +-------------------------+
                    |       free space        |
              0x500 +-------------------------+
                    |           BDA           | 0x100 (256 bytes)
              0x400 +-------------------------+
                    |           IVT           | 0x400 (1024 bytes)
                0x0 +-------------------------+

# a peek at the stage 2

the role of the dead space code, or stage 2, is to load the os just as the role
of the mbr code, or stage 1, was to load the stage 2. the stage 2 code is
written in C in order to facilitate manipulation of the filesystems on which
the kernel is stored. this is only possible because the processor was switched
to protected mode during stage 1.

the stage2 main function takes one argument, which is the position of the
partition table in physical memory (something like 0x7C00 + 0x1BE.) the stage2
finds the bootable partition. the stage2 also has a very basic heap, as can be
seen on the diagram above.

the elf kernel loading is not handled yet, but there is a layman's way of
loading a flat binary anyway with the /boot/config file. here is an example of
the basic layout of the file:

/boot/kernel.img 0x100000
/boot/initrd 0x500000

this is a list of all files to load in memory and the address at which to do
it. considering the kernel is a flat binary, this is pretty straightforward.

the loading is also very dependent on the filesystem in use. currently only
minixv1 fs is supported, but others can be added pretty easily. the driver only
consists of 3 functions:

    1. an init function which is performing the various initializations needed
    by the filesystem. it is executed as soon as the filesystem is identified.

    2. a get_size function which returns the size of the given file (passed as
    a const char *)

    3. the main load_file function, which loads the the file at the given
    address and returns the number of bytes loaded.

## stage2, an overview of the the minixv1 filesystem driver

the minix filesystem uses blocks as a method of measuring. a block is 1024
bytes (default,) which means 2 sectors of 512 bytes. #i represents the number
of inodes in the filesystem and #z the number of datazones. see below for more
information about those.

we are talking about the v1 filesystem so inodes are 16 bytes long. we'll take
the example of a 16MB partition. this is 5120 inodes (as can be seen when
formatting) for a total of 15360 blocks.

              0 +-----------------+
                |    boot block   | 1
              1 +-----------------+
                |    superblock   | 1
              2 +-----------------+
                |      imap       | 1 (5120 / (1024 * 8)) <- /8 because bitmap
              3 +-----------------+
                |      zmap       | 2 (~15360 / (1024 * 8)) <- 1,8, so 2 blocks
              5 +-----------------+
                |   inode table   | ~150 (5120 * 32 / 1024)
            165 +-----------------+
                |    data zones   |
                |       ...       | a hell of a lot
                |       ...       |
                +-----------------+


    1. the boot block is here in case the disk itself is formatted (not a
    partition.) it's not used in our scenario.

    2. the superblock is 1 block long but contains actually only a few bytes
    long structure holding important information (max number of blocks, inodes,
    first datazone offset, etc.)

    3. the imap is a bitmap with 1 for an occupied inode, 0 for a free one. its
    size in blocks is then: 5120 / 8 / 1024 = 1

    4. the zmap is a bitmap with 1 for an occupied zone and 0 for a free one. a
    datazone is a block which is intended to receive data (there are blocks
    like the ones in the inode table which are therefore not datazones.)
    its size is: ~15360 / 8 / 1024 = ~1,8, so it occupies 2 blocks. 15360
    represents the number of total blocks, so the number of datazones (or
    simply zones) is actually 15360 - sizeof(imap, zmap, superblock, boot
    block, inode table...).

    5. the inode table is a chunk of blocks which contains the actual inodes.
    an inodes, as for most filesystems, contains all the metadata regarding a
    file, except its name, which is contained in the directory entries (see
    below.) its size is 5120 * 32 / 1024 = 5120 / 32 = ~150+ blocks.

    6. data zones come after that. the "first data zone block" field in the
    superblocks indicates 165, which matches more or less the 150 + 5 blocks
    we processed above.

an inode is composed of a mode (directory, block device??), permissions etc,
but mainly a zones array. this array contains offset of zones composing the
file.

in the case of a directory, the inode contains offset to zones containing
directory entries. a directory entry represents another file or directory
contained in this directory. it's composed of the offset of the
file/directory's inode in the inode table, as well as its name.

for example, the path /boot/file1. here, the INODE TABLE column represents
three inodes of 16 bytes each.contained in the first block of the ~150
composing the whole inode table.

each entry in the datazone column (directory entries of the root folder,
directory entries of the boot folder, datazone1 of big file1, datazone2 of big
file1 as well as datazone3 of big file1) are all different blocks.

each entry in the directory entries blocks is like 32 or 16 bytes (depending on
the filename length, it's usually 32 now, 30 bytes for filename and 2 bytes for
inode table offset.)

  +-------------------------------------------------------------------------+
  |                                                                         |
  |     INODE TABLE                             DATA ZONES                  |
  |                                                                         |
  |          +--------------------> directory entries of the root folder:   |
  |          |                                                              |
  |          |                           [root inode offset] ["."] ---------+
  +-> root folder inode                  [boot inode offset] ["boot"]       |
                                                  |                         |
  +-----------------------------------------------+                         |
  |                                                                         |
  |          +--------------------> directory entries of the boot folder:   |
  |          |                                                              |
  |          |                          [root inode offset] [".."] ---------+
  +-> boot folder inode                 [boot inode offset] ["."] ----------+
  |                                     [file1 inode offset] ["file1"]      |
  |                                               |                         |
  | +---------------------------------------------+                         |
  | |                                                                       |
  | +-> file1 inode ------------------> datazone1 of big file1              |
  |       |    |                                                            |
  |       |    +----------------------> datazone2 of big file1              |
  |       |                                                                 |
  |       +---------------------------> datazone3 of big file1              |
  |                                                                         |
  +-------------------------------------------------------------------------+

as you may already have understood, inode table offsets being composed of 2
bytes, there are maximum 2^16 different inodes possible, which means 2^16
files/directories/symbolic links/hard links...

however, the limitating number of files may also be the number of datazones. in
this case, there are like 15k blocks so ~15k datazones, which means maximum 15k
folders/files/...

you can see an implementation of a basic reading procedure in
boot/stage2/fs/minix.{c,h}
