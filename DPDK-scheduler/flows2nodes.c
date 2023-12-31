#include "main.h"

struct rte_ring *input_rings[3];
struct rte_ring *output_ring;
void (*flows2nodes)(void) = NULL;
struct app_mbuf_array *worker_mbuf;

// SP
int SP_priority[3];
// WFQ
int WFQ_weight[3];
struct app_mbuf_array *peek_mbuf[3];
int peek_valid[3];
// pFabric
int pFabric_size[3];

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
            for (int i = 0; i < 3; ++i)
            {
                peek_mbuf[i] = rte_malloc_socket(NULL, sizeof(struct app_mbuf_array),
                                                 RTE_CACHE_LINE_SIZE, rte_socket_id());
                if (peek_mbuf[i] == NULL)
                    rte_panic("Worker thread: cannot allocate buffer space\n");
                peek_valid[i] = 0;
                WFQ_weight[i] = app.WFQ_weight[i + 2 + nodeid * 3];
            }
        }
        else if (!strcmp(app.intra_node, "pFabric"))
        {
            flows2nodes = flows2nodes_pFabric;
            for (int i = 0; i < 3; ++i)
            {
                pFabric_size[i] = app.pFabric_size[i + nodeid * 3];
            }
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
        rte_ring_sp_enqueue(output_ring, worker_mbuf->array[0]);
        break;
    }
}
void flows2nodes_WFQ(void)
{
    uint64_t estimate_departure[3];
    for (int i = 0; i < 3; ++i)
    {
        if (!peek_valid[i])
        {
            int ret = rte_ring_sc_dequeue(
                input_rings[i],
                (void **)peek_mbuf[i]->array);
            if (ret == -ENOENT)
                continue;
            peek_valid[i] = 1;
        }
        struct ipv4_5tuple_host *ipv4_5tuple = rte_pktmbuf_mtod_offset(peek_mbuf[i]->array[0], struct ipv4_5tuple_host *, sizeof(struct ether_hdr) + offsetof(struct ipv4_hdr, time_to_live));
        struct flow_key key;
        key.ip = ipv4_5tuple->ip_src;
        key.port = ipv4_5tuple->port_src;
        struct app_fwd_table_item value;
        if (app_fwd_lookup(&key, &value) < 0)
            value.arrival_timestamp = 0;

        double bandwidth = WFQ_weight[i] * 1.0 / (WFQ_weight[0] + WFQ_weight[1]) * app.tx_rate_mbps;
        estimate_departure[i] = value.arrival_timestamp + worker_mbuf->array[0]->pkt_len / bandwidth * 8 / 1000000 * app.cpu_freq[rte_lcore_id()];
        rte_hash_del_key(app.fwd_hash, &key);
    }
    int ring_id = 0;
    uint64_t min_departure = UINT64_MAX;
    for (int i = 0; i < 3; ++i)
    {
        if (peek_valid[i] && estimate_departure[i] < min_departure)
        {
            min_departure = estimate_departure[i];
            ring_id = i;
        }
    }
    if (peek_valid[0] || peek_valid[1] || peek_valid[2])
    {
        packet_enqueue(app.default_port, peek_mbuf[ring_id]->array[0]);
        peek_valid[ring_id] = 0;
    }
}
void flows2nodes_pFabric(void)
{
    int ring = 0;
    int max_size = INT_MIN;
    for (int i = 0; i < 3; ++i)
    {
        if (pFabric_size[i] > max_size)
        {
            ring = i;
            max_size = pFabric_size[i];
        }
    }

    for (int i = 0; i < 2; ++i)
    {
        int ret = rte_ring_sc_dequeue(
            input_rings[ring],
            (void **)worker_mbuf->array);
        if (ret != -ENOENT)
        {
            pFabric_size[ring] -= worker_mbuf->array[0]->pkt_len;
            packet_enqueue(app.default_port, worker_mbuf->array[0]);
            return;
        }
        ring = (ring + 1) % 3;
    }
}