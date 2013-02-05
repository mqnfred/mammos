# os design

## boot process

The boot process is composed of two stages, each having his own task. The
stage1 is in charge of setting up a basic environment for the stage2 to work
on. The stage2 itself is in charge of loading the kernel and jumping there,
ending the boot process.

### stage 1

Here is a clear and exhaustive list of all things done by the first stage.

    - Entering unreal mode with segment register %es, which will be used by
      stage2 when copying kernel above 1MB in physical memory.

    - Setup a valid and plain stack under the 64kB limit of %ss. The placement
      chosen is right below the mapping of the Master Boot Record (MBR) in
      physical memory, 16-bytes aligned, meaning 0x7bf0. The stack should not
      exceed a critical size of 0x76f0, considering the BIOS Data Area (BDA)
      ends at offset 0x500. It would also be preferable for it not to exceed an
      amount of bytes of 0x74f0, considering the placement of the temporary
      kernel loading area (see stage2).

    - Before loading the stage2 into memory, the stage1 is also in charge of
      retrieving the configuration of the drive on which the Operating System
      (and its boot process) is loaded. In order to do that, information will
      be stored in the previously set up stack, as arguments to stage2.

    - Once the stack is set up and the %es and %ds segment registers are in
      unreal mode, the stage1 will load the stage2 into memory at address
      0x7e00 (end of the MBR mapping in physical memory). On the disk, the
      stage2 occupies the whole Extended Boot Record (EBR), from sector 2
      included to sector 63 excluded, for a size of 61 sectors.

    - The stage2 loaded in memory, it's time for the stage1 to end. A simple
      jump to location 0x7e00 will do just that.

Thus far, the memory layout of the physical low-memory area is the following:

    +------------------------------+ 0xFFFF
   ...                            ...
    | Stage 2 code                 |
    +------------------------------+ 0x7e00
    | MBR Magic Number (0x55aa)    |
    +------------------------------+ 0x7df0
    | Partition table              |
    +------------------------------+ 0x7dbe
    | Stage 1 code                 |
    +------------------------------+ 0x7c00
    | Unused space (2 bytes)       |
    +------------------------------+ 0x7bf0
    | Stack (growing down)         |
   ...                            ...
    |                              |
    +------------------------------+ 0x0500
    | BIOS Data Area (BDA)         |
    +------------------------------+ 0x0400
    | Interrupt Vector Table (IVT) |
    +------------------------------+ 0x0000

### stage 2
