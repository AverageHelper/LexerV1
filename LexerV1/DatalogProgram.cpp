//
//  DatalogProgram.cpp
//  LexerV1
//
//  Created by James Robinson on 9/30/19.
//

#include "DatalogProgram.h"
#include <set>

DatalogProgram::DatalogProgram(std::string identifier) {
    this->identifier = identifier;
    this->schemes = {};
    this->facts = {};
    this->rules = {};
    this->queries = {};
}

DatalogProgram::~DatalogProgram() {
    for (auto scheme : schemes) {
        if (scheme == nullptr) { continue; }
        scheme->release();
        if (!scheme->isOwned()) {
            delete scheme;
        }
    }
    schemes.clear();
    
    for (auto fact : facts) {
        if (fact == nullptr) { continue; }
        fact->release();
        if (!fact->isOwned()) {
            delete fact;
        }
    }
    facts.clear();
    
    for (auto rule : rules) {
        if (rule == nullptr) { continue; }
        rule->release();
        if (!rule->isOwned()) {
            delete rule;
        }
    }
    rules.clear();
    
    for (auto query : queries) {
        if (query == nullptr) { continue; }
        query->release();
        if (!query->isOwned()) {
            delete query;
        }
    }
    queries.clear();
}

//bool vectorContainsString(const std::vector<std::string> subject, std::string query) {
//    for (unsigned int i = 0; i < subject.size(); i += 1) {
//        if (subject.at(i) == query) {
//            return true;
//        }
//    }
//
//    return false;
//}

const std::vector<std::string> DatalogProgram::getDomain() {
    std::set<std::string> result = {};
    
    // Get all unique strings in Facts
    for (unsigned int fct = 0; fct < facts.size(); fct += 1) {
        Predicate* fact = facts.at(fct);
        
        for (unsigned int itm = 0; itm < fact->getItems().size(); itm += 1) {
//            if (!vectorContainsString(result, fact->getItems().at(itm))) {
                result.insert(fact->getItems().at(itm));
//            }
        }
    }
    
    return std::vector<std::string>(result.begin(), result.end());
}

void DatalogProgram::setIdentifier(std::string identifier) {
    this->identifier = identifier;
}

std::string DatalogProgram::getIdentifier() {
    return identifier;
}


int DatalogProgram::addScheme(Predicate* scheme) {
    schemes.push_back(scheme);
    scheme->retain();
    return static_cast<int>(schemes.size());
}

int DatalogProgram::addFact(Predicate* fact) {
    facts.push_back(fact);
    fact->retain();
    return static_cast<int>(facts.size());
}

int DatalogProgram::addRule(Rule* rule) {
    rules.push_back(rule);
    rule->retain();
    return static_cast<int>(rules.size());
}

int DatalogProgram::addQuery(Predicate* query) {
    queries.push_back(query);
    query->retain();
    return static_cast<int>(queries.size());
}

void DatalogProgram::setSchemes(std::vector<Predicate *> &schemes) {
    for (auto scheme : this->schemes) {
        scheme->release();
    }
    this->schemes = schemes;
    for (auto scheme : schemes) {
        scheme->retain();
    }
}

void DatalogProgram::setFacts(std::vector<Predicate *> &facts) {
    for (auto fact : this->facts) {
        fact->release();
    }
    this->facts = facts;
    for (auto fact : facts) {
        fact->retain();
    }
}

void DatalogProgram::setRules(std::vector<Rule *> &rules) {
    for (auto rule : this->rules) {
        rule->release();
    }
    this->rules = rules;
    for (auto rule : rules) {
        rule->retain();
    }
}

void DatalogProgram::setQueries(std::vector<Predicate *> &queries) {
    for (auto query : this->queries) {
        query->release();
    }
    this->queries = queries;
    for (auto query : queries) {
        query->retain();
    }
}

const std::vector<Predicate*> DatalogProgram::getSchemes() {
    return this->schemes;
}

const std::vector<Predicate*> DatalogProgram::getFacts() {
    return this->facts;
}

const std::vector<Rule*> DatalogProgram::getRules() {
    return this->rules;
}

const std::vector<Predicate*> DatalogProgram::getQueries() {
    return this->queries;
}


std::string DatalogProgram::toString() {
    std::ostringstream result = std::ostringstream();
    
    result << "Schemes(" << schemes.size() << "):" << std::endl;
    for (unsigned int i = 0; i < schemes.size(); i += 1) {
        result << "  " << schemes.at(i)->toString() << std::endl;
    }
    
    result << "Facts(" << facts.size() << "):" << std::endl;
    for (unsigned int i = 0; i < facts.size(); i += 1) {
        result << "  " << facts.at(i)->toString() << std::endl;
    }
    
    result << "Rules(" << rules.size() << "):" << std::endl;
    for (unsigned int i = 0; i < rules.size(); i += 1) {
        result << "  " << rules.at(i)->toString() << std::endl;
    }
    
    result << "Queries(" << queries.size() << "):" << std::endl;
    for (unsigned int i = 0; i < queries.size(); i += 1) {
        result << "  " << queries.at(i)->toString() << std::endl;
    }
    
    std::vector<std::string> domain = getDomain();
    result << "Domain(" << domain.size() << "):";
    for (unsigned int i = 0; i < domain.size(); i += 1) {
        result << std::endl << "  " << domain.at(i);
    }
    
    return result.str();
}
