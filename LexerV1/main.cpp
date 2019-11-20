//
//  main.cpp
//  LexerV1
//
//  Created by James Robinson on 9/9/19.
//

#include <iostream>
#include <fstream>
#include <map>
#include "Lexer.h"
#include "Recognizers.h"
#include "DatalogCheck.h"
#include "Database.h"

int indexOfValueInVector(std::string query, const std::vector<std::string> &domain);

int main(int argc, char* argv[]) {
    std::string filename = "";
    bool uiLogging = (argc <= 1);
    
    if (uiLogging) {
        // If user didn't send anything in command line, ask for input.
        std::cout << "=== Welcome to RoLexer (V1) ===" << std::endl;
        std::cout << "Enter the name of a file to tokenize (include extension): ";
        std::cin >> filename;
        
    } else {
        // Silently take input if user passed a filename.
        filename = argv[1];
    }
    
    std::ifstream iFS = std::ifstream();
    
    // Open user file
    iFS.open(filename);
    while (!iFS.is_open()) {
        if (uiLogging) {
            // Try again if user's filename didn't work.
            std::cout << "The file '" << filename
                << "' could not be opened. Enter another filename: ";
            std::cin >> filename;
            iFS.open(filename);
            
        } else {
            // Fail if user's filename didn't work.
            std::cout << "The file '" << filename << "' could not be opened." << std::endl;
            return 0;
        }
    }
    
    // Parse tokens
    std::vector<Token*> tokens = collectedTokensFromFile(iFS);
    iFS.close();
    
//    printTokens(tokens);
    
    DatalogCheck checker = DatalogCheck();
    DatalogProgram* program = checker.checkGrammar(tokens);
    
    if (program == nullptr) {
        return 0;
    }
    
//    std::cout << checker.getResultMsg() << std::endl;
    
    Database* database = new Database();
    
    // Evaluate Schemes
    for (unsigned int schemeIdx = 0; schemeIdx < program->getSchemes().size(); schemeIdx += 1) {
        Predicate* scheme = program->getSchemes().at(schemeIdx);
        std::vector<std::string> titles = scheme->getItems();
        
        Relation* relation = new Relation(scheme->getIdentifier(), scheme->getItems());
        database->addRelation(relation);
    }
    
    // Evaluate Facts
    for (unsigned int factIdx = 0; factIdx < program->getFacts().size(); factIdx += 1) {
        Predicate* fact = program->getFacts().at(factIdx);
        std::vector<std::string> items = fact->getItems();
        
        Relation* relation = database->relationWithName(fact->getIdentifier());
        
        if (relation != nullptr) {
            Tuple tuple = Tuple(items);
            relation->addTuple(tuple);
        }
    }
    
    // Evaluate Rules
    
    
    // Evaluate Queries
    for (unsigned int queryIdx = 0; queryIdx < program->getQueries().size(); queryIdx += 1) {
        Predicate* query = program->getQueries().at(queryIdx);
        std::cout << query->toString() << " ";
        
        Relation* relation = database->relationWithName(query->getIdentifier());
        if (relation == nullptr) {
            std::cout << "No" << std::endl;
            continue;
        }
        
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
                queryCols.insert(std::make_pair(relation->getScheme().at(col), val));
                oldCols.push_back(relation->getScheme().at(col));
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
        Relation selected = *relation;
        if (!matchColumns.empty()) {
            selected = selected.select({ matchColumns });
        }
        if (!matchValues.empty()) {
            selected = selected.select(matchValues);
        }
        
        if (selected.getContents().empty()) {
            std::cout << "No" << std::endl;
        } else {
            std::cout << "Yes(" << selected.getContents().size() << ")" << std::endl;
        }
        
        // Project only the columns we want.
        Relation projected = selected.project(oldCols);
        
        // Rename the columns to the names of the variables found in the query
        Relation renamed = projected;
        for (auto pair : queryCols) {
            std::string oldCol = pair.first;
            std::string newCol = pair.second;
            renamed = renamed.rename(oldCol, newCol);
        }
        
        // If there are variables in the query, output the tuples from the resulting relation.
        for (Tuple t : renamed.getContents()) {
            std::cout << "  " << renamed.stringForTuple(t) << std::endl;
        }
    }
    
    // Free our memory.
    if (program != nullptr) {
        delete program;
    }
    delete database;
    releaseTokens(tokens);
    
    return 0;
}

int indexOfValueInVector(std::string query, const std::vector<std::string> &domain) {
    for (unsigned int idx = 0; idx < domain.size(); idx += 1) {
        std::string val = domain.at(idx);
        if (val == query) {
            return idx;
        }
    }
    
    return -1;
}
