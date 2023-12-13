#include <fstream>
#include <map>
#include <string>
#include "../compiler/vPIFOLib.h"

using namespace std;

int main(int argc, char * argv[]){

    TreeNode root = createTreeRoot(SchedStrategyWFQ(SchedStrategyWFQ()), createPerfInfo(100));
    TreeNode normal_user = createTreeNode(SchedStrategyWFQ(SchedStrategyWFQ()));
    TreeNode vip_user = createTreeNode(SchedStrategyWFQ(SchedStrategyWFQ()));
    attachNode(normal_user, root, 0.3);
    attachNode(vip_user, root, 0.7);

    attachFlow("10.1.1.1, 10.1.4.2, 49153, 8080, TCP", normal_user, 0.1);
    attachFlow("10.1.2.1, 10.1.5.2, 49153, 8080, TCP", vip_user, 0.1);
    attachFlow("10.1.1.1, 10.1.4.2, 49154, 8080, TCP", normal_user, 0.2);
    attachFlow("10.1.2.1, 10.1.5.2, 49154, 8080, TCP", vip_user, 0.15);
    attachFlow("10.1.1.1, 10.1.4.2, 49155, 8080, TCP", normal_user, 0.2);
    attachFlow("10.1.2.1, 10.1.5.2, 49155, 8080, TCP", vip_user, 0.2);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49153, TCP", normal_user, 0.1);
    attachFlow("10.1.5.2, 10.1.2.1, 8080, 49153, TCP", vip_user, 0.1);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49154, TCP", normal_user, 0.2);
    attachFlow("10.1.5.2, 10.1.2.1, 8080, 49154, TCP", vip_user, 0.15);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49155, TCP", normal_user, 0.2);
    attachFlow("10.1.5.2, 10.1.2.1, 8080, 49155, TCP", vip_user, 0.2);

    bool hasPFabric = false;
    checkMakeTree(root, hasPFabric);

    ofstream OutStream;
    OutStream.open(argv[1]);

    printPushConvertTable(root, OutStream);

    OutStream.close();

    std::string inputFileName = argv[1];
    std::string outputFileName = getTraceFileName(inputFileName);
    tagPriority("../trace/PcapTrace-6-3.pcap", outputFileName.c_str(), hasPFabric);
    
    return 0;
}