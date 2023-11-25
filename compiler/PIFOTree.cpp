#include <vector>
#include <iostream>
#include <ostream>
#include "PIFOTree.h"
#include "PerfInfo.h"
#include "SchedStrategy.h"

using namespace std;

static int nodeId;

TreeNode createTreeNode(SchedStrategy strategy, PerfInfo minPerf){
    TreeNode node = new TreeNode_;
    node->nodeId = nodeId++;
    node->strategy = strategy;
    node->minPerf = minPerf;
    node->actualPerf = new PerfInfo_;
    node->father = nullptr;
    node->children.clear();
    return node;
}

TreeNode createTreeRoot(SchedStrategy strategy, PerfInfo actualPerf, PerfInfo minPerf){
    TreeNode node = new TreeNode_;
    node->nodeId = nodeId++;
    node->strategy = strategy;
    node->minPerf = minPerf;
    node->actualPerf = actualPerf;
    node->father = nullptr;
    node->children.clear();
    return node;
}

void attachNode(TreeNode node, TreeNode father){
    node->father = father;
    father->children.emplace_back(node);
}

void collectLeafNode(vector<TreeNode>& leafNodes, TreeNode node){
    if(node->children.empty()){
        leafNodes.emplace_back(node);
    }
    for(auto &it : node->children){
        collectLeafNode(leafNodes, it);
    }
}

void upDeliverMinPerfToRoot(TreeNode leafNode, TreeNode root){
    if(!leafNode || !(leafNode->minPerf)) return;
    while(leafNode->father && leafNode->nodeId != root->nodeId){
        if(!(leafNode->father->minPerf)){
            leafNode->father->minPerf = new PerfInfo_;
        }
        sumPerfInfo(leafNode->minPerf, leafNode->father->minPerf);
        leafNode->father->strategy = SchedStrategyWFQ();
        leafNode = leafNode->father;
    }
}

void downDeliverMarginPerfToLeaf(TreeNode node){
    if(node->children.empty()) return;
    PerfInfo_ marginPerf_, dividedPerfInfo_;
    getMarginPerf(node->actualPerf, node->minPerf, &marginPerf_);
    dividePerfEqually(&marginPerf_, node->children.size(), &dividedPerfInfo_);
    for(auto &it : node->children){
        sumPerfInfo(&dividedPerfInfo_, it->actualPerf);
        sumPerfInfo(it->minPerf, it->actualPerf);
        downDeliverMarginPerfToLeaf(it);
    }
}

void checkMakeTree(TreeNode root){
    vector<TreeNode> leafNodes;
    collectLeafNode(leafNodes, root);

    for(auto &node : leafNodes){
        upDeliverMinPerfToRoot(node, root);
    }

    if(!checkPerfInfoMeet(root->actualPerf, root->minPerf)){
        cout << "Error: The minimum requirement exceeds the actual capacity!" << endl;
    }else{
        downDeliverMarginPerfToLeaf(root);
    }
}

void printTreeNode(TreeNode node, ostream& os){
    os << "Node " << node->nodeId << " :\n";
    os << "SchedStrategy:\n";
    if(node->strategy){
        printSchedStrategy(node->strategy, os);
    }else{
        os << "\tnil\n";
    }
    os << "minPerf:\n";
    if(node->minPerf){
        printPerfInfo(node->minPerf, os);
    }else{
        os << "\tnil\n";
    }
    os << "actualPerf:\n";
    if(node->actualPerf){
        printPerfInfo(node->actualPerf, os);
    }else{
        os << "\tnil\n";
    }
    os << "father: ";
    if(node->father){
        os << node->father->nodeId;
    }else{
        os << "nil";
    }
    os << "\n";
    os << "children: ";
    if(!node->children.empty()){
        for(auto &it : node->children){
            os << it->nodeId << " ";
        }
    }else{
        os << "nil";
    }
    os << "\n\n";
}

void printTree(TreeNode node, ostream& os){
    if(!node) return;
    printTreeNode(node, os);
    for(auto &it : node->children){
        printTree(it, os);
    }
}