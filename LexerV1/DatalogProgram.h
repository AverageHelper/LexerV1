//
//  DatalogProgram.h
//  LexerV1
//
//  Created by James Robinson on 9/30/19.
//

#ifndef DatalogProgram_h
#define DatalogProgram_h

#include "Production.h"
#include "Predicate.h"
#include "Rule.h"

class DatalogProgram: public Production {
private:
    std::string identifier;
    std::vector<Predicate*> schemes;
    std::vector<Predicate*> facts;
    std::vector<Rule*>      rules;
    std::vector<Predicate*> queries;
    
public:
    DatalogProgram(std::string identifier = "");
    ~DatalogProgram();
    
    void setIdentifier(std::string identifier);
    int addScheme(Predicate* scheme);
    int addFact(Predicate* fact);
    int addRule(Rule* rule);
    int addQuery(Predicate* query);
    void setSchemes(std::vector<Predicate*>& schemes);
    void setFacts(std::vector<Predicate*>& facts);
    void setRules(std::vector<Rule*>& rules);
    void setQueries(std::vector<Predicate*>& queries);
    
    std::string getIdentifier();
    std::string toString() override;
    const std::vector<std::string> getDomain();
    
    const std::vector<Predicate*> getSchemes();
    const std::vector<Predicate*> getFacts();
    const std::vector<Rule*>      getRules();
    const std::vector<Predicate*> getQueries();
};

#endif /* DatalogProgram_h */
