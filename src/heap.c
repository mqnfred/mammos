#include <heap.h>


static uint32_t heap_offset = 0x0;

static struct meta* dump = NULL;
static struct meta* blocks = NULL;


static struct meta* get_meta(void)
{
    // take the first meta node in dump if there are left
    if (dump != NULL)
    {
        struct meta* hold = dump;
        dump = dump->next;
        return hold;
    }

#if 0
    // if no meta nodes are left in dump, we need to allocate new ones
    // first we look for a free page in the already existing list
    for (struct meta* tmp = blocks; tmp != NULL; tmp = tmp->next)
    {
        if (!tmp->free || tmp->addr % PAGE_SIZE != 0 || tmp->size != PAGE_SIZE)
            continue;

        // setup the meta node
        mmap(tmp->addr);
        tmp->free = false;
        dump = (void*)tmp->addr;
    }
#endif

    // if no space was available in the blocks list, allocate it at the top
    // of the heap
    if (dump == NULL)
    {
        mmap((uint32_t)(dump = (void*)heap_offset));
        heap_offset += PAGE_SIZE;
    }

    // build the list into dump
    for (uint32_t i = 0; i < NODES_IN_PAGE - 1; i += 1)
        (dump + i)->next = dump + i + 1;
    (dump + NODES_IN_PAGE - 1)->next = NULL;

    // now that dump is not empty anymore, start again
    return get_meta();
}


__attribute__((always_inline))
static inline void store_meta(struct meta* node)
{
    node->next = dump;
    dump = node;
}


__attribute__((always_inline))
static inline void merge(void)
{
    for (struct meta* cur = blocks; cur != NULL; cur = cur->next)
    {
        if (!cur->free)
            continue;

        for (struct meta* tmp = cur->next; tmp != NULL; tmp = tmp->next)
        {
            if (!tmp->free)
            {
                cur = tmp->next;
                break;
            }

            cur->next = tmp->next;
            cur->size += tmp->size;

            tmp->next = dump;
            dump = tmp;
        }
    }
}


__attribute__((always_inline))
static inline void* malloc_internal(uint32_t size, struct meta* beginning)
{
    struct meta* tail = beginning;

    // look for a first fit in the blocks list
    for (struct meta* tmp = beginning; tmp != NULL; tmp = tmp->next)
    {
        // save the tail in case the need to map a new frame arises
        tail = tmp;

        if (!tmp->free || tmp->size < size)
            continue;
        else if (tmp->size > (size + OVERHEAD_TOLERANCE))
        {
            struct meta* newmeta = get_meta();
            newmeta->size = tmp->size - size;
            newmeta->addr = tmp->addr + size;
            newmeta->next = tmp->next;
            newmeta->free = true;

            tmp->next = newmeta;
            tmp->size = size;
        }

        tmp->free = false;
        return (void*)tmp->addr;
    }

    // if no block of an appropriate size was found, map one!
    // and add it at the tail of the blocks list
    struct meta* node = get_meta();

    mmap(heap_offset);
    node->addr = heap_offset;
    heap_offset += PAGE_SIZE;

    node->free = true;
    node->size = PAGE_SIZE;
    node->next = NULL;

    if (tail == NULL)
        blocks = node;
    else
        tail->next = node;

    return malloc_internal(size, node);
}


void* malloc(uint32_t size)
{
    return malloc_internal(size, blocks);
}


void free(void* address)
{
    for (struct meta* cur = blocks; cur != NULL; cur = cur->next)
        if (cur->addr == (uint32_t)address)
        {
            cur->free = true;
            break;
        }

    merge();
}


void setup_heap(uint32_t offset)
{
    // align the offset on a 4kib limit
    if (offset % PAGE_SIZE != 0)
        offset += PAGE_SIZE - (offset % PAGE_SIZE);

    heap_offset = offset;
}
