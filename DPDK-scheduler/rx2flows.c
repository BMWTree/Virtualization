#include "main.h"

void app_main_loop_rx2flows(void)
{
    struct app_mbuf_array *worker_mbuf;
    uint32_t i;
    int dst_port;
    struct ipv4_5tuple_host *ipv4_5tuple;
    struct flow_key key;
    struct app_fwd_table_item value;
    srand((unsigned)time(NULL));
    RTE_LOG(INFO, SWITCH, "Core %u is doing rx2flows\n",
            rte_lcore_id());

    app.cpu_freq[rte_lcore_id()] = rte_get_tsc_hz();
    app.fwd_item_valid_time = app.cpu_freq[rte_lcore_id()] / 1000 * VALID_TIME;

    if (app.log_qlen)
    {
        fprintf(
            app.qlen_file,
            "# %-10s %-8s %-8s %-8s\n",
            "<Time (in s)>",
            "<Port id>",
            "<Qlen in Bytes>",
            "<Buffer occupancy in Bytes>");
        fflush(app.qlen_file);
    }
    worker_mbuf = rte_malloc_socket(NULL, sizeof(struct app_mbuf_array),
                                    RTE_CACHE_LINE_SIZE, rte_socket_id());
    struct ring_obj *obj = rte_malloc_socket(NULL, sizeof(struct ring_obj),
                                             RTE_CACHE_LINE_SIZE, rte_socket_id());
    if (worker_mbuf == NULL)
        rte_panic("Worker thread: cannot allocate buffer space\n");

    for (i = 0; !force_quit; i = (i + 1) % app.n_ports)
    {
        int ret;
        ret = rte_ring_sc_dequeue(
            app.rings_rx[i],
            (void **)worker_mbuf->array);

        if (ret == -ENOENT)
            continue;
        if (i != app.port)
        {
            dst_port = app.port;
            packet_enqueue(dst_port, worker_mbuf->array[0]);
            continue;
        }

        ipv4_5tuple = rte_pktmbuf_mtod_offset(worker_mbuf->array[0], struct ipv4_5tuple_host *, sizeof(struct ether_hdr) + offsetof(struct ipv4_hdr, time_to_live));
        int flow;
        for (flow = 0; flow < 6; ++flow)
        {
            uint16_t src_port = rte_be_to_cpu_16(ipv4_5tuple->port_src), dst_port = rte_be_to_cpu_16(ipv4_5tuple->port_dst);
            struct in_addr src_ip_addr, dst_ip_addr;
            src_ip_addr.s_addr = ipv4_5tuple->ip_src;
            dst_ip_addr.s_addr = ipv4_5tuple->ip_dst;
            if (src_port == app.flow_src_ports[flow] || dst_port == app.flow_src_ports[flow])
            {
                RTE_LOG(DEBUG, SWITCH, "New packet %s:%d -> %s:%d\n", inet_ntoa(src_ip_addr), src_port, inet_ntoa(dst_ip_addr), dst_port);

                obj->mbuf=worker_mbuf->array[0];
                obj->timestamp=rte_get_tsc_cycles();
                rte_ring_sp_enqueue(app.rings_flows[flow], obj);
                RTE_LOG(
                    DEBUG, SWITCH,
                    "%s: Port %d: forward packet to %s\n",
                    __func__, i, app.rings_flows[flow]->name);
                break;
            }
        }
        if (flow == 6)
        {
            RTE_LOG(
                DEBUG, SWITCH,
                "%s: Port %d: forward packet to port %d\n",
                __func__, i, app.default_port);
            packet_enqueue(app.default_port, worker_mbuf->array[0]);
        }
    }
}
