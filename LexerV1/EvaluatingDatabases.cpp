//
//  EvaluatingDatabases.cpp
//  LexerV1
//
//  Created by James Robinson on 11/21/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include "EvaluatingDatabases.h"

int indexOfValueInVector(std::string query, const std::vector<std::string> &domain) {
    for (unsigned int idx = 0; idx < domain.size(); idx += 1) {
        std::string val = domain.at(idx);
        if (val == query) {
            return idx;
        }
    }
    
    return -1;
}

// MARK: - Schemes

void evaluateSchemes(Database *database, DatalogProgram *program) {
    for (unsigned int schemeIdx = 0; schemeIdx < program->getSchemes().size(); schemeIdx += 1) {
        Predicate* scheme = program->getSchemes().at(schemeIdx);
        std::vector<std::string> titles = scheme->getItems();
        
        Relation* relation = new Relation(scheme->getIdentifier(), scheme->getItems());
        database->addRelation(relation);
    }
}

// MARK: - Facts

void evaluateFacts(Database *database, DatalogProgram *program) {
    for (unsigned int factIdx = 0; factIdx < program->getFacts().size(); factIdx += 1) {
        Predicate* fact = program->getFacts().at(factIdx);
        std::vector<std::string> items = fact->getItems();
        
        Relation* relation = database->relationWithName(fact->getIdentifier());
        
        if (relation != nullptr) {
            Tuple tuple = Tuple(items);
            relation->addTuple(tuple);
        }
    }
}

// MARK: - Queries

std::string evaluateQueryItem(Relation &result,
                              Database *database,
                              Predicate *query,
                              bool outputSuccess) {
    // Evaluate each item in query
    std::vector<size_t> matchColumns = {};
    std::vector< std::pair<size_t, std::string> > matchValues = {};
    
    std::map<std::string, std::string> queryCols;
    std::vector<std::string> oldCols = {};
    std::vector<std::string> newCols = {};
    std::vector<std::string> processedOperands = {};
    
    for (unsigned int col = 0; col < query->getItems().size(); col += 1) {
        std::string val = query->getItems().at(col);
        
        // If we find a constant, σ col=val
        if (val.at(0) == '\'') {
            matchValues.push_back(std::make_pair(col, val));
            continue;
        } else if (indexOfValueInVector(val, newCols) == -1) {
            // Remember pair if we haven't already
            
            queryCols.insert(std::make_pair(result.getScheme().at(col), val));
            oldCols.push_back(result.getScheme().at(col));
            newCols.push_back(val);
        }
        
        // If we find a matching column, σ col=duplicateCol
        int duplicateCol = indexOfValueInVector(val, processedOperands);
        if (duplicateCol >= 0) {
            matchColumns.push_back(col); // inefficient to throw so many of the same in here?
            matchColumns.push_back(duplicateCol);
        } else {
            processedOperands.push_back(val);
        }
    }
    
    // Make row selections from query
    if (!matchColumns.empty()) {
        result.select({ matchColumns });
    }
    if (!matchValues.empty()) {
        result.select(matchValues);
    }
    
    std::ostringstream str = std::ostringstream();
    if (outputSuccess && result.getContents().empty()) {
        str << "No" << std::endl;
    } else if (outputSuccess) {
        str << "Yes(" << result.getContents().size() << ")" << std::endl;
    }
    
    // Project only the columns we want.
    result.project(oldCols);
    
    // Rename the columns to the names of the variables found in the query
    Tuple newScheme = result.getScheme();
    for (size_t i = 0; i < newCols.size(); i += 1) {
        auto newCol = newCols.at(i);
        newScheme.at(i) = newCol;
    }
    result.rename(newScheme);
    
    return str.str();
}

std::string evaluateQueries(Database *database, DatalogProgram *program, bool printingHeader) {
    std::ostringstream str = std::ostringstream();
    if (printingHeader) {
        str << "Query Evaluation" << std::endl;
    }
    for (unsigned int i = 0; i < program->getQueries().size(); i += 1) {
        Predicate* query = program->getQueries().at(i);
        
        str << query->toString() << " ";
        
        Relation* relation = database->relationWithName(query->getIdentifier());
        if (relation == nullptr) {
            str << "No" << std::endl;
            continue;
        }
        Relation found = *relation;
        str << evaluateQueryItem(found, database, query);
        
        // If there are variables in the query, output the tuples from the resulting relation.
        for (Tuple t : found.getContents()) {
            str << "  " << found.stringForTuple(t) << std::endl;
        }
    }
    
    std::string output = str.str();
    for (size_t i = output.size() - 1; i >= 0; i -= 1) {
        if (iswspace(output.at(i))) {
            output.pop_back();
        } else { // Only the trailing spaces
            break;
        }
    }
    
    return output;
}

// MARK: - Rules

// MARK: Dependencies

