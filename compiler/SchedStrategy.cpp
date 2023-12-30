#include <cassert>
#include <iostream>
#include <pcap.h>
#include <vector>
#include <cstdio>
#include "SchedStrategy.h"
#include "PIFOTree.h"
#include "util.h"
#include "PFabric.h"
#include "SP.h"
#include "WFQ.h"

extern std::map<std::string, TreeNode> flowNodeMap;

static long long curCycle;
static long long cumulatePktNum;
static long long pktId;
static long long idle_cycle_cnt;

const long long IDLECYCLE_BITS = 8;
const long long MAX_IDLECYCLE = (1 << 8) - 1;
const long long MAX_INTERVAL_IDLECYCLE = 99;

SchedStrategy SchedStrategyUnknown(){
    SchedStrategy schedStrategy = new SchedStrategy_;
    schedStrategy->type = UNKNOWNTYPE;
    return schedStrategy;
}

SchedStrategy SchedStrategyWFQ(StrategyWFQ WFQ){
    SchedStrategy schedStrategy = new SchedStrategy_;
    schedStrategy->type = WFQTYPE;
    schedStrategy->u.WFQ = WFQ;
    return schedStrategy;
}

SchedStrategy SchedStrategyPFabric(StrategyPFabric pFabric){
    SchedStrategy schedStrategy = new SchedStrategy_;
    schedStrategy->type = PFABRICTYPE;
    schedStrategy->u.pFabric = pFabric;
    return schedStrategy;

}

SchedStrategy SchedStrategySP(StrategySP SP){
    SchedStrategy schedStrategy = new SchedStrategy_;
    schedStrategy->type = SPTYPE;
    schedStrategy->u.SP = SP;
    return schedStrategy;

}

void printSchedStrategy(SchedStrategy strategy, ostream& os){
    assert(strategy);
    switch(strategy->type){
    case UNKNOWNTYPE:{
        os << "\ttype: unknown\n";
        break;
    }
    case PFABRICTYPE:{
        os << "\ttype: pFabric\n";
        break;
    }
    case SPTYPE:{
        os << "\ttype: SP\n";
        break;
    }
    case WFQTYPE:{
        os << "\ttype: WFQ\n";
        break;
    }
    }
}

void tagPriorityTillRoot(TreeNode leafNode, std::vector<int>& priorityVec, unsigned char* user, const struct pcap_pkthdr* pkthdr, const unsigned char* packet){
    TreeNode node = leafNode;

    SchedStrategyType type = node->strategy->type;

    switch(type){
    case UNKNOWNTYPE:{
        assert(0);
        break;
    }
    case PFABRICTYPE:{
        priorityVec.emplace_back(calPFabricPriority(user, pkthdr, packet));
        break;
    }
    case SPTYPE:{
        priorityVec.emplace_back(calSPLeafPriority(user, pkthdr, packet, node->strategy->u.SP));
        break;
    }
    case WFQTYPE:{
        priorityVec.emplace_back(calWFQLeafPriority(user, pkthdr, packet, node->strategy->u.WFQ));
        break;
    }
    }
    
    while(node->father){
        type = node->father->strategy->type;
        switch(type){
        case UNKNOWNTYPE:{
            assert(0);
            break;
        }
        case PFABRICTYPE:{
            assert(0);
            break;
        }
        case SPTYPE:{
            priorityVec.emplace_back(calSPNonLeafPriority(node->nodeId, node->father->strategy->u.SP));
            break;
        }
        case WFQTYPE:{
            priorityVec.emplace_back(calWFQNonLeafPriority(node->nodeId, node->father->strategy->u.WFQ, pkthdr));
            break;
        }
        }
        node = node->father;
    }
}

void tagPriorityHandler(unsigned char* user, const struct pcap_pkthdr* pkthdr, const unsigned char* packet) {
    if(idle_cycle_cnt > 1800){
        return;
    }

    std::string flowId = getFlowId(user, pkthdr, packet);

    if(flowNodeMap.find(flowId) == flowNodeMap.end()){
        return;
    }
    assert(flowNodeMap.find(flowId) != flowNodeMap.end());

    TreeNode leafNode = flowNodeMap[flowId];

    std::vector<int> priorityVec;
    tagPriorityTillRoot(leafNode, priorityVec, user, pkthdr, packet);
    // assert(priorityVec.size() == 2);

    long long thisPacketCycle = tsToCycle(&pkthdr->ts);
    assert(thisPacketCycle >= curCycle);

    if(thisPacketCycle - curCycle > 1){
        for(long long i=0; i<cumulatePktNum; i++){
            std::cout << "type:2" << std::endl;
        }
        cumulatePktNum = 0;
        if(curCycle != 0){
            std::cout << "type:0, idle_cycle:" << std::min(thisPacketCycle - curCycle - 1, MAX_INTERVAL_IDLECYCLE) << std::endl;
            idle_cycle_cnt++;
        }else{
            std::cout << "type:0, idle_cycle:100" << std::endl;
        }
        
    }

    curCycle = thisPacketCycle;
    // std::cout << "type:1, priority:"<< priorityVec[1] <<", tree_id:" << leafNode->nodeId << ", data_meta:1, data_payload:" << priorityVec[0] << "\n";
    // std::cout << "type:2\n";
    std::cout << "type:1, tree_id:" << leafNode->nodeId << ", meta:" << pktId++;
    for(size_t i=0; i<priorityVec.size(); i++){
        std::cout << ", priority" << i << ":" << priorityVec[i];
    }
    std::cout<<std::endl;
    cumulatePktNum++;
}

void tagPriority(const char* pcap_file, const char* trace_file, bool hasPFabric){
    if(hasPFabric){
        pFabricInitFlowRemainingSize(pcap_file);
    }

    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t* pcap_handle;

    // 打开 pcap 文件
    pcap_handle = pcap_open_offline(pcap_file, errbuf);
    if (pcap_handle == nullptr) {
        std::cerr << "Error opening pcap file: " << errbuf << std::endl;
        return;
    }

    freopen(trace_file, "w", stdout);
    if (pcap_loop(pcap_handle, 0, tagPriorityHandler, nullptr) < 0) {
        std::cerr << "Error in pcap_loop: " << pcap_geterr(pcap_handle) << std::endl;
        pcap_close(pcap_handle);
        return;
    }
    if(cumulatePktNum > 0){
        for(long long i=0; i<cumulatePktNum; i++){
            std::cout << "type:2" << std::endl;
        }
        cumulatePktNum = 0;
    }
    std::cout << "type:0, idle_cycle:" << MAX_IDLECYCLE << std::endl;
    fclose(stdout);

    // 关闭 pcap 文件
    pcap_close(pcap_handle);
    
    return;
}