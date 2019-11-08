//
//  Relation.cpp
//  LexerV1
//
//  Created by James Robinson on 11/4/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include "Relation.h"

Relation::Relation(const Relation &other) {
    this->name = other.name;
    this->contents = other.contents;
    this->scheme = other.scheme;
}

Relation::Relation(const std::string name, Tuple scheme) {
    this->name = name;
    this->contents = std::set<Tuple>();
    this->scheme = scheme;
}

Relation::~Relation() {
    contents.clear();
}

std::string Relation::getName() const {
    return this->name;
}

size_t Relation::getColumnCount() const {
    return getScheme().size();
}

Tuple Relation::getScheme() const {
    return scheme;
}

bool Relation::addTuple(Tuple element) {
    if (element.size() != getColumnCount()) {
        return false;
    }
    
    this->contents.insert(element);
    return true;
}

std::set<Tuple> Relation::getContents() const {
    return this->contents;
}

std::vector<Tuple> Relation::listContents() const {
    std::vector<Tuple> result = {};
    
    for (auto t : getContents()) {
        result.push_back(t);
    }
    
    return result;
}

Relation* Relation::rename(std::string oldCol, std::string newCol) const {
    Tuple newScheme = getScheme();
    
    // Evaluate for each column in scheme.
    for (unsigned int i = 0; i < newScheme.size(); i += 1) {
        if (newScheme.at(i) == oldCol && !vectorContainsValue(newScheme, newCol)) {
            // Did we land at oldCol? Have we not replaced it yet?
            newScheme.at(i) = newCol; // Replace oldName with newName
        }
    }
    
    return new Relation(name, newScheme);
}

Relation* Relation::select(std::vector<std::pair<size_t, std::string>> queries) const {
    Relation* result = new Relation(getName(), getScheme());
    
    // Evaluate each tuple
    for (auto t : getContents()) {
        bool isMatch = false;
        
        for (auto query : queries) {
            size_t col = query.first;
            std::string val = query.second;
            
            if (col > result->getColumnCount()) {
                continue; // Too big? Next query.
            }
            if (t.at(col) != val) {
                break; // Column doesn't match an expected value? Next tuple.
            }
            
            isMatch = true;
        }
        
        if (isMatch) {
            result->addTuple(t);
        }
    }
    
    return result;
}

Relation* Relation::select(std::vector<std::pair<size_t, size_t>> queries) const {
    Relation* result = new Relation(getName(), getScheme());
    
    // Evaluate each equivalence
    for (unsigned int queryIdx = 0; queryIdx < queries.size(); queryIdx += 1) {
        std::pair<size_t, size_t> query = queries.at(queryIdx);
        size_t col1 = query.first;
        size_t col2 = query.second;
        
        if (col1 > result->getColumnCount() || col2 > result->getColumnCount()) {
            continue; // Too big? Move along.
        }
        
        // Evaluate each tuple
        for (auto t : getContents()) {
            if (t.at(col1) == t.at(col2)) {
                result->addTuple(t);
            }
        }
    }
    
    return result;
}

bool Relation::vectorContainsValue(const std::vector<std::string> &domain,
                                   const std::string &query) const {
    for (auto val : domain) {
        if (val == query) {
            return true;
        }
    }
    
    return false;
}

void Relation::stripExtraColsFromScheme(Tuple &otherScheme) const {
    // Evaluate each column in given scheme.
    Tuple result = {};
    
    if (otherScheme.empty()) {
        return; // Empty scheme? That's ok.
    }
    
    Tuple dirtyScheme = otherScheme;
    otherScheme.clear();
    
    // Strip duplicates from otherScheme
    for (auto col : dirtyScheme) {
        if (!vectorContainsValue(otherScheme, col)) {
            otherScheme.push_back(col);
        }
    }
    
    // Pull only those from otherScheme which are in current scheme
    for (auto col : otherScheme) {
        if (vectorContainsValue(getScheme(), col)) {
            result.push_back(col);
        }
    }
    
    otherScheme = result;
}

int Relation::indexForColumnInScheme(std::string col) {
    return indexForColumnInTuple(col, getScheme());
}

int Relation::indexForColumnInTuple(std::string col, const Tuple &domain) {
    for (unsigned int i = 0; i < domain.size(); i += 1) {
        if (domain.at(i) == col) {
            return i;
        }
    }
    
    return -1;
}

void Relation::swapColumns(size_t oldCol, size_t newCol) {
    if (newCol >= getColumnCount()) {
        newCol = getColumnCount() - 1; // Too large? Use the end instead.
    }
    
    // Reorder scheme
    std::string val = scheme.at(oldCol);
    scheme.at(oldCol) = scheme.at(newCol);
    scheme.at(newCol) = val;
    
    // Reorder each tuple
    std::set<Tuple> reordered = std::set<Tuple>();
    for (auto t : contents) {
        std::string val = t.at(oldCol);
        t.at(oldCol) = t.at(newCol);
        t.at(newCol) = val;
        reordered.insert(t);
    }
    contents = reordered;
}

void Relation::keepOnlyColumnsUntil(size_t col) {
    if (col >= getColumnCount()) {
        return;
    }
    
    // Strip from scheme
    scheme.erase(scheme.begin() + col, scheme.end());
    
    std::set<Tuple> stripped = std::set<Tuple>();
    for (auto t : contents) {
        
        // Strip from each column
        t.erase(t.begin() + col, t.end());
        stripped.insert(t);
        
    }
    
    // If we only have a single empty row, remove it
    if (stripped.size() == 1 && (*stripped.begin()).empty()) {
        stripped.clear();
    }
    
    contents = stripped;
}

Relation* Relation::project(Tuple scheme) const {
    Tuple current = getScheme();
    Tuple newScheme = scheme;
    
    stripExtraColsFromScheme(newScheme); // This removes columns that don't exist.
    
    Relation* result = new Relation(*this);
    
    // For each column in scheme, find where it was in our old scheme, then apply.
    for (unsigned int newIndex = 0; newIndex < newScheme.size(); newIndex += 1) {
        size_t oldIndex = result->indexForColumnInScheme(newScheme.at(newIndex));
        result->swapColumns(oldIndex, newIndex);
    }
    
    result->keepOnlyColumnsUntil(newScheme.size());
    
    return result;
}

bool Relation::operator==(const Relation &other) {
    return (getName() == other.getName() &&
            getScheme() == other.getScheme() &&
            getContents() == other.getContents());
}
