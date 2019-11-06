//
//  Relation.cpp
//  LexerV1
//
//  Created by James Robinson on 11/4/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include "Relation.h"

Relation::Relation(const std::string name, Tuple scheme) {
    this->name = name;
    this->contents = std::set<Tuple>();
    this->scheme = scheme;
}

Relation::~Relation() {
    contents.clear();
}

const std::string Relation::getName() {
    return this->name;
}

size_t Relation::getColumnCount() {
    return getScheme().size();
}

void Relation::setScheme(Tuple scheme) {
    this->scheme = scheme;
}

Tuple Relation::getScheme() {
    return scheme;
}

bool Relation::addTuple(Tuple element) {
    if (element.size() != getColumnCount()) {
        return false;
    }
    
    this->contents.insert(element);
    return true;
}

const std::set<Tuple> Relation::getContents() {
    return this->contents;
}

bool vectorContainsString(std::string query, std::vector<std::string> domain) {
    for (unsigned int i = 0; i < domain.size(); i += 1) {
        if (domain.at(i) == query) {
            return true;
        }
    }
    
    return false;
}

Relation* Relation::rename(std::string oldName, std::string newName) {
    bool replacedItem = false;
    Tuple newScheme = getScheme();
    
    for (unsigned int i = 0; i < newScheme.size(); i += 1) {
        if (newScheme.at(i) == oldName) {
            if (replacedItem) { // Duplicate now? Return nil.
                return nullptr;
            }
            newScheme.at(i) = newName; // Replace oldName with newName
            replacedItem = true;
        }
    }
    
    if (replacedItem) {
        // Found and replaced name.
        return new Relation(name, newScheme);
        
    } else {
        // Didn't find item to rename.
        return nullptr;
    }
}

Relation* Relation::select(Tuple parameters) {
    std::vector<Tuple> matches = {};
    for (unsigned int i = 0; i < parameters.size(); i += 1) {
        // Iterate over the parameters of the query
        
        if (parameters.at(i).at(0) == '\'') {
            // A constant if we're given a string
            // Select the tuples from the Relation that have the same value as the constant in the same position as the constant.
            
        } else {
            // A variable
            // If the parameter is a variable and the same variable name appears later in the query, select the tuples from the Relation that have the same value in both positions where the variable name appears.
        }
    }
    return nullptr;
}

Relation* Relation::project(Tuple scheme) {
    // Keep only the columns from the Relation that correspond to the positions of the variables in the query.
    // Make sure that each variable name appears only once in the resulting relation. If the same name appears more than once, keep the first column where the name appears and remove any later columns where the same name appears. (This makes a difference when there are other columns in between the ones with the same name.)
    return nullptr;
}
