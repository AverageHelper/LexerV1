//
//  DatalogCheck.h
//  LexerV1
//
//  Created by James Robinson on 9/27/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef DatalogCheck_h
#define DatalogCheck_h

#include <iostream>
#include <sstream>
#include <exception>
#include <vector>
#include "Token.h"

class DatalogCheck {
public:
    bool debugMode = false;
    bool checkGrammar(const std::vector<Token *> &tokens);
    
private:
    /// Returns @c true if the token's type matches one of the given @c expectedTypes. Throws an exception otherwise.
    bool checkType(const Token* token, const std::vector<TokenType> expectedTypes);
    
    /// Returns @c true if the token's type matches the given @c expectedType. Throws an exception otherwise.
    bool checkType(const Token* token, const TokenType expectedType);
    
    /// Returns @c true if the token's type matches the given @c expectedType. @c false otherwise.
    bool peekType(const Token* token, const TokenType expectedType);
    
    bool datalogProgram(const std::vector<Token *> &tokens, int &index);
    
    bool schemeList(const std::vector<Token *> &tokens, int &index);
    bool factList(const std::vector<Token *> &tokens, int &index);
    bool ruleList(const std::vector<Token *> &tokens, int &index);
    bool queryList(const std::vector<Token *> &tokens, int &index);
    
    bool scheme(const std::vector<Token *> &tokens, int &index);
    bool fact(const std::vector<Token *> &tokens, int &index);
    bool rule(const std::vector<Token *> &tokens, int &index);
    bool query(const std::vector<Token *> &tokens, int &index);
    
    bool headPredicate(const std::vector<Token *> &tokens, int &index);
    bool predicate(const std::vector<Token *> &tokens, int &index);
    
    bool predicateList(const std::vector<Token *> &tokens, int &index);
    bool parameterList(const std::vector<Token *> &tokens, int &index);
    bool stringList(const std::vector<Token *> &tokens, int &index);
    bool idList(const std::vector<Token *> &tokens, int &index);
    
    bool parameter(const std::vector<Token *> &tokens, int &index);
    bool expression(const std::vector<Token *> &tokens, int &index);
    bool op(const std::vector<Token *> &tokens, int &index);
};

#endif /* DatalogCheck_h */
