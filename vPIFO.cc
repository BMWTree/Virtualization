#include "vPIFO.h"

namespace ns3
{
    const int vPIFO::ROOT = 233;
    const int vPIFO::SIZE = ((1 << 20) - 1) / 3;
    
    NS_OBJECT_ENSURE_REGISTERED(vPIFO);
    TypeId vPIFO::GetTypeId(void)
	{
		static TypeId tid = TypeId("ns3::vPIFO")
			.SetParent<QueueDisc>()
			.SetGroupName("TrafficControl")
			.AddConstructor<vPIFO>();
		return tid;
	}

    bool vPIFO::IsHadoop(int x)
    {
        return (x % 10) > (x / 10);
    }

    vPIFO::vPIFO()
    {
        // Build the scheduling tree

        // Root node: root to tenant group
        sch_tree[ROOT] = std::make_shared<SP>();
        
        // Layer 1: tenant group to tenant type
        for (int i = 0; i <= 9; ++i)
            sch_tree[i] = std::make_shared<SP>();

        // Layer 2: tenant type to tenant
        for (int i = 0, j; i <= 9; ++i)
        {
            j = 10 + i * 2;
            sch_tree[j] = std::make_shared<WFQ>(i + 1);
            sch_tree[j + 1] = std::make_shared<WFQ>(10 - i - 1);
        }

        // Layer 3: only for Web Search tenant, tenant to flow
        for (int i = 100; i <= 199; ++i)
        {
            if (IsHadoop(i - 100))
                continue;
            sch_tree[i] = std::make_shared<pFabric>();
        }
        // Read the Web Search traffic to initialize pFabric flow size
        std::ifstream infile;
        infile.open("scratch/traffic_ws.txt");
        int no;
        infile >> no;
        while (no--)
        {
            int size, tenant;
            uint32_t src, dst, sport, dport;
            double start_time;
            infile >> src >> dst >> sport >> dport >> size >> start_time >> tenant;
            if (IsHadoop(tenant))
                continue;
            std::stringstream ss;
            ss << src << dst << sport << dport;
            std::string flow_label = ss.str();
            flow_map[flow_label] = ++queue_cnt;
            queue_map[queue_cnt] = std::queue<Ptr<QueueDiscItem>>();
            sch_tree[tenant + 100]->InitializeSize(queue_cnt, size);
        }
    }

    std::string vPIFO::GetFlowLabel(Ptr<QueueDiscItem> item)
    {
        Ptr<const Ipv4QueueDiscItem> ipItem =
            DynamicCast<const Ipv4QueueDiscItem>(item);

        const Ipv4Header ipHeader = ipItem->GetHeader();
        TcpHeader header;
        GetPointer(item)->GetPacket()->PeekHeader(header);

        std::stringstream ss;
        ss << ipHeader.GetSource().Get();
        ss << ipHeader.GetDestination().Get();
        ss << header.GetSourcePort();
        ss << header.GetDestinationPort();

        std::string flowLabel = ss.str();
        return flowLabel;
    }

    bool vPIFO::DoEnqueue(Ptr<QueueDiscItem> item)
    {
        // The root queue is full
        if (size >= SIZE) {
            Drop(item);
            return false;
        }
        size++;
        TenantTag my_tag;
        Packet *packet = GetPointer(item->GetPacket());
        packet->PeekPacketTag(my_tag);
        int tenant = my_tag.GetTenantId();
        int group = tenant / 10;
        int rk1 = sch_tree[ROOT]->RankComputation(group, 0);
        pipe.AddPush(ROOT, rk1, group);

        int type_id = 10 + group * 2 + IsHadoop(tenant);
        int rk2 = sch_tree[group]->RankComputation(type_id, 0);
        pipe.AddPush(group, rk2, type_id);

        int tenant_id = 100 + tenant;
        int packet_size = packet->GetSize();
        int rk3 = sch_tree[type_id]->RankComputation(tenant_id, packet_size);
        pipe.AddPush(type_id, rk3, tenant_id);

        // A Hadoop tenant, all packets can be set in the same real queue
        if (IsHadoop(tenant))
        {
            if (!queue_map.count(tenant_id))
                queue_map[tenant_id] = std::queue<Ptr<QueueDiscItem>>();
            std::queue<Ptr<QueueDiscItem>> q = queue_map[tenant_id];
            q.push(item);
        }
        // A WebSearch tenant, each flow need a real packet queue
        else
        {
            string flow_label = GetFlowLabel(item);
            int flow_id = flow_map[flow_label];
            std::queue<Ptr<QueueDiscItem>> q = queue_map[flow_id];
            int rk4 = sch_tree[tenant_id]->RankComputation(flow_id, 0);
            pipe.AddPush(tenant_id, rk4, flow_id);
            q.push(item);
        }
        return true;
    }

    Ptr<QueueDiscItem> vPIFO::DoDequeue()
    {
        int ans = pipe.GetToken();
        // No packet in buffer now
        if (ans == -1)
            return nullptr;
        size--;
        std::queue<Ptr<QueueDiscItem>> q = queue_map[ans];
        Ptr<QueueDiscItem> item = q.front();

        TenantTag my_tag;
        Packet *packet = GetPointer(item->GetPacket());
        int packet_size = packet->GetSize();
        packet->PeekPacketTag(my_tag);
        int tenant = my_tag.GetTenantId();

        int type_id = 10 + (tenant / 10) * 2 + IsHadoop(tenant);
        sch_tree[type_id]->Dequeue(packet_size);
        if (!IsHadoop(tenant))
        {
            string flow_label = GetFlowLabel(item);
            int flow_id = flow_map[flow_label];
            sch_tree[tenant + 100]->Dequeue(flow_id);
        }
        q.pop();
        return item;
    }
    
    Ptr<const QueueDiscItem> vPIFO::DoPeek(void) const {
        return 0;
    }
    
    bool vPIFO::CheckConfig(void) {
        return 1;
    }
    
    void vPIFO::InitializeParams(void) {
    }
}