DependencyGraph* buildDependencyGraph(DatalogProgram *program) {
    // Build the dependency graph
    DependencyGraph* graph = new DependencyGraph();
    
    // Add nodes to the graph for each rule
    for (auto ruleA : program->getRules()) {
        if (ruleA == nullptr) { continue; }
        Predicate* headA = ruleA->getHeadPredicate();
        if (headA == nullptr) { continue; }
        graph->addDependency(ruleA, nullptr);
        
        // Add edges for each dependency
        for (auto ruleB : program->getRules()) {
            if (ruleB == nullptr) { continue; }
            
            for (auto predicate : ruleA->getPredicates()) {
                if (predicate == nullptr) { continue; }
                
                // Rule A depends on rule B if any of the predicate names in the
                // body of rule A is the same as the predicate name of the head of rule B
                Predicate* headB = ruleB->getHeadPredicate();
                if (predicate->getIdentifier() == headB->getIdentifier()) {
                    graph->addDependency(ruleA, ruleB);
                }
            }
        }
    }
    
    return graph;
}

void invert(DependencyGraph& graph) {
    // Build the reverse dependency graph.
    graph = graph.inverted();
}

void stronglyConnectedComponentsFromGraphReference(const DependencyGraph* graph,
                                                   vector<DependencyGraph>& result) {
    // Find the strongly-connected components (SCCs).
    DependencyGraph reversed = graph->inverted();
    vector<pair<int, DependencyGraph::Node>> ordering = reversed.postOrdering();
    
    if (ordering.empty()) { return; }
    
    // Find SCCs:
    // Run DFS on the original dependency graph starting from the node with the largest post-order number.
    // Any node visited during the DFS is part of the SCC.
    set<int> visited = set<int>();
    stack<int> stack = std::stack<int>();
    
    for (int idx = static_cast<int>(ordering.size()) - 1; idx >= 0; idx -= 1) {
        DependencyGraph scc = DependencyGraph();
        int idWithHighestPONum = ordering.at(idx).first;
        
        if (visited.find(idWithHighestPONum) == visited.end()) { // If not yet visited...
            stack.push(idWithHighestPONum); // Push the p-o number.
        } else {
            continue;
        }
        
        while (!stack.empty()) {
            int currentNode = stack.top();
            
            bool alreadyVisited = !visited.insert(currentNode).second;
            if (alreadyVisited) {
                DependencyGraph::Node node = graph->getNodes().at(currentNode);
                scc.addVertex(node, currentNode);
                stack.pop();
                continue;
            }
            
            map<int, Rule*> adjacencies = graph->getNodes().at(currentNode).getAdjacencies();
            while (!adjacencies.empty()) {
                // Push adjacencies onto the stack in reverse-PO-number order
                int maxPostOrderNumber = -1;
                int nodeWithMaxPONum = -1;
                for (auto rulePair : adjacencies) {
                    int id = rulePair.first;
                    if (visited.find(id) == visited.end()) { // If not already visited...
                        maxPostOrderNumber =
                        std::max(maxPostOrderNumber, graph->getNodes().at(id).getPostOrderNumber());
                        nodeWithMaxPONum = id;
                    } else { // If already visited...
                        adjacencies.erase(id); // forget about it
                        break;
                    }
                }
                if (nodeWithMaxPONum >= 0) {
                    stack.push(nodeWithMaxPONum);
                    adjacencies.erase(nodeWithMaxPONum);
                }
            }
            
        }
        
        result.push_back(scc);
    }
}

vector<DependencyGraph> stronglyConnectedComponentsFromGraph(const DependencyGraph& graph) {
    vector<DependencyGraph> result = vector<DependencyGraph>();
    
    DependencyGraph* intermediate = new DependencyGraph(graph);
    stronglyConnectedComponentsFromGraphReference(intermediate, result);
    delete intermediate;
    
    return result;
}

