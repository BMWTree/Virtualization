#include <fstream>
#include <map>
#include <string>
#include "../compiler/vPIFOLib.h"

// test for generating table
// key is leaf node id, value is the path from leaf to root

using namespace std;

int main(int argc, char * argv[]){

    // std::map<std::string, double> weightTable;
    // weightTable["10.1.1.1, 10.1.4.2, 49153, 8080, TCP"] = 0.5;

    // std::map<std::string, int> priorityTable;
    // priorityTable["10.1.1.1, 10.1.4.2, 49153, 8080, TCP"] = 1;

    TreeNode root = createTreeRoot(SchedStrategyPFabric(SchedStrategyPFabric()), createPerfInfo(100), "10.1.1.1");

    TreeNode lc = createTreeNode(SchedStrategyUnknown(), "10.1.1.1");
    TreeNode rc = createTreeNode(SchedStrategyUnknown(), "10.1.1.1");

    TreeNode rlc = createTreeNode(SchedStrategyUnknown(), "10.1.1.1");
    TreeNode rrc = createTreeNode(SchedStrategyUnknown(), "10.1.1.1");


    attachNode(lc, root);
    attachNode(rc, root);
    attachNode(rlc, rc);
    attachNode(rrc, rc);

    bool hasPFabric = false;
    checkMakeTree(root, hasPFabric);

    ofstream OutStream;
    OutStream.open(argv[1]);

    printPushConvertTable(root, OutStream);

    OutStream.close();
    return 0;
}