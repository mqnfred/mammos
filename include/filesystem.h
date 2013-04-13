#ifndef FILESYSTEM_H
# define FILESYSTEM_H


typedef void (*read_type_t)(struct fs_node*, uint32_t);
typedef void (*write_type_t)(struct fs_node*, uint32_t);


struct inode
{
    char name[8];

    uint32_t flags;
    uint32_t size;

    read_type_t readfunc;
    write_type_t writefunc;
};


#endif // !FILESYSTEM_H
