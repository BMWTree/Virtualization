#include "main.h"

struct rte_ring *input_rings[2];

void (*forward)(void) = NULL;
// void forward_SP(void);
// void forward_WFQ(void);
int SP_priority[3];
struct app_mbuf_array *worker_mbuf;
void app_main_loop_forwarding(void)
{

    if (forward == NULL)
    {
        if (!strcmp(app.inter_node, "SP"))
        {
            forward = forward_SP;
            for (int i = 0; i < 2; ++i)
                SP_priority[i] = app.SP_priority[i];
        }
        else if (!strcmp(app.intra_node, "WFQ"))
        {
            forward = forward_WFQ;
        }
        for (int i = 0; i < 2; ++i)
        {
            input_rings[i] = app.rings_nodes[i];
        }
    }

    worker_mbuf = rte_malloc_socket(NULL, sizeof(struct app_mbuf_array),
                                    RTE_CACHE_LINE_SIZE, rte_socket_id());
    if (worker_mbuf == NULL)
        rte_panic("Worker thread: cannot allocate buffer space\n");

    while (!force_quit)
    {
        forward();
    }
}

void forward_SP(void)
{
    int i;
    for (int priority = 1; priority <= 2; ++priority)
    {
        for (i = 0; i < 2; ++i)
        {
            if (SP_priority[i] == priority)
                break;
        }
        struct rte_ring *ring = input_rings[i];

        int ret = rte_ring_sc_dequeue(
            ring,
            (void **)worker_mbuf->array);
        if (ret == -ENOENT)
            continue;
        packet_enqueue(app.default_port,worker_mbuf->array[0]);
        break;
    }
}
void forward_WFQ(void)
{
    
}