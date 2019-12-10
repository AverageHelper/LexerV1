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

bool DependencyGraph::addVertex(Node node, int identifier) {
    if (this->nodes.count(identifier) > 0 &&
        this->nodes.at(identifier) == node) {
        return false;
    }
    this->nodes[identifier] = node;
    return true;
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

const std::vector<DependencyGraph::Node> DependencyGraph::allVertices() const {
    std::vector<Node> result = std::vector<Node>();
    
    for (auto pair : nodes) {
        result.push_back(pair.second);
    }
    
    return result;
}

int DependencyGraph::computePostOrderNumbersForVectorsStartingAt(int start, int startingPostorder) {
    if (this->nodes.empty()) {
        return -1;
    }
    
    std::set<int> visited = std::set<int>();
    std::stack<int> stack = std::stack<int>();
    int previousPostOrder = startingPostorder;
    
    stack.push(start);
    
    while (!stack.empty()) {
        int currentNode = stack.top();
        
        bool alreadyVisited = !visited.insert(currentNode).second;
        if (alreadyVisited) {
            Node node = nodes.at(currentNode);
            node.setPostOrderNumber(previousPostOrder++);
            nodes[currentNode] = node;
            stack.pop();
            continue;
        }
        
        // The numerically-first index goes next.
        for (auto idx : nodes.at(currentNode).getAdjacencies()) {
            if (visited.find(idx) == visited.end()) { // If not already visited...
                stack.push(idx);
            }
        }
        
    }
    
    return previousPostOrder;
}

void DependencyGraph::computePostOrderNumbersForVertices() {
    // Run DFS-Forest on the dependency graph.
    int nextPostorder = computePostOrderNumbersForVectorsStartingAt(0);
    for (auto pair : nodes) {
        if (pair.second.getPostOrderNumber() > -1) { continue; }
        nextPostorder = computePostOrderNumbersForVectorsStartingAt(pair.first, nextPostorder);
    }
}

std::vector<std::pair<int, DependencyGraph::Node>> DependencyGraph::postOrdering() {
    computePostOrderNumbersForVertices(); // Guarantees each node has a postOrderNumber >= 1
    
    std::vector<std::pair<int, Node>> result = std::vector<std::pair<int, Node>>();
    if (nodes.empty()) { return result; }
    result.push_back(*nodes.begin());
    
    for (auto pair : nodes) { // For each vertex...
        size_t oldSize = result.size();
        
        // Insertion sort:
        for (size_t index = 0; index < result.size(); index += 1) { // For each sorted node...
            
            if (pair.second.getPostOrderNumber() < result.at(index).second.getPostOrderNumber()) {
                // If we're smaller, go on in!
                result.insert(result.begin() + index, pair);
                break;
                
            } else if (pair.second.getPostOrderNumber() == result.at(index).second.getPostOrderNumber()) {
                // If we're the same, go to next.
                oldSize += 1;
            }
        }
        
        if (oldSize == result.size()) {
            // Didn't insert... Append!
            result.push_back(pair);
        }
    }
    
    return result;
}

std::string DependencyGraph::postOrderNumbers() {
    computePostOrderNumbersForVertices();
    
    // Print the post-order numbers
    std::ostringstream result = std::ostringstream();
    for (auto pair : nodes) {
        result << "R" << pair.first << ": " << pair.second.getPostOrderNumber() << std::endl;
    }
    
    return result.str();
}

std::string DependencyGraph::toString() const {
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

std::string DependencyGraph::verticesByIDToString() const {
    std::ostringstream str = std::ostringstream();
    
    size_t verticesListed = 0;
    for (auto pair : getGraph()) {
        str << "R" << pair.first;
        verticesListed += 1;
        if (verticesListed < getGraph().size()) {
            str << ",";
        }
    }
    
    return str.str();
}



// MARK: - Node

DependencyGraph::Node::Node(Rule* primaryRule) {
    this->primaryRule = primaryRule;
    this->adjacencies = std::set<int>();
    this->postOrderNumber = -1;
}

DependencyGraph::Node::Node(const DependencyGraph::Node &other) {
    this->primaryRule = other.primaryRule;
    this->adjacencies = other.adjacencies;
    this->postOrderNumber = other.postOrderNumber;
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

int DependencyGraph::Node::getPostOrderNumber() const {
    return this->postOrderNumber;
}

void DependencyGraph::Node::setPostOrderNumber(int num) {
    this->postOrderNumber = num;
}

bool DependencyGraph::Node::operator ==(const Node &other) const {
    return (*this->primaryRule == *other.primaryRule &&
            this->adjacencies == other.adjacencies);
}
