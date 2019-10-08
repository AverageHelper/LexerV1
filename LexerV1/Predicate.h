//
//  Predicate.h
//  LexerV1
//
//  Created by James Robinson on 9/30/19.
//

#ifndef Predicate_h
#define Predicate_h

#include "Production.h"

class Predicate: public Production {
private:
    TokenType type;
    std::string identifier;
    std::vector<std::string> contents;
    
public:
    Predicate(TokenType type, std::string identifier);
    ~Predicate();
    
    int addItem(std::string item);
    void setItems(std::vector<std::string>& items);
    
    void setType(TokenType type);
    
    TokenType getType();
    std::string getIdentifier();
    std::vector<std::string> getItems();
    std::string toString() override;
};

#endif /* Predicate_h */
