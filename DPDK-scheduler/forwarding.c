#include "main.h"

struct rte_ring *input_rings[2];

int app_fwd_learning(struct flow_key *key, struct app_fwd_table_item *value)
{
    if (app.fwd_hash == NULL)
    {
        RTE_LOG(
            ERR, HASH,
            "%s: ERROR hash table is not initialized.\n",
            __func__);
        return -1;
    }
    int index = rte_hash_lookup(app.fwd_hash, key);
    if (index == -EINVAL)
    {
        RTE_LOG(
            ERR, HASH,
            "%s: ERROR the parameters are invalid when lookup hash table\n",
            __func__);
    }
    else if (index == -ENOENT)
    {
        int new_ind = rte_hash_add_key(app.fwd_hash, key);
        if (new_ind == -ENOSPC)
        {
            RTE_LOG(INFO, HASH,
                    "%s: ENOSPC, reseting\n",
                    __func__);
            rte_hash_reset(app.fwd_hash);
            new_ind = rte_hash_add_key(app.fwd_hash, key);
        }
        app.fwd_table[new_ind].arrival_timestamp = value->arrival_timestamp;
    }
    else if (index < 0 || index >= FORWARD_ENTRY)
    {
        RTE_LOG(
            ERR, HASH,
            "%s: ERROR invalid table entry found in hash table: %d\n",
            __func__, index);
        return -1;
    }
    else
    {
        app.fwd_table[index].arrival_timestamp = value->arrival_timestamp;
    }
    return 0;
}

int app_fwd_lookup(const struct flow_key *key, struct app_fwd_table_item *value)
{
    int index = rte_hash_lookup(app.fwd_hash, key);
    if (index >= 0 && index < FORWARD_ENTRY)
    {
        uint64_t now_time = rte_get_tsc_cycles();
        uint64_t interval = now_time - app.fwd_table[index].arrival_timestamp;
        if (interval <= app.fwd_item_valid_time)
        {
            value->arrival_timestamp = app.fwd_table[index].arrival_timestamp;
            return 0;
        }
        else
        {
            rte_hash_del_key(app.fwd_hash, key);
            RTE_LOG(
                INFO, HASH,
                "%s: ERROR key port: %d\n",
                __func__, key->port);
            return -1;
        }
    }
    return -1;
}

void (*forward)(void) = NULL;
int SP_priority[2];
int WFQ_weight[2];
struct app_mbuf_array *worker_mbuf;
void app_main_loop_forwarding(void)
{
    app.cpu_freq[rte_lcore_id()] = rte_get_tsc_hz();
    app.fwd_item_valid_time = app.cpu_freq[rte_lcore_id()] / 1000 * VALID_TIME;
    uint64_t rtt = app.cpu_freq[rte_lcore_id()] / 1000000 * app.rtt;
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
            for (int i = 0; i < 2; ++i)
                WFQ_weight[i] = app.WFQ_weight[i];
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
        packet_enqueue(app.default_port, worker_mbuf->array[0]);
        break;
    }
}
void forward_WFQ(void)
{
    uint64_t estimate_departure[2];
    for (int i = 0; i < 2; ++i)
    {
        uint32_t n = rte_ring_dequeue_bulk_start(input_rings[i], (void **)worker_mbuf->array[0], 1, NULL);
        if (n == 0)
        {
            estimate_departure[i] = UINT64_MAX;
            continue;
        }
        
        struct ipv4_5tuple_host *ipv4_5tuple = rte_pktmbuf_mtod_offset(worker_mbuf->array[0], struct ipv4_5tuple_host *, sizeof(struct rte_ether_hdr) + offsetof(struct rte_ipv4_hdr, time_to_live));
        struct flow_key key;
        key.ip = ipv4_5tuple->ip_src;
        key.port = ipv4_5tuple->port_src;
        struct app_fwd_table_item value;
        if(app_fwd_lookup(&key, &value)<0)
            value.arrival_timestamp=0;

        double bandwidth = WFQ_weight[i] * 1.0 / (WFQ_weight[0] + WFQ_weight[1]) * app.tx_rate_mbps;
        estimate_departure[i] = value.arrival_timestamp + worker_mbuf->array[0]->pkt_len / bandwidth * 8 / 1000000 * app.cpu_freq[rte_lcore_id()];
        struct rte_ipv4_hdr a;
        rte_hash_del_key(app.fwd_hash,&key);
        rte_ring_dequeue_finish(input_rings[i], 0);
    }
    struct rte_ring *ring = estimate_departure[0] < estimate_departure[1] ? input_rings[0] : input_rings[1];
    int ret = rte_ring_sc_dequeue(
        ring,
        (void **)worker_mbuf->array);
    if (ret != -ENOENT)
        packet_enqueue(app.default_port, worker_mbuf->array[0]);
}