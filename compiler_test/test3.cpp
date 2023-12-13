#include <fstream>
#include <map>
#include <string>
#include "../compiler/vPIFOLib.h"

// test for generating table
// key is leaf node id, value is the path from leaf to root

using namespace std;

int main(int argc, char * argv[]){

    TreeNode root = createTreeRoot(SchedStrategySP(SchedStrategySP()), createPerfInfo(100));
    TreeNode y = createTreeNode(SchedStrategyWFQ(SchedStrategyWFQ()));
    TreeNode x = createTreeNode(SchedStrategyWFQ(SchedStrategyWFQ()));
    TreeNode z = createTreeNode(SchedStrategySP(SchedStrategySP()));

    attachNode(x, root, 1);
    attachNode(y, root, 2);
    attachNode(z, y, 0.5);

    bool hasPFabric = false;
    checkMakeTree(root, hasPFabric);

    ofstream OutStream;
    OutStream.open(argv[1]);

    printPushConvertTable(root, OutStream);

    OutStream.close();
    return 0;
}