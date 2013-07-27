#ifndef STAGE2_H
# define STAGE2_H

# include <stdint.h>
# include <partitions.h>
# include <stage2/fs/fat.h>
# include <stage2/fs/minix.h>


typedef uint32_t (*f_load_file)(const char *, void *);
typedef uint32_t (*f_get_size)(const char *);


void stage2(struct part_entry *part_table);


#endif // !STAGE2_H
