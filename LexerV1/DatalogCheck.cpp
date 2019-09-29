//
//  DatalogCheck.cpp
//  LexerV1
//
//  Created by James Robinson on 9/27/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include "DatalogCheck.h"

class WrongToken: public std::exception {
private:
    Token token;
    
public:
    WrongToken(Token token) {
        this->token = token;
    }
    
    Token getToken() const {
        return this->token;
    }
    
    virtual const char* what() const throw() {
        std::ostringstream stm = std::ostringstream();
        
        stm << "A token was found to not match the expected pattern: ";
        stm << getToken().toString();
        return stm.str().c_str();
    }
    
};

bool DatalogCheck::checkGrammar(const std::vector<Token *> &tokens) {
    int start = 0;
    
    try {
        return datalogProgram(tokens, start);
        
    } catch (WrongToken& e) {
        if (debugMode) {
            std::cout << "Failure!" << std::endl << "  " << std::endl;
            std::cout << e.getToken().toString() << std::endl;
        }
        return false;
    }
}

// MARK: - Check Token Types

bool DatalogCheck::checkType(const Token* token,
                             const std::vector<TokenType> expectedTypes) {
    for (unsigned int i = 0; i < expectedTypes.size(); i += 1) {
        if (expectedTypes.at(i) == token->getType()) {
            return true;
        }
    }
    
    throw WrongToken(*token);
    return false;
}

bool DatalogCheck::checkType(const Token *token,
                             const TokenType expectedType) {
    std::vector<TokenType> expected = { expectedType };
    return checkType(token, expected);
}

bool DatalogCheck::peekType(const Token* token,
                            const TokenType expectedType) {
    return token->getType() == expectedType;
}



// MARK: - datalogProgram

bool DatalogCheck::datalogProgram(const std::vector<Token *> &tokens,
                                  int &index) {
    /*
    datalogProgram    ->    SCHEMES COLON scheme schemeList
                            FACTS COLON factList
                            RULES COLON ruleList
                            QUERIES COLON query queryList
     */
    
    // Always add our expected stream position modifier to the given index pointer.
    if (checkType(tokens.at(index + 0), SCHEMES)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), COLON)) {
        index += 1;
    }
    
    if (schemeList(tokens, index)) {
        index += 1;
    }
    
    return true;
}

// MARK: - Lists

bool DatalogCheck::schemeList(const std::vector<Token *> &tokens,
                              int &index) {
    /*
     schemeList  ->    scheme schemeList | lambda
     */
    
    // Check FIRST(scheme)
    if (!peekType(tokens.at(index + 0), ID)) {
        return false;
    }
    
    bool result = scheme(tokens, index);
    schemeList(tokens, index);
    
    return result;
}

bool DatalogCheck::factList(const std::vector<Token *> &tokens,
                            int &index) {
    /*
     factList    ->    fact factList | lambda
     */
    
    // Check FIRST(fact)
    if (!peekType(tokens.at(index + 0), ID)) {
        return false;
    }
    
    bool result = fact(tokens, index);
    factList(tokens, index);
    
    return result;
}

bool DatalogCheck::ruleList(const std::vector<Token *> &tokens,
                            int &index) {
    /*
     ruleList    ->    rule ruleList | lambda
     */
    
    // Check FIRST(rule)
    if (!peekType(tokens.at(index + 0), ID)) {
        return false;
    }
    
    bool result = rule(tokens, index);
    ruleList(tokens, index);
    
    return result;
}

bool DatalogCheck::queryList(const std::vector<Token *> &tokens,
                             int &index) {
    /*
     queryList   ->    query queryList | lambda
     */
    
    // Check FIRST(query)
    if (!peekType(tokens.at(index + 0), ID)) {
        return false;
    }
    
    bool result = query(tokens, index);
    queryList(tokens, index);
    
    return result;
}

// MARK: - Items

bool DatalogCheck::scheme(const std::vector<Token *> &tokens,
                          int &index) {
    /*
     scheme      ->     ID LEFT_PAREN ID idList RIGHT_PAREN
     */
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
    }
    
    idList(tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    return true;
}

