//
//  Predicate.cpp
//  LexerV1
//
//  Created by James Robinson on 9/30/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include "Predicate.h"

Predicate::Predicate(TokenType type, std::string identifier) {
    this->type = type;
    this->identifier = identifier;
    this->contents = {};
}

Predicate::~Predicate() {
    contents.clear();
}

TokenType Predicate::getType() {
    return type;
}

void Predicate::setType(TokenType type) {
    this->type = type;
}

std::string Predicate::getIdentifier() {
    return identifier;
}

std::vector<std::string> Predicate::getItems() {
    return contents;
}

void Predicate::setItems(std::vector<std::string>& items) {
    this->contents = items;
}

void Predicate::copyItemsIn(std::vector<std::string> items) {
    this->contents = items;
}

int Predicate::addItem(std::string item) {
    contents.push_back(item);
    return static_cast<int>(contents.size());
}

std::string Predicate::toString() {
    std::ostringstream result = std::ostringstream();
    
    result << identifier;
    result << "(";
    
    for (unsigned int i = 0; i < contents.size(); i += 1) {
        result << contents.at(i);
        if (i < contents.size() - 1) {
            result << ",";
        }
    }
    
    result << ")";
    
    if (type == QUERIES) {
        result << "?";
    } else if (type == FACTS) {
        result << ".";
    }
    
    return result.str();
}
