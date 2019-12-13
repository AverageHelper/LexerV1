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
    if (headPredicate != nullptr) {
        headPredicate->release();
        if (!headPredicate->isOwned()) {
            delete headPredicate;
        }
        headPredicate = nullptr;
    }
    
    for (Predicate* pred : predicates) {
        if (pred == nullptr) { continue; }
        pred->release();
        if (!pred->isOwned()) {
            delete pred;
        }
    }
    predicates.clear();
}

void Rule::setHeadPredicate(Predicate* predicate) {
    this->headPredicate = predicate;
    predicate->retain();
}

Predicate* Rule::getHeadPredicate() const {
    return headPredicate;
}

int Rule::addPredicate(Predicate* predicate) {
    predicates.push_back(predicate);
    predicate->retain();
    return static_cast<int>(predicates.size());
}

std::vector<Predicate*> Rule::getPredicates() const {
    return predicates;
}

void Rule::setPredicates(std::vector<Predicate*> predicates) {
    for (auto pred : this->predicates) {
        pred->release();
    }
    this->predicates = predicates;
    for (auto pred : predicates) {
        pred->retain();
    }
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

bool Rule::operator ==(const Rule &other) const {
    return (this->headPredicate == other.headPredicate &&
            ((this->headPredicate == nullptr && other.headPredicate == nullptr) ||
            (this->headPredicate->getIdentifier() == other.headPredicate->getIdentifier() &&
            this->headPredicate->getType() == other.headPredicate->getType() &&
            this->headPredicate->getItems() == other.headPredicate->getItems())) &&
            this->predicates == other.predicates);
}

bool Rule::operator !=(const Rule &other) const {
    return !(operator==(other));
}
