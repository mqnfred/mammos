#ifndef LINUX_MINIX_FS_H
# define LINUX_MINIX_FS_H

# include <linux/types.h>
# include <linux/magic.h>

# define MINIX_ROOT_INO 1
# define MINIX_SYSTEM_ID 0x80

# define MINIX_LINK_MAX 250
# define MINIX2_LINK_MAX 65530

# define MINIX_I_MAP_SLOTS 8
# define MINIX_Z_MAP_SLOTS 64
# define MINIX_VALID_FS 0x0001
# define MINIX_ERROR_FS 0x0002

# define MINIX_INODES_PER_BLOCK ((BLOCK_SIZE)/(sizeof (struct minix_inode)))


struct minix_inode {
    uint16_t i_mode;
    uint16_t i_uid;
    uint32_t i_size;
    uint32_t i_time;
    uint8_t i_gid;
    uint8_t i_nlinks;
    uint16_t i_zone[9];
};


struct minix2_inode {
    uint16_t i_mode;
    uint16_t i_nlinks;
    uint16_t i_uid;
    uint16_t i_gid;
    uint32_t i_size;
    uint32_t i_atime;
    uint32_t i_mtime;
    uint32_t i_ctime;
    uint32_t i_zone[10];
};


struct minix_super_block {
    uint16_t s_ninodes;
    uint16_t s_nzones;
    uint16_t s_imap_blocks;
    uint16_t s_zmap_blocks;
    uint16_t s_firstdatazone;
    uint16_t s_log_zone_size;
    uint32_t s_max_size;
    uint16_t s_magic;
    uint16_t s_state;
    uint32_t s_zones;
};


struct minix3_super_block {
    uint32_t s_ninodes;
    uint16_t s_pad0;
    uint16_t s_imap_blocks;
    uint16_t s_zmap_blocks;
    uint16_t s_firstdatazone;
    uint16_t s_log_zone_size;
    uint16_t s_pad1;
    uint32_t s_max_size;
    uint32_t s_zones;
    uint16_t s_magic;
    uint16_t s_pad2;
    uint16_t s_blocksize;
    uint8_t s_disk_version;
};


struct minix_dir_entry {
    uint16_t inode;
    char name[0];
};


struct minix3_dir_entry {
    uint32_t inode;
    char name[0];
};


#endif // !LINUX_MINIX_FS_H
