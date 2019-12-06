//
//  DependencyGraph.h
//  LexerV1
//
//  Created by James Robinson on 12/5/19.
//

#ifndef DependencyGraph_h
#define DependencyGraph_h

#include "Relation.h"
#include <string>
#include <vector>
#include <map>
#include <set>
#include <sstream>


class DependencyGraph {
public:
    struct Node;
    
    DependencyGraph();
    
    /// Lists @c other as dependent upon the given @c parent relation.
    bool addDependency(Relation* parent, Relation *other);
    const std::map<int, Node>& getGraph() const;
    
    std::string toString();
    
private:
    std::map<int, Node> nodes;
    
    int getLastIndex() const;
    
    /// Adds the given @c node to the graph, assigning it the highest numerical ID number.
    int appendNode(const Node& node);
    
    /// Retrieves the @c Node which wraps the given @c relation if one exists in the graph, or returns a new node for the relation after adding it to the graph.
    /// @returns A @c pair containing the node and its ID.
    const std::pair<int, DependencyGraph::Node> nodeForRelation(Relation* relation);
};


struct DependencyGraph::Node {
private:
    Relation* primaryRelation;
    std::set<int> adjacencies;
    
public:
    Node(Relation* primaryRelation = nullptr);
    Node(const Node &other);
    
    std::string getName() const;
    const std::set<int>& getAdjacencies() const;
    
    bool addAdjacency(int nodeID);
};

#endif /* DependencyGraph_h */
