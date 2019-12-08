//
//  EvaluatingDatabases.h
//  LexerV1
//
//  Created by James Robinson on 11/20/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef EvaluatingDatabases_h
#define EvaluatingDatabases_h

#include <sstream>
#include <map>
#include "Database.h"
#include "DatalogProgram.h"
#include "DependencyGraph.h"

int extern indexOfValueInVector(std::string query, const std::vector<std::string> &domain);

void extern evaluateSchemes(Database *database, DatalogProgram *program);
void extern evaluateFacts(Database *database, DatalogProgram *program);
std::string extern evaluateQueryItem(Relation &result,
                                     Database *database,
                                     Predicate *query,
                                     bool outputSuccess = true);
std::string extern evaluateQueries(Database *database, DatalogProgram *program, bool printingHeader = true);
std::string extern evaluateRules(Database *database, DatalogProgram *program, bool optimizeDependencies = false);

/// Lists all dependent and independent rules in the given @c program.
DependencyGraph* buildDependencyGraph(DatalogProgram *program);

/// Reverses the direction of each edge in @c graph.
void invert(DependencyGraph& graph);

/// Returns a set of the strongly-connected components of the given @c graph.
std::set<DependencyGraph> stronglyConnectedComponentsFromGraph(const DependencyGraph& graph);

#endif /* EvaluatingDatabases_h */
