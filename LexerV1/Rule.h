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
    
    int addPredicate(Predicate* predicate);
    std::vector<Predicate*> getPredicates();
    void setPredicates(std::vector<Predicate*> predicates);
    
    std::string toString() override;
};

#endif /* Rule_h */
