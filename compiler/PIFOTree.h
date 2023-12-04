#pragma once

#include <vector>
#include <ostream>
#include <string>
#include "util.h"
#include "SchedStrategy.h"
#include "PerfInfo.h"

typedef struct TreeNode_* TreeNode;

struct TreeNode_{
    int nodeId;
    SchedStrategy strategy;
    PerfInfo minPerf;
    PerfInfo actualPerf;
    TreeNode father;
    std::vector<TreeNode> children;
    // leaf node will be mapped to a srcIP
    std::string srcIP;
};

TreeNode createTreeNode(SchedStrategy strategy, std::string srcIP="", PerfInfo minPerf=nullptr);
TreeNode createTreeRoot(SchedStrategy strategy, PerfInfo actualPerf, std::string srcIP="", PerfInfo minPerf=nullptr);
void attachNode(TreeNode node, TreeNode father, int priority=-1, double weight=0.0);
void checkMakeTree(TreeNode root, bool& hasPFabric);

void printTreeNode(TreeNode node, std::ostream& os);
void printTree(TreeNode node, std::ostream& os);
void printPushConvertTable(TreeNode root, ostream& os);

