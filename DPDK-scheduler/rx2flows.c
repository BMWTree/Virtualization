#include "main.h"

void app_main_loop_rx2flows(void)
{
    struct app_mbuf_array *worker_mbuf;
    uint32_t i;
    int dst_port;
    struct ipv4_5tuple_host *ipv4_5tuple;
    int default_port;

    default_port = app.default_port;
    srand((unsigned)time(NULL));
    RTE_LOG(INFO, SWITCH, "Core %u is doing rx2flows\n",
            rte_lcore_id());

    app.cpu_freq[rte_lcore_id()] = rte_get_tsc_hz();
    app.fwd_item_valid_time = app.cpu_freq[rte_lcore_id()] / 1000 * VALID_TIME;
    uint64_t rtt = app.cpu_freq[rte_lcore_id()] / 1000000 * app.rtt;

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
    if (worker_mbuf == NULL)
        rte_panic("Worker thread: cannot allocate buffer space\n");

    for (i = 0; !force_quit; i = (i + 1) % app.n_ports)
    {
        int ret;
        /*ret = rte_ring_sc_dequeue_bulk(
            app.rings_rx[i],
            (void **) worker_mbuf->array,
            app.burst_size_worker_read);*/
        ret = rte_ring_sc_dequeue(
            app.rings_rx[i],
            (void **)worker_mbuf->array);

        if (ret == -ENOENT)
            continue;
        if (i != app.port)
        {
            dst_port = app.port;
            packet_enqueue(dst_port,worker_mbuf->array[0]);
            continue;
        }


        ipv4_5tuple = rte_pktmbuf_mtod_offset(worker_mbuf->array[0], struct ipv4_5tuple_host *, sizeof(struct ether_hdr) + offsetof(struct ipv4_hdr, time_to_live));
        for (int flow = 0; flow < 6; ++flow)
        {
            if (ipv4_5tuple->port_src == app.flow_src_ports[flow] || ipv4_5tuple->port_dst == app.flow_src_ports[flow])
            {
                rte_ring_sp_enqueue(app.rings_flows[flow], worker_mbuf->array[0]);
                RTE_LOG(
                    DEBUG, SWITCH,
                    "%s: Port %d: forward packet to ring flow %d\n",
                    __func__, i, flow);
                break;
            }
        }
    }
}
