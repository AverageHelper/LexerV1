//
//  Rule.h
//  LexerV1
//
//  Created by James Robinson on 9/30/19.
//

#ifndef Rule_h
#define Rule_h

#include "Production.h"
#include "Predicate.h"

class Rule: public Production {
private:
    Predicate* headPredicate;
    std::vector<Predicate*> predicates;
    
public:
    Rule();
    ~Rule();
    
    void setHeadPredicate(Predicate* predicate);
    Predicate* getHeadPredicate() const;
    
    int addPredicate(Predicate* predicate);
    std::vector<Predicate*> getPredicates() const;
    void setPredicates(std::vector<Predicate*> predicates);
    
    std::string toString() override;
    
    bool operator ==(const Rule &other);
};

#endif /* Rule_h */
