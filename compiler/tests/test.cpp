#include <fstream>
#include "../PIFOTree.h"

using namespace std;

int main(int argc, char * argv[]){

    TreeNode root = createTreeRoot(SchedStrategyUnknown(), createPerfInfo(100));
    TreeNode lc = createTreeNode(SchedStrategyUnknown(), createPerfInfo(10));
    TreeNode rc = createTreeNode(SchedStrategyUnknown());

    attachNode(lc, root);
    attachNode(rc, root);

    checkMakeTree(root);

    ofstream OutStream;
    OutStream.open(argv[1]);

    printTree(root, OutStream);

    OutStream.close();
    
    return 0;
}