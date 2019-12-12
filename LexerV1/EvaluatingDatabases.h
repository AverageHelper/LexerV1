//
//  EvaluatingDatabases.h
//  LexerV1
//
//  Created by James Robinson on 11/20/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef EvaluatingDatabases_h
#define EvaluatingDatabases_h

#include "Database.h"
#include "DatalogProgram.h"
#include "DependencyGraph.h"
#include <string>
#include <sstream>
#include <vector>
#include <map>
#include <stack>

using std::string;
using std::vector;
using std::set;
using std::map;
using std::pair;
using std::stack;

int extern indexOfValueInVector(string query, const vector<string> &domain);

void extern evaluateSchemes(Database *database,
                            DatalogProgram *program);
void extern evaluateFacts(Database *database,
                          DatalogProgram *program);
string extern evaluateQueryItem(Relation &result,
                                Database *database,
                                Predicate *query,
                                bool outputSuccess = true);
string extern evaluateQueries(Database *database,
                              DatalogProgram *program,
                              bool printingHeader = true);
string evaluateRulesInSubgraph(const set<pair<int, Rule*>>& subgraph,
                               const DependencyGraph* depGraph,
                               Database *database,
                               int& passCount);
string extern evaluateRules(Database *database,
                            DatalogProgram *program,
                            bool optimizeDependencies = false);

/// Lists all dependent and independent rules in the given @c program.
DependencyGraph* buildDependencyGraph(DatalogProgram *program);

/// Reverses the direction of each edge in @c graph.
void invert(DependencyGraph& graph);

/// Finds and returns the strongly-connected subgraphs from the given @c graph.
///
/// @Param graph The original dependency graph.
vector<DependencyGraph> stronglyConnectedComponentsFromGraph(const DependencyGraph& graph);

void stronglyConnectedComponentsFromGraph(const DependencyGraph& graph, vector<DependencyGraph>& components);
void stronglyConnectedComponentsFromGraphReference(const DependencyGraph* graph, vector<DependencyGraph>& components);

#endif /* EvaluatingDatabases_h */
