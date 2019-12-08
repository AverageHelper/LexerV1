//
//  DependencyGraph.cpp
//  LexerV1
//
//  Created by James Robinson on 12/5/19.
//

#include "DependencyGraph.h"



// MARK: - Graph

DependencyGraph::DependencyGraph() {
    this->nodes = std::map<int, DependencyGraph::Node>();
}

int DependencyGraph::getLastIndex() const {
    int max = -1;
    for (auto pair : nodes) {
        max = std::max(pair.first, max);
    }
    return max;
}

int DependencyGraph::appendNode(const Node &node) {
    int max = getLastIndex();
    
    nodes[max + 1] = node;
    return max + 1;
}

const std::pair<int, DependencyGraph::Node> DependencyGraph::nodeForRule(Rule* rule) {
    for (auto pair : nodes) {
        int id = pair.first;
        Node node = pair.second;
        
        if (node.getPrimaryRule() == rule) {
            return std::pair(id, node);
        }
    }
    
    Node result = Node(rule);
    int newID = appendNode(result);
    return std::pair(newID, result);
}

bool DependencyGraph::addDependency(Rule* parent, Rule* other) {
    int lastIndex = getLastIndex();
    
    auto parentNodePair = nodeForRule(parent);
    int parentNodeID = parentNodePair.first;
    Node parentNode = Node(parentNodePair.second);
    
    if (other != nullptr) {
        int otherNodeID = nodeForRule(other).first; // Grab ID of other node
        
        bool didAdd = parentNode.addAdjacency(otherNodeID);
        nodes[parentNodeID] = parentNode;
        
        if (didAdd || otherNodeID > lastIndex) {
            return true;
        }
        // Check that parent was added, even if we've got nothing here.
    }
    
    return parentNodeID > lastIndex; // Increased index if added
}

Rule* DependencyGraph::dependencyWithIdentifier(const std::string& identifier) {
    for (auto pair : this->nodes) {
        if (pair.second.getName() == identifier) {
            return pair.second.getPrimaryRule();
        }
    }
    
    return nullptr;
}

const std::map<int, DependencyGraph::Node>& DependencyGraph::getGraph() const {
    return this->nodes;
}

std::string DependencyGraph::toString() {
    std::ostringstream result = std::ostringstream();
    
    for (auto pair : nodes) {
        int id = pair.first;
        Node node = pair.second;
        
        result << "R" << id << ":";
        
        int adjacenciesListed = 0;
        size_t adjacencyCount = node.getAdjacencies().size();
        for (int adjID : node.getAdjacencies()) {
            result << "R" << adjID;
            adjacenciesListed += 1;
            
            if (adjacenciesListed < adjacencyCount) {
                result << ",";
            }
        }
        
        result << std::endl;
    }
    
    return result.str();
}



// MARK: - Node

DependencyGraph::Node::Node(Rule* primaryRule) {
    this->primaryRule = primaryRule;
    this->adjacencies = std::set<int>();
}

DependencyGraph::Node::Node(const DependencyGraph::Node &other) {
    this->primaryRule = other.primaryRule;
    this->adjacencies = other.adjacencies;
}

const std::set<int>& DependencyGraph::Node::getAdjacencies() const {
    return this->adjacencies;
}

bool DependencyGraph::Node::addAdjacency(int nodeID) {
    return this->adjacencies.insert(nodeID).second;
}

std::string DependencyGraph::Node::getName() const {
    if (this->primaryRule == nullptr) {
        return "nullptr";
    }
    return this->primaryRule->getHeadPredicate()->getIdentifier();
}

Rule* DependencyGraph::Node::getPrimaryRule() const {
    return this->primaryRule;
}
