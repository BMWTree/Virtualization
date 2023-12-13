#include <fstream>
#include <map>
#include <string>
#include "../compiler/vPIFOLib.h"

using namespace std;

int main(int argc, char * argv[]){

    // std::map<std::string, double> weightTable;
    // weightTable["10.1.1.1, 10.1.4.2, 49153, 8080, TCP"] = 0.5;

    // std::map<std::string, int> priorityTable;
    // priorityTable["10.1.1.1, 10.1.4.2, 49153, 8080, TCP"] = 1;

    TreeNode root = createTreeRoot(SchedStrategyPFabric(SchedStrategyPFabric()), createPerfInfo(100));

    attachFlow("10.1.1.1, 10.1.4.2, 49153, 8080, TCP", root);
    attachFlow("10.1.1.1, 10.1.4.2, 49154, 8080, TCP", root);
    attachFlow("10.1.1.1, 10.1.4.2, 49155, 8080, TCP", root);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49153, TCP", root);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49154, TCP", root);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49155, TCP", root);

    bool hasPFabric = false;
    checkMakeTree(root, hasPFabric);

    ofstream OutStream;
    OutStream.open(argv[1]);

    printPushConvertTable(root, OutStream);

    OutStream.close();

    std::string inputFileName = argv[1];
    std::string outputFileName = getTraceFileName(inputFileName);
    tagPriority("../trace/PcapTrace-6-0.pcap", outputFileName.c_str(), hasPFabric);
    
    return 0;
}