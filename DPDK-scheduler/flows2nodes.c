#include "main.h"

void app_main_loop_flows2nodes(int nodeid)
{
    app.cpu_freq[rte_lcore_id()] = rte_get_tsc_hz();
    struct flows2nodes_context context;
    RTE_LOG(INFO, SWITCH, "Core %u is doing flows2nodes %d\n",
            rte_lcore_id(), nodeid);

    if (!strcmp(app.intra_node, "SP"))
    {
        context.flows2nodes = flows2nodes_SP;
        for (int i = 0; i < 3; ++i)
            context.SP_priority[i] = app.SP_priority[2 + nodeid * 3 + i];
    }
    else if (!strcmp(app.intra_node, "WFQ"))
    {
        context.flows2nodes = flows2nodes_WFQ;
        for (int i = 0; i < 3; ++i)
        {
            context.peek_mbuf[i] = rte_malloc_socket(NULL, sizeof(struct ring_obj),
                                                     RTE_CACHE_LINE_SIZE, rte_socket_id());
            if (context.peek_mbuf[i] == NULL)
                rte_panic("Worker thread: cannot allocate buffer space\n");
            context.peek_valid[i] = 0;
            context.WFQ_weight[i] = app.WFQ_weight[i + 2 + nodeid * 3];
        }
    }
    else if (!strcmp(app.intra_node, "pFabric"))
    {
        context.flows2nodes = flows2nodes_pFabric;
        for (int i = 0; i < 3; ++i)
        {
            context.pFabric_size[i] = app.pFabric_size[i + nodeid * 3];
        }
    }
    else
    {
        context.flows2nodes = 0;
    }

    for (int i = 0; i < 3; ++i)
    {
        context.input_rings[i] = app.rings_flows[i + nodeid * 3];
    }
    context.output_ring = app.rings_nodes[nodeid];

    context.worker_mbuf = rte_malloc_socket(NULL, sizeof(struct ring_obj),
                                            RTE_CACHE_LINE_SIZE, rte_socket_id());
    if (context.worker_mbuf == NULL)
        rte_panic("Worker thread: cannot allocate buffer space\n");

    while (!force_quit)
    {
        context.flows2nodes(&context);
        rte_delay_us(TIME_SLEEP_US);
    }
}

void flows2nodes_SP(struct flows2nodes_context *context)
{
    int i;
    for (int priority = 1; priority <= 3; ++priority)
    {
        for (i = 0; i < 3; ++i)
        {
            if (context->SP_priority[i] == priority)
                break;
        }
        struct rte_ring *ring = context->input_rings[i];

        int ret = rte_ring_sc_dequeue(
            ring,
            (void **)&context->worker_mbuf);
        if (ret == -ENOENT)
            continue;
        rte_ring_sp_enqueue(context->output_ring, context->worker_mbuf);
        RTE_LOG(DEBUG, SWITCH, "%s: enqueue packet to %s\n", __func__, context->output_ring->name);
        break;
    }
}
void flows2nodes_WFQ(struct flows2nodes_context *context)
{
    uint64_t estimate_departure[3];
    for (int i = 0; i < 3; ++i)
    {
        if (!context->peek_valid[i])
        {
            int ret = rte_ring_sc_dequeue(
                context->input_rings[i],
                (void **)&context->peek_mbuf[i]);
            if (ret == -ENOENT)
                continue;
            // printf("%d,%lu\n",context->peek_mbuf[i]->mbuf->pkt_len,context->peek_mbuf[i]->timestamp);
            context->peek_valid[i] = 1;
        }
        // struct ipv4_5tuple_host *ipv4_5tuple = rte_pktmbuf_mtod_offset(context->peek_mbuf[i]->mbuf, struct ipv4_5tuple_host *, sizeof(struct ether_hdr) + offsetof(struct ipv4_hdr, time_to_live));
        // struct flow_key key;
        // key.ip = ipv4_5tuple->ip_src;
        // key.port = ipv4_5tuple->port_src;
        // key.seq = ipv4_5tuple->seq;
        // struct app_fwd_table_item value;
        // if (app_fwd_lookup(&key, &value) < 0)
        //     value.arrival_timestamp = 0;

        uint64_t arrival_timestamp=context->peek_mbuf[i]->timestamp;
        double bandwidth = context->WFQ_weight[i] * 1.0 / (context->WFQ_weight[0] + context->WFQ_weight[1]) * app.tx_rate_mbps;
        // printf("%f,%lu\n",bandwidth,app.cpu_freq[rte_lcore_id()]);
        uint64_t estimate_tx=(uint64_t)(context->peek_mbuf[i]->mbuf->pkt_len / bandwidth * 8 / 1000000 * app.cpu_freq[rte_lcore_id()]);
        estimate_departure[i] = arrival_timestamp + estimate_tx;
        // printf("%s:%lu + %lu = %lu, weight=%d, pkt len=%d\n",__func__,arrival_timestamp, estimate_tx, estimate_departure[i],context->WFQ_weight[i],context->peek_mbuf[i]->mbuf->pkt_len);
        // rte_hash_del_key(app.fwd_hash, &key);
    }
    int ring_id = 0;
    uint64_t min_departure = UINT64_MAX;
    for (int i = 0; i < 3; ++i)
    {
        // if (context->peek_valid[i])
        //     printf("ring %d: time %lu\n", i, estimate_departure[i]);
        if (context->peek_valid[i] && estimate_departure[i] < min_departure)
        {
            min_departure = estimate_departure[i];
            ring_id = i;
        }
    }
    if (context->peek_valid[0] || context->peek_valid[1] || context->peek_valid[2])
    {
        rte_ring_sp_enqueue(context->output_ring, context->peek_mbuf[ring_id]);
        context->peek_valid[ring_id] = 0;
    }
}
void flows2nodes_pFabric(struct flows2nodes_context *context)
{
    int ring = 0;
    int min_size = INT_MAX;
    for (int i = 0; i < 3; ++i)
    {
        if (context->pFabric_size[i] < min_size)
        {
            ring = i;
            min_size = context->pFabric_size[i];
        }
    }
    for (int i = 0; i < 2; ++i)
    {
        int ret = rte_ring_sc_dequeue(
            context->input_rings[ring],
            (void **)&context->worker_mbuf);
        if (ret == -ENOENT)
        {
            ring = (ring + 1) % 3;
            continue;
        }
        context->pFabric_size[ring] -= context->worker_mbuf->mbuf->pkt_len;
        rte_ring_sp_enqueue(context->output_ring, context->worker_mbuf);
    }
}