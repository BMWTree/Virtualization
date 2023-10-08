#pragma once

#include <vector>
#include <ostream>
#include "SchedStrategy.h"
#include "PerfInfo.h"

using std::vector;
using std::ostream;

typedef struct TreeNode_* TreeNode;

struct TreeNode_{
    int nodeId;
    SchedStrategy strategy;
    PerfInfo minPerf;
    PerfInfo actualPerf;
    TreeNode father;
    vector<TreeNode> children;
};

TreeNode createTreeNode(SchedStrategy strategy, PerfInfo minPerf=nullptr);
TreeNode createTreeRoot(SchedStrategy strategy, PerfInfo actualPerf, PerfInfo minPerf=nullptr);
void attachNode(TreeNode node, TreeNode father);
void checkMakeTree(TreeNode root);

void printTreeNode(TreeNode node, ostream& os);
void printTree(TreeNode node, ostream& os);

