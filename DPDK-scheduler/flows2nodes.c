#include "main.h"

struct rte_ring *input_rings[3];
struct rte_ring *output_ring;
void (*flows2nodes)(void) = NULL;
// void flows2nodes_SP(void);
// void flows2nodes_WFQ(void);
int SP_priority[3];
struct app_mbuf_array *worker_mbuf;
void app_main_loop_flows2nodes(int nodeid)
{

    if (flows2nodes == NULL)
    {
        if (!strcmp(app.intra_node, "SP"))
        {
            flows2nodes = flows2nodes_SP;
            for (int i = 0; i < 3; ++i)
                SP_priority[i] = app.SP_priority[2 + nodeid * 3 + i];
        }
        else if (!strcmp(app.intra_node, "WFQ"))
        {
            flows2nodes = flows2nodes_WFQ;
        }
        for (int i = 0; i < 3; ++i)
        {
            input_rings[i] = app.rings_flows[i + nodeid * 3];
        }
        output_ring = app.rings_nodes[nodeid];
    }

    worker_mbuf = rte_malloc_socket(NULL, sizeof(struct app_mbuf_array),
                                    RTE_CACHE_LINE_SIZE, rte_socket_id());
    if (worker_mbuf == NULL)
        rte_panic("Worker thread: cannot allocate buffer space\n");

    while (!force_quit)
    {
        flows2nodes();
    }
}

void flows2nodes_SP(void)
{
    int i;
    for (int priority = 1; priority <= 3; ++priority)
    {
        for (i = 0; i < 3; ++i)
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
        rte_ring_sp_enqueue(output_ring,worker_mbuf->array[0]);
        break;
    }
}
void flows2nodes_WFQ(void)
{

}