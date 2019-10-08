//
//  Rule.cpp
//  LexerV1
//
//  Created by James Robinson on 9/30/19.
//

#include "Rule.h"

Rule::Rule() {
    headPredicate = nullptr;
    predicates = {};
}

Rule::~Rule() {
    delete headPredicate;
    headPredicate = nullptr;
    
    for (unsigned int i = 0; i < predicates.size(); i += 1) {
        delete predicates.at(i);
    }
    predicates.clear();
}

void Rule::setHeadPredicate(Predicate* predicate) {
    this->headPredicate = predicate;
}

int Rule::addPredicate(Predicate* predicate) {
    predicates.push_back(predicate);
    return static_cast<int>(predicates.size());
}

std::vector<Predicate*> Rule::getPredicates() {
    return predicates;
}

void Rule::setPredicates(std::vector<Predicate*> predicates) {
    this->predicates = predicates;
}

std::string Rule::toString() {
    std::ostringstream result = std::ostringstream();
    
    result << headPredicate->toString();
    result << " :- ";
    
    for (unsigned int i = 0; i < predicates.size(); i += 1) {
        result << predicates.at(i)->toString();
        
        if (i < predicates.size() - 1) {
            result << ",";
        }
    }
    
    result << ".";
    
    return result.str();
}