bool DatalogCheck::fact(const std::vector<Token *> &tokens,
                        int &index) {
    /*
     fact        ->     ID LEFT_PAREN STRING stringList
                        RIGHT_PAREN PERIOD
     */
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), STRING)) {
        index += 1;
    }
    
    stringList(tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), PERIOD)) {
        index += 1;
    }
    
    return true;
}

bool DatalogCheck::rule(const std::vector<Token *> &tokens,
                        int &index) {
    /*
     rule        ->    headPredicate COLON_DASH predicate
                        predicateList PERIOD
     */
    
    headPredicate(tokens, index);
    
    if (checkType(tokens.at(index + 0), COLON_DASH)) {
        index += 1;
    }
    
    predicate(tokens, index);
    predicateList(tokens, index);
    
    if (checkType(tokens.at(index + 0), PERIOD)) {
        index += 1;
    }
    
    return true;
}

bool DatalogCheck::query(const std::vector<Token *> &tokens,
                         int &index) {
    /*
     query       ->      predicate Q_MARK
     */
    
    predicate(tokens, index);
    
    if (checkType(tokens.at(index + 0), Q_MARK)) {
        index += 1;
    }
    
    return true;
}

// MARK: - Predicates

bool DatalogCheck::headPredicate(const std::vector<Token *> &tokens,
                                 int &index) {
    /*
     headPredicate    ->    ID LEFT_PAREN ID idList RIGHT_PAREN
     */
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
    }
    
    idList(tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    return true;
}

bool DatalogCheck::predicate(const std::vector<Token *> &tokens,
                             int &index) {
    /*
     predicate        ->    ID LEFT_PAREN parameter parameterList
                            RIGHT_PAREN
     */
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    parameter(tokens, index);
    parameterList(tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    return true;
}

// MARK: - Long Lists

bool DatalogCheck::predicateList(const std::vector<Token *> &tokens,
                                 int &index) {
    /*
     predicateList    ->    COMMA predicate predicateList | lambda
     */
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return false;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    bool result = predicate(tokens, index);
    predicateList(tokens, index);
    
    return result;
}

bool DatalogCheck::parameterList(const std::vector<Token *> &tokens,
                                 int &index) {
    /*
     parameterList    ->     COMMA parameter parameterList | lambda
     */
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return false;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    bool result = parameter(tokens, index);
    parameterList(tokens, index);
    
    return result;
}

bool DatalogCheck::stringList(const std::vector<Token *> &tokens,
                              int &index) {
    /*
     stringList       ->     COMMA STRING stringList | lambda
     */
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return false;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), STRING)) {
        index += 1;
    }
    
    stringList(tokens, index);
    
    return true;
}

bool DatalogCheck::idList(const std::vector<Token *> &tokens,
                          int &index) {
    /*
     idList           ->     COMMA ID idList | lambda
     */
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return false;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
    }
    
    idList(tokens, index);
    
    return true;
}


// MARK: - Smalls

bool DatalogCheck::parameter(const std::vector<Token *> &tokens,
                             int &index) {
    /*
     parameter     ->       STRING | ID | expression
     */
    
    if (checkType(tokens.at(index + 0), STRING)) {
        index += 1;
        return true;
    }
    
    if (checkType(tokens.at(index + 0), ID)) {
        index += 1;
        return true;
    }
    
    return expression(tokens, index);
}

bool DatalogCheck::expression(const std::vector<Token *> &tokens,
                              int &index) {
    /*
     expression    ->       LEFT_PAREN parameter operator parameter
                            RIGHT_PAREN
     */
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    if (parameter(tokens, index) &&
            op(tokens, index) &&
            parameter(tokens, index)) {
        if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
            index += 1;
        }
    }
    
    return true;
}

bool DatalogCheck::op(const std::vector<Token *> &tokens, int &index) {
    /*
     operator      ->       ADD | MULTIPLY
     */
    
    if (checkType(tokens.at(index + 0), { ADD, MULTIPLY })) {
        index += 1;
    }
    
    return true;
}

