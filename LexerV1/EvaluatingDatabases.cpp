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

DependencyGraph* buildDependencyGraph(Database *database, DatalogProgram *program) {
    // Build the dependency graph
    DependencyGraph* graph = new DependencyGraph();
    
    for (auto rule : program->getRules()) {
        Predicate* predicate = rule->getHeadPredicate();
        Relation* head = nullptr;
        if (predicate != nullptr) {
            head = database->relationWithName(predicate->getIdentifier());
            if (head == nullptr) { continue; }
            graph->addDependency(head, nullptr);
        }
        
        for (auto predicate : rule->getPredicates()) {
            Relation* tail = database->relationWithName(predicate->getIdentifier());
            if (tail == nullptr) { continue; }
            graph->addDependency(head, tail);
        }
        
    }
    
    return graph;
}

void invert() {
    // Build the reverse dependency graph.
}

void dfsForest() {
    // Run DFS-Forest on the reverse dependency graph.
}

void findSCCs() {
    // Find the strongly connected components (SCCs).
}

// Evaluate the rules in each component.
void evaluateRulesInComponent() {
    
}


// MARK: Evaluate

std::string evaluateRules(Database *database, DatalogProgram *program, bool optimizeDependencies) {
    std::ostringstream str = std::ostringstream();
    str << "Rule Evaluation" << std::endl;
    
    bool didAddToDatabase = true;
    int passCount = 0;
    
    std::map<std::string, std::set<std::string>> printedTuples
        = std::map<std::string, std::set<std::string>>();
    
    while (didAddToDatabase) {
        didAddToDatabase = false;
        
        for (auto rule : program->getRules()) {
            
            str << rule->toString();
            
            //  Evaluate the predicates on the right-hand side of the rule
            std::vector<Relation> intermediates = std::vector<Relation>();
            std::vector<std::string> tuplesToPrint = std::vector<std::string>();
            
            for (auto predicate : rule->getPredicates()) {
                Relation* relation = database->relationWithName(predicate->getIdentifier());
                if (relation == nullptr) {
                    continue;
                }
                Relation intermediateRelation = Relation(*relation);
                str << evaluateQueryItem(intermediateRelation, database, predicate, false);
                intermediates.push_back(intermediateRelation);
            }
            
            if (intermediates.empty()) {
                continue;
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
                std::string oldCol = ruleRelation.getScheme().at(i);
                std::string newCol = headRelation->getScheme().at(i);
                ruleRelation.rename(oldCol, newCol);
            }
            
            //  Union with the relation in the database
            for (auto t : headRelation->getContents()) {
                std::string key = ruleRelation.getName();
                std::string output = headRelation->stringForTuple(t);
                printedTuples[key].insert(output);
            }
            ruleRelation = headRelation->unionWith(ruleRelation);
            if (database->addRelation(new Relation(ruleRelation))) {
                didAddToDatabase = true; // True if we actually changed something.
                
                for (Tuple t : ruleRelation.getContents()) {
                    std::string key = ruleRelation.getName();
                    std::string output = ruleRelation.stringForTuple(t);
                    if (printedTuples.find(key) == printedTuples.end() ||
                        printedTuples[key].find(output) == printedTuples[key].end()) {
                        // Only print if we've not yet printed this tuple for this relation.
                        tuplesToPrint.push_back(output);
                        // Add output to a vector of tuples printed for ruleRelation.name
                        printedTuples[key].insert(output);
                    }
                }
            }
            
            str << std::endl;
            for (auto val : tuplesToPrint) {
                str << "  " << val << std::endl;
            }
        }
        
        passCount += 1;
    }
    
    str << std::endl << "Schemes populated after " << passCount
        << " passes through the Rules." << std::endl << std::endl;
    
    return str.str();
}
