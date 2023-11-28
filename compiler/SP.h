#pragma once

#include <map>
#include <string>

typedef struct StrategySP_* StrategySP;

struct StrategySP_{
    bool isLeaf;
    // if isLeaf == true, then the priorityTable is flow(5 tuple) -> priority
    // else, then the priorityTable is nodeId(int) -> priority
    std::map<std::string, int> priorityTable;
};

StrategySP SchedStrategySP(bool isLeaf, std::map<std::string, int>* priorityTable);
int calSPLeafPriority(unsigned char* user, const struct pcap_pkthdr* pkthdr, const unsigned char* packet, StrategySP strategySP);
int calSPNonLeafPriority(int nodeId, StrategySP strategySP);