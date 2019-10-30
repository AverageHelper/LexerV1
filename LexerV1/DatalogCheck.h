//
//  DatalogCheck.h
//  LexerV1
//
//  Created by James Robinson on 9/27/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef DatalogCheck_h
#define DatalogCheck_h

#include <sstream>
#include <exception>
#include <vector>
#include "Production.h"
#include "DatalogProgram.h"
#include "Rule.h"

class DatalogCheck {
public:
    DatalogProgram* checkGrammar(const std::vector<Token *> &tokens);
    std::string getResultMsg();
    
private:
    std::string resultMsg = "";
    std::string currentNonTerminal = "";
    
    /// Returns @c true if the token's type matches one of the given @c expectedTypes. Throws an exception otherwise.
    Token* checkType(Token* token, const std::vector<TokenType> expectedTypes);
    
    /// Returns @c true if the token's type matches the given @c expectedType. Throws an exception otherwise.
    Token* checkType(Token* token, const TokenType expectedType);
    
    /// Returns @c true if the token's type matches the given @c expectedType. @c false otherwise.
    bool peekType(const Token* token, const TokenType expectedType);
    
    DatalogProgram* datalogProgram(const std::vector<Token *> &tokens, int &index);
    
    std::vector<Predicate*> schemeList(std::vector<Predicate*> &schemeList, const std::vector<Token *> &tokens, int &index);
    std::vector<Predicate*> factList(std::vector<Predicate*> &factList, const std::vector<Token *> &tokens, int &index);
    std::vector<Rule*> ruleList(std::vector<Rule*> &ruleList, const std::vector<Token *> &tokens, int &index);
    std::vector<Predicate*> queryList(std::vector<Predicate*> &queryList, const std::vector<Token *> &tokens, int &index);
    
    Predicate* scheme(const std::vector<Token *> &tokens, int &index);
    Predicate* fact(const std::vector<Token *> &tokens, int &index);
    Rule* rule(const std::vector<Token *> &tokens, int &index);
    Predicate* query(const std::vector<Token *> &tokens, int &index);
    
    Predicate* headPredicate(const std::vector<Token *> &tokens, int &index);
    Predicate* predicate(const std::vector<Token *> &tokens, int &index);
    
    std::vector<Predicate*> predicateList(const std::vector<Predicate*> &foundPredicates, const std::vector<Token *> &tokens, int &index);
    std::vector<std::string> parameterList(const std::vector<std::string> &foundParams, const std::vector<Token *> &tokens, int &index);
    std::vector<std::string> stringList(const std::vector<std::string> &foundStrings, const std::vector<Token *> &tokens, int &index);
    std::vector<std::string> idList(const std::vector<std::string> &foundIDs, const std::vector<Token *> &tokens, int &index);
    
    std::string parameter(const std::vector<Token *> &tokens, int &index);
    std::string expression(const std::vector<Token *> &tokens, int &index);
    std::string op(const std::vector<Token *> &tokens, int &index);
};

#endif /* DatalogCheck_h */
