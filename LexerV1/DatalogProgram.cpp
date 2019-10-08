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
    for (unsigned int i = 0; i < schemes.size(); i += 1) {
        delete schemes.at(i);
    }
    schemes.clear();
    
    for (unsigned int i = 0; i < facts.size(); i += 1) {
        delete facts.at(i);
    }
    facts.clear();
    
    for (unsigned int i = 0; i < rules.size(); i += 1) {
        delete rules.at(i);
    }
    rules.clear();
    
    for (unsigned int i = 0; i < queries.size(); i += 1) {
        delete queries.at(i);
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
    return static_cast<int>(schemes.size());
}

int DatalogProgram::addFact(Predicate* fact) {
    facts.push_back(fact);
    return static_cast<int>(facts.size());
}

int DatalogProgram::addRule(Rule* rule) {
    rules.push_back(rule);
    return static_cast<int>(rules.size());
}

int DatalogProgram::addQuery(Predicate* query) {
    queries.push_back(query);
    return static_cast<int>(queries.size());
}

void DatalogProgram::setSchemes(std::vector<Predicate *> &schemes) {
    this->schemes = schemes;
}

void DatalogProgram::setFacts(std::vector<Predicate *> &facts) {
    this->facts = facts;
}

void DatalogProgram::setRules(std::vector<Rule *> &rules) {
    this->rules = rules;
}

void DatalogProgram::setQueries(std::vector<Predicate *> &queries) {
    this->queries = queries;
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
