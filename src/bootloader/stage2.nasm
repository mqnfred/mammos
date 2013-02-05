; stage2, stored in the EBR, loaded by stage1
; for more information, see the /design.md file


%define STAGE2_ENTRY 0x7e00


ORG STAGE2_ENTRY
BITS 16



stage2_entry:
    hlt
    jmp     stage2_entry
