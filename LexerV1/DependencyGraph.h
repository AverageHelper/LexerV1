//
//  DependencyGraph.h
//  LexerV1
//
//  Created by James Robinson on 12/5/19.
//

#ifndef DependencyGraph_h
#define DependencyGraph_h

#include "Rule.h"
#include <string>
#include <vector>
#include <map>
#include <set>
#include <stack>
#include <sstream>


class DependencyGraph {
public:
    struct Node;
    
    DependencyGraph();
    DependencyGraph(const DependencyGraph& other);
    ~DependencyGraph();
    
    const std::map<int, Node>& getNodes() const;
    const std::vector<Node> allVertices() const;
    
    /// Lists @c other as dependent upon the given @c parent relation.
    bool addDependency(Rule* parent, Rule *other);
    bool addVertex(const Node& node, int identifier);
    Rule* dependencyWithIdentifier(const std::string& identifier);
    
    /// A string representation of the graph's post-order numbers.
    std::string postOrderNumbers();
    
    /// Returns an inverted copy of the graph.
    DependencyGraph inverted() const;
    
    /// Returns a @c vector of vertices, in order of their post-order number.
    std::vector<std::pair<int, Node>> postOrdering();
    std::string toString() const;
    std::string verticesByIDToString() const;
    
private:
    std::map<int, Node> nodes;
    
    int getLastIndex() const;
    
    /// Adds the given @c node to the graph, assigning it the highest numerical ID number.
    std::pair<int, Node> appendNode(const Node& node);
    
    /// Retrieves the @c Node which wraps the given @c relation if one exists in the graph, or returns a new node for the relation after adding it to the graph.
    /// @returns A @c pair containing the node and its ID.
    std::pair<int, Node> nodeForRule(Rule* rule);
    
    /// Computes post-order numbers for each node on the graph.
    void computePostOrderNumbersForVertices();
    
    /// Computes post-order numbers for each node on the graph, starting at the node with the given index @c start.
    /// @Returns The next post-order number, if we were to run another DFS on a different part of the forest.
    int computePostOrderNumbersForVectorsStartingAt(int start, int startingPostorder = 1);
};


struct DependencyGraph::Node {
private:
    Rule* primaryRule;
    std::map<int, Rule*> adjacencies;
    int postOrderNumber;
    
public:
    Node(Rule* primaryRule = nullptr);
    Node(const Node &other);
    ~Node();
    
    int getPostOrderNumber() const;
    void setPostOrderNumber(int num);
    
    Rule* getPrimaryRule() const;
    std::string getName() const;
    
    const std::map<int, Rule*>& getAdjacencies() const;
    bool addAdjacency(int nodeID, Rule* rule);
    
    bool operator ==(const Node &other) const;
};

#endif /* DependencyGraph_h */
