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

DependencyGraph::DependencyGraph(const DependencyGraph& other) {
    for (auto nodePair : other.nodes) {
        Node newNode = Node(nodePair.second);
        this->nodes[nodePair.first] = newNode;
    }
}

DependencyGraph::~DependencyGraph() {
    
}

int DependencyGraph::getLastIndex() const {
    int max = -1;
    for (auto pair : nodes) {
        max = std::max(pair.first, max);
    }
    return max;
}

std::pair<int, DependencyGraph::Node> DependencyGraph::appendNode(const Node& node) {
    int max = getLastIndex();
    
    return *nodes.insert(std::make_pair(max + 1, node)).first;
//    nodes[max + 1] = node;
//    return nodes.at(max + 1);
}

std::pair<int, DependencyGraph::Node> DependencyGraph::nodeForRule(Rule* rule) {
    if (rule == nullptr) {
        std::cout << "--- WARNING: Cannot search DependencyGraph for null Rule. ---" << std::endl;
    }
    
    for (auto pair : nodes) {
        // Check each extant pair
        if (rule != nullptr && *pair.second.getPrimaryRule() == *rule) {
            return pair;
        }
    }
    
    return appendNode(Node(rule));
}

bool DependencyGraph::addDependency(Rule* parent, Rule* other) {
    int lastIndex = getLastIndex();
    
    auto parentNodePair = nodeForRule(parent);
    int parentNodeID = parentNodePair.first;
    
    if (other != nullptr) {
        int otherNodeID = nodeForRule(other).first; // Grab ID of other node
        
        bool didAdd = parentNodePair.second.addAdjacency(otherNodeID, other); // Add other node to graph
        nodes[parentNodeID] = parentNodePair.second;
        
        if (didAdd || otherNodeID > lastIndex) {
            return true;
        }
        // Check that parent was added, even if we've got nothing here.
    }
    
    return parentNodeID > lastIndex; // Increased index if added
}

bool DependencyGraph::addVertex(const Node& node, int identifier) {
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

const std::map<int, DependencyGraph::Node>& DependencyGraph::getNodes() const {
    return this->nodes;
}

const std::vector<DependencyGraph::Node> DependencyGraph::allVertices() const {
    std::vector<Node> result = std::vector<Node>();
    
    for (auto pair : nodes) {
        result.push_back(pair.second);
    }
    
    return result;
}

int DependencyGraph::computePostOrderNumbersForSubtreeStartingAt(int startIndex, int startingPostorder, std::set<int>& visited) {
    if (this->nodes.empty()) {
        return -1;
    }
    
    std::stack<int> stack = std::stack<int>();
    int previousPostOrder = startingPostorder;
    
    stack.push(startIndex);
    
    while (!stack.empty()) {
        int currentNode = stack.top();
        
        bool alreadyVisited = !visited.insert(currentNode).second;
        if (alreadyVisited) {
            Node node = nodes.at(currentNode);
            if (node.getPostOrderNumber() > -1) { stack.pop(); continue; }
            node.setPostOrderNumber(previousPostOrder++);
            nodes[currentNode] = node;
            stack.pop();
            continue;
        }
        
        // The numerically-first index goes next. (so we iterate here in reverse)
        auto adjacencies = nodes.at(currentNode).getAdjacencies();
        for (auto rulePair = adjacencies.rbegin(); rulePair != adjacencies.rend(); rulePair++) {
            if (visited.find(rulePair->first) == visited.end()) { // If not already visited...
                stack.push(rulePair->first);
            }
        }
        
    }
    
    return previousPostOrder;
}

void DependencyGraph::computePostOrderNumbersForVertices() {
    
    // Reset old post-order numbers.
    for (auto nodePair : nodes) {
        Node newNode = nodePair.second;
        newNode.setPostOrderNumber(-1);
        nodes[nodePair.first] = newNode;
    }
    
    // Run DFS-Forest on the dependency graph.
    std::set<int> visited = std::set<int>();
    int nextPostorder = computePostOrderNumbersForSubtreeStartingAt(0, 1, visited);
    for (auto pair : nodes) {
        if (pair.second.getPostOrderNumber() > -1) { continue; }
        nextPostorder = computePostOrderNumbersForSubtreeStartingAt(pair.first, nextPostorder, visited);
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

DependencyGraph DependencyGraph::inverted() const {
    DependencyGraph result = DependencyGraph();
    
    for (auto nodePair : getNodes()) { // For each node...
        Node newNode = Node(nodePair.second.getPrimaryRule());
        result.addVertex(newNode, nodePair.first);  // Number it in the new graph.
    }
    
    for (auto nodePair : getNodes()) {
        // Reverse each node's edges
        for (auto adj : nodePair.second.getAdjacencies()) { // For each adjacency...
            int adjID = adj.first;
            
            Node newNode = result.getNodes().at(adjID);
            newNode.addAdjacency(nodePair.first, nodePair.second.getPrimaryRule());  // Make adj: this
            result.addVertex(newNode, adjID);
        }
    }
    
    return result;
}

std::string DependencyGraph::toString() const {
    std::ostringstream result = std::ostringstream();
    
    for (auto pair : getNodes()) {
        int id = pair.first;
        
        result << "R" << id << ":";
        
        std::map<int, Rule*> adjacencies = pair.second.getAdjacencies();
        int adjacenciesListed = 0;
        int adjacencyCount = static_cast<int>(adjacencies.size());
        for (auto rulePair : adjacencies) {
            result << "R" << rulePair.first;
            
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
    for (auto pair : getNodes()) {
        str << "R" << pair.first;
        verticesListed += 1;
        if (verticesListed < getNodes().size()) {
            str << ",";
        }
    }
    
    return str.str();
}



// MARK: - Node

DependencyGraph::Node::Node(Rule* primaryRule) {
    this->primaryRule = primaryRule;
    this->adjacencies = std::map<int, Rule*>();
    this->postOrderNumber = -1;
}

DependencyGraph::Node::Node(const DependencyGraph::Node &other) {
    this->primaryRule = other.primaryRule;
    this->adjacencies = other.adjacencies;
    this->postOrderNumber = other.postOrderNumber;
}

DependencyGraph::Node::~Node() {
    // :)
}

const std::map<int, Rule*>& DependencyGraph::Node::getAdjacencies() const {
    return this->adjacencies;
}

bool DependencyGraph::Node::addAdjacency(int nodeID, Rule* rule) {
    if (this->adjacencies.find(nodeID) == adjacencies.end() || // If rule ID doesn't already exist
        *this->adjacencies.at(nodeID) != *rule) { // If rule is different
        this->adjacencies[nodeID] = rule;
        return true;
    }
    return false;
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