string evaluateRule(Rule *rule,
                    Database *database,
                    bool &didAddToDatabase,
                    map<std::string, set<std::string>> &printedTuples) {
    std::ostringstream result = std::ostringstream();
    
    result << rule->toString();
    
    //  Evaluate the predicates on the right-hand side of the rule
    vector<Relation> intermediates = vector<Relation>();
    vector<string> tuplesToPrint = vector<string>();
    
    for (auto predicate : rule->getPredicates()) {
        Relation* relation = database->relationWithName(predicate->getIdentifier());
        if (relation == nullptr) {
            continue;
        }
        Relation intermediateRelation = Relation(*relation);
        result << evaluateQueryItem(intermediateRelation, database, predicate, false);
        intermediates.push_back(intermediateRelation);
    }
    
    if (intermediates.empty()) {
        return result.str();
    }
    
    //  Join the relations that result
    Relation ruleRelation = *intermediates.begin();
    if (intermediates.size() > 1) {
        for (auto relation : intermediates) {
            ruleRelation = ruleRelation.joinedWith(relation);
        }
    }
    
    //  Project the columns that appear in the head predicate
    Tuple newScheme = Tuple(rule->getHeadPredicate()->getItems());
    ruleRelation.project(newScheme);
    ruleRelation.setName(rule->getHeadPredicate()->getIdentifier());
    Relation* headRelation = database->relationWithName(rule->getHeadPredicate()->getIdentifier());
    
    //  Rename the relation to make it union-compatible
    for (unsigned int i = 0; i < headRelation->getScheme().size(); i += 1) {
        string oldCol = ruleRelation.getScheme().at(i);
        string newCol = headRelation->getScheme().at(i);
        ruleRelation.rename(oldCol, newCol);
    }
    
    for (auto t : headRelation->getContents()) {
        string key = ruleRelation.getName();
        string output = headRelation->stringForTuple(t);
        printedTuples[key].insert(output);
    }
    
    //  Union with the relation in the database
    Relation oldHead = *headRelation;
    ruleRelation = headRelation->unionWith(ruleRelation);
    if (ruleRelation != oldHead) {
        didAddToDatabase = true;
    }
    
    if (database->addRelation(new Relation(ruleRelation))) {
        didAddToDatabase = true;
        
        for (Tuple t : ruleRelation.getContents()) {
            string key = ruleRelation.getName();
            string output = ruleRelation.stringForTuple(t);
            if (printedTuples.find(key) == printedTuples.end() ||
                printedTuples[key].find(output) == printedTuples[key].end()) {
                // Only print if we've not yet printed this tuple for this relation.
                tuplesToPrint.push_back(output);
                // Add output to a vector of tuples printed for ruleRelation.name
                printedTuples[key].insert(output);
            }
        }
    }
    
    result << std::endl;
    for (auto val : tuplesToPrint) {
        result << "  " << val << std::endl;
    }
    
    return result.str();
}

// Evaluate the rules in each component.
//string evaluateRulesInSubgraph(const DependencyGraph& dependencyGraph,
string evaluateRulesInSubgraph(const set<pair<int, Rule*>>& subgraph,
                               const DependencyGraph* depGraph,
                               Database *database,
                               int& passCount) {
    std::ostringstream result = std::ostringstream();
    map<string, set<string>> printedTuples = map<string, set<string>>();
    
    // If we've other nodes, we'll need to run a fixed-point algorithm.
    bool isRecursiveDependent = true;
    if (subgraph.size() == 1) {
        auto nodePair = *subgraph.begin();
        auto adjacencies = depGraph->getNodes().at(nodePair.first).getAdjacencies();
        // If nodePair is adjacent to itself (according to original graph) then we need to recurse.
        isRecursiveDependent = adjacencies.find(nodePair.first) != adjacencies.end();
    }
    
    // Evaluate our rules
    bool didAddToDatabase = true;
    
    while (didAddToDatabase) { // Stop when we've not added any new nodes.
        didAddToDatabase = false;
        
        for (auto rulePair : subgraph) { // For each rule...
            Rule* rule = rulePair.second;
            result << evaluateRule(rule, database, didAddToDatabase, printedTuples);
        }
        
        passCount += 1;
        if (!isRecursiveDependent) { break; } // Run once if we're not recursive.
    }
    
    return result.str();
}


// MARK: - Evaluate

string evaluateRules(Database *database, DatalogProgram *program, bool optimizeDependencies) {
    std::ostringstream str = std::ostringstream();

    DependencyGraph* dependencies = buildDependencyGraph(program);
    vector<DependencyGraph> components;
    
    if (optimizeDependencies) {
        str << "Dependency Graph" << std::endl;
        str << dependencies->toString() << std::endl;
        stronglyConnectedComponentsFromGraphReference(dependencies, components);
        
    } else {
        components = { *dependencies };
    }
    
    str << "Rule Evaluation" << std::endl;
    for (auto subgraph : components) {
        if (optimizeDependencies) {
            str << "SCC: " << subgraph.verticesByIDToString() << std::endl;
        }
        
        int passCount = 0;
        
        if (optimizeDependencies) {
            if (!subgraph.getNodes().empty()) {
                // Represent the subgraph as a set
                set<pair<int, Rule*>> subgraphSet = set<pair<int, Rule*>>();
                for (auto nodePair : subgraph.getNodes()) {
                    subgraphSet.insert(std::make_pair(nodePair.first, nodePair.second.getPrimaryRule()));
                }
                
                str << evaluateRulesInSubgraph(subgraphSet, dependencies, database, passCount);
            }
        } else {
            bool didAddToDatabase = true;
            map<string, set<string>> printedTuples = map<string, set<string>>();
            while (didAddToDatabase) {
                didAddToDatabase = false;
                for (auto node : subgraph.getNodes()) {
                    Rule* rule = node.second.getPrimaryRule();
                    str << evaluateRule(rule, database, didAddToDatabase, printedTuples);
                }
                passCount += 1;
            }
        }
        
        if (optimizeDependencies) {
            str << passCount << " passes: " << subgraph.verticesByIDToString() << std::endl;
        } else {
            str << std::endl << "Schemes populated after " << passCount
                << " passes through the Rules." << std::endl << std::endl;
        }
        
        passCount = 0;
    }
    
    if (optimizeDependencies) {
        str << std::endl;
    }
    
    delete dependencies;
    
    return str.str();
}
