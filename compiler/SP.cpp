#include <map>
#include <string>
#include <iostream>
#include <sstream>
#include <cassert>
#include <pcap.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include "SP.h"
#include "util.h"

StrategySP SchedStrategySP(bool isLeaf, std::map<std::string, int>* priorityTable){
    StrategySP strategySP = new StrategySP_;
    strategySP->isLeaf = isLeaf;
    // this will only effect at the leaf node
    // non-leaf node priorityTable will be filled during attach node
    if(isLeaf){
        assert(priorityTable != nullptr);
        for(auto &it : *priorityTable){
            strategySP->priorityTable[it.first] = it.second;
        }
    }
    return strategySP;
}

int calSPLeafPriority(unsigned char* user, const struct pcap_pkthdr* pkthdr, const unsigned char* packet, StrategySP strategySP) {
    std::string flowId = getFlowId(user, pkthdr, packet);

    assert(strategySP->priorityTable.find(flowId) != strategySP->priorityTable.end());

    int priority = strategySP->priorityTable[flowId];

    return priority;
}

int calSPNonLeafPriority(int childNodeId, StrategySP strategySP) {
    std::string nodeId_str = std::to_string(childNodeId);

    assert(strategySP->priorityTable.find(nodeId_str) != strategySP->priorityTable.end());

    int priority = strategySP->priorityTable[nodeId_str];

    return priority;
}
