#include <fstream>
#include <map>
#include <string>
#include "../compiler/vPIFOLib.h"

using namespace std;

int main(int argc, char * argv[]){

    TreeNode root = createTreeRoot(SchedStrategySP(SchedStrategySP()), createPerfInfo(100));
    TreeNode normal_user = createTreeNode(SchedStrategySP(SchedStrategySP()));
    TreeNode vip_user = createTreeNode(SchedStrategySP(SchedStrategySP()));
    attachNode(normal_user, root, 2);
    attachNode(vip_user, root, 1);

    attachFlow("10.1.1.1, 10.1.4.2, 49153, 8080, TCP", normal_user, 1);
    attachFlow("10.1.2.1, 10.1.5.2, 49153, 8080, TCP", vip_user, 1);
    attachFlow("10.1.1.1, 10.1.4.2, 49154, 8080, TCP", normal_user, 2);
    attachFlow("10.1.2.1, 10.1.5.2, 49154, 8080, TCP", vip_user, 2);
    attachFlow("10.1.1.1, 10.1.4.2, 49155, 8080, TCP", normal_user, 3);
    attachFlow("10.1.2.1, 10.1.5.2, 49155, 8080, TCP", vip_user, 3);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49153, TCP", normal_user, 1);
    attachFlow("10.1.5.2, 10.1.2.1, 8080, 49153, TCP", vip_user, 1);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49154, TCP", normal_user, 2);
    attachFlow("10.1.5.2, 10.1.2.1, 8080, 49154, TCP", vip_user, 2);
    attachFlow("10.1.4.2, 10.1.1.1, 8080, 49155, TCP", normal_user, 3);
    attachFlow("10.1.5.2, 10.1.2.1, 8080, 49155, TCP", vip_user, 3);

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