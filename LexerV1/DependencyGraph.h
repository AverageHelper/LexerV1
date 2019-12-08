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
    
    const std::map<int, Node>& getGraph() const;
    
    /// Lists @c other as dependent upon the given @c parent relation.
    bool addDependency(Rule* parent, Rule *other);
    Rule* dependencyWithIdentifier(const std::string& identifier);
    
    std::string postOrderNumbers();
    std::string toString();
    
private:
    std::map<int, Node> nodes;
    
    int getLastIndex() const;
    
    /// Adds the given @c node to the graph, assigning it the highest numerical ID number.
    int appendNode(const Node& node);
    
    /// Retrieves the @c Node which wraps the given @c relation if one exists in the graph, or returns a new node for the relation after adding it to the graph.
    /// @returns A @c pair containing the node and its ID.
    const std::pair<int, DependencyGraph::Node> nodeForRule(Rule* rule);
    
    /// Computes post-order numbers on the graph, starting at the node with the given index @c start.
    /// @Returns The next post-order number, if we were to run another DFS on a different part of the forest.
    int computePostOrderNumbersForVectorsStartingAt(int start, int startingPostorder = 1);
};


struct DependencyGraph::Node {
private:
    Rule* primaryRule;
    std::set<int> adjacencies;
    int postOrderNumber;
    
public:
    Node(Rule* primaryRule = nullptr);
    Node(const Node &other);
    
    int getPostOrderNumber() const;
    void setPostOrderNumber(int num);
    
    Rule* getPrimaryRule() const;
    std::string getName() const;
    
    const std::set<int>& getAdjacencies() const;
    bool addAdjacency(int nodeID);
};

#endif /* DependencyGraph_h */
