//
//  Database.cpp
//  LexerV1
//
//  Created by James Robinson on 11/4/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include "Database.h"

Database::Database() {
    this->relations = {};
}

Database::~Database() {
    for (unsigned int i = 0; i < relations.size(); i += 1) {
        delete relations.at(i);
    }
    
    relations.clear();
}

const std::vector<Relation*> Database::getRelations() {
    return this->relations;
}

void Database::addRelation(Relation* relation) {
    this->relations.push_back(relation);
}

Relation* Database::relationWithName(std::string name) {
    for (unsigned int i = 0; i < relations.size(); i += 1) {
        if (relations.at(i)->getName() == name) {
            return relations.at(i);
        }
    }
    
    return nullptr;
}
