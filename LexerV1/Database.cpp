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

bool Database::addRelation(Relation* relation) {
    for (size_t i = 0; i < this->relations.size(); i += 1) {
        Relation* extantRelation = this->relations.at(i);
        
        if (extantRelation->getName() == relation->getName()) {
            // Relation with same name? If it's new, replace what we have.
            if (*extantRelation != *relation) {
                delete extantRelation;
                this->relations.erase(this->relations.begin() + i);
                break;
            } else {
                // Identical? Do nothing.
                return false;
            }
        }
    }
    
    this->relations.push_back(relation);
    return true;
}

Relation* Database::relationWithName(std::string name) {
    for (unsigned int i = 0; i < relations.size(); i += 1) {
        if (relations.at(i)->getName() == name) {
            return relations.at(i);
        }
    }
    
    return nullptr;
}
