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
    this->referenceCount = 0;
}

Predicate::~Predicate() {
    if (this->isOwned()) {
        std::cout << "--- Deallocated an owned Predicate object ---" << std::endl;
    }
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

// MARK: Memory Management

bool Predicate::isOwned() const {
    return referenceCount != 0;
}

void Predicate::retain() {
    referenceCount += 1;
}

void Predicate::release() {
    referenceCount -= 1;
    if (referenceCount < 0) {
        std::cout << "--- WARNING: A Predicate's referenceCount descended below 0 ---" << std::endl;
    }
}
