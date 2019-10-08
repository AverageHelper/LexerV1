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

DatalogProgram* DatalogCheck::checkGrammar(const std::vector<Token *> &tokens) {
    int start = 0;
    DatalogProgram* result = nullptr;
    std::vector<Token*> cleanTokens = {};
    
    for (unsigned int i = 0; i < tokens.size(); i += 1) {
        if (tokens.at(i)->getType() != COMMENT) {
            cleanTokens.push_back(tokens.at(i));
        }
    }
    
    try {
        currentNonTerminal = "";
        result = datalogProgram(cleanTokens, start);
        if (debugLogging) {
            std::cout << "Success!" << std::endl;
        }
        currentNonTerminal = "";
        
    } catch (WrongToken& e) {
        if (debugLogging) {
            std::cout << "Failure!" << std::endl << "  ";
            std::cout << e.getToken().toString() << std::endl;
        }
    }
    
    return result;
}

// MARK: - Check Token Types

Token* DatalogCheck::checkType(Token* token,
                               const std::vector<TokenType> expectedTypes) {
    
    for (unsigned int i = 0; i < expectedTypes.size(); i += 1) {
        if (expectedTypes.at(i) == token->getType()) {
            return token;
        }
    }
    
    throw WrongToken(*token);
    return nullptr;
}

Token* DatalogCheck::checkType(Token *token,
                               const TokenType expectedType) {
    std::vector<TokenType> expected = { expectedType };
    return checkType(token, expected);
}

bool DatalogCheck::peekType(const Token* token,
                            const TokenType expectedType) {
    return token->getType() == expectedType;
}



// MARK: - datalogProgram

DatalogProgram* DatalogCheck::datalogProgram(const std::vector<Token *> &tokens, int &index) {
    /*
    datalogProgram    ->    SCHEMES COLON scheme schemeList
                            FACTS COLON factList
                            RULES COLON ruleList
                            QUERIES COLON query queryList
     */
    
    currentNonTerminal = "datalogProgram";
    
    // Always add our expected stream position modifier to the given index pointer.
    if (checkType(tokens.at(index + 0), SCHEMES) != nullptr) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), COLON) != nullptr) {
        index += 1;
    }
    
    std::vector<Predicate*> schemeStart = {};
    std::vector<Predicate*> schemes = schemeList(schemeStart, tokens, index);
    
    if (checkType(tokens.at(index + 0), FACTS) != nullptr) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), COLON) != nullptr) {
        index += 1;
    }
    
    std::vector<Predicate*> factStart = {};
    std::vector<Predicate*> facts = factList(factStart, tokens, index);
    
    if (checkType(tokens.at(index + 0), RULES) != nullptr) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), COLON) != nullptr) {
        index += 1;
    }
    
    std::vector<Rule*> ruleStart = {};
    std::vector<Rule*> rules = ruleList(ruleStart, tokens, index);
    
    if (checkType(tokens.at(index + 0), QUERIES) != nullptr) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), COLON) != nullptr) {
        index += 1;
    }
    
    std::vector<Predicate*> queryStart = {};
    std::vector<Predicate*> queries = queryList(queryStart, tokens, index);
    
    DatalogProgram* result = new DatalogProgram();
    result->setSchemes(schemes);
    result->setFacts(facts);
    result->setRules(rules);
    result->setQueries(queries);
    
    return result;
}

// MARK: - Lists

std::vector<Predicate*> DatalogCheck::schemeList(std::vector<Predicate*> &schemeList,
                                                 const std::vector<Token *> &tokens,
                                                 int &index) {
    /*
     schemeList  ->    scheme schemeList | lambda
     */
    
    currentNonTerminal = "schemeList";
    std::vector<Predicate*> result = schemeList;
    
    // Check FIRST(scheme)
    if (!peekType(tokens.at(index + 0), ID)) {
        return result;
    }
    
    result.push_back(scheme(tokens, index));
    return this->schemeList(result, tokens, index);
}

std::vector<Predicate*> DatalogCheck::factList(std::vector<Predicate*> &factList,
                                               const std::vector<Token *> &tokens,
                                               int &index) {
    /*
     factList    ->    fact factList | lambda
     */
    
    currentNonTerminal = "factList";
    std::vector<Predicate*> result = factList;
    
    // Check FIRST(fact)
    if (!peekType(tokens.at(index + 0), ID)) {
        return result;
    }
    
    result.push_back(fact(tokens, index));
    return this->factList(result, tokens, index);
}

std::vector<Rule*> DatalogCheck::ruleList(std::vector<Rule*> &ruleList,
                                          const std::vector<Token *> &tokens,
                                          int &index) {
    /*
     ruleList    ->    rule ruleList | lambda
     */
    
    currentNonTerminal = "ruleList";
    std::vector<Rule*> result = ruleList;
    
    // Check FIRST(rule)
    if (!peekType(tokens.at(index + 0), ID)) {
        return result;
    }
    
    result.push_back(rule(tokens, index));
    return this->ruleList(result, tokens, index);
}

std::vector<Predicate*> DatalogCheck::queryList(std::vector<Predicate*> &queryList,
                                                const std::vector<Token *> &tokens,
                                                int &index) {
    /*
     queryList   ->    query queryList | lambda
     */
    
    currentNonTerminal = "queryList";
    std::vector<Predicate*> result = queryList;
    
    // Check FIRST(query)
    if (!peekType(tokens.at(index + 0), ID)) {
        return result;
    }
    
    result.push_back(query(tokens, index));
    return this->queryList(result, tokens, index);
}

// MARK: - Items

Predicate* DatalogCheck::scheme(const std::vector<Token *> &tokens,
                                int &index) {
    /*
     scheme      ->     ID LEFT_PAREN ID idList RIGHT_PAREN
     */
    
    currentNonTerminal = "scheme";
    std::string schemeID = "<NO_ID>";
    
    if (checkType(tokens.at(index + 0), ID)) {
        schemeID = tokens.at(index + 0)->getValue();
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    std::vector<std::string> idList = {};
    if (checkType(tokens.at(index + 0), ID)) {
        idList.push_back(tokens.at(index + 0)->getValue());
        index += 1;
    }
    
    idList = this->idList(idList, tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    Predicate* result = new Predicate(SCHEMES, schemeID);
    result->setItems(idList);
    
    return result;
}

Predicate* DatalogCheck::fact(const std::vector<Token *> &tokens,
                              int &index) {
    /*
     fact        ->     ID LEFT_PAREN STRING stringList
                        RIGHT_PAREN PERIOD
     */
    
    currentNonTerminal = "fact";
    std::string factID = "<NO_ID>";
    
    if (checkType(tokens.at(index + 0), ID)) {
        factID = tokens.at(index + 0)->getValue();
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    std::vector<std::string> stringList = {};
    if (checkType(tokens.at(index + 0), STRING)) {
        stringList.push_back(tokens.at(index + 0)->getValue());
        index += 1;
    }
    
    stringList = this->stringList(stringList, tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), PERIOD)) {
        index += 1;
    }
    
    Predicate* result = new Predicate(FACTS, factID);
    result->setItems(stringList);
    
    return result;
}

Rule* DatalogCheck::rule(const std::vector<Token *> &tokens,
                         int &index) {
    /*
     rule        ->    headPredicate COLON_DASH predicate
                        predicateList PERIOD
     */
    
    currentNonTerminal = "rule";
    
    Predicate* head = headPredicate(tokens, index);
    head->setType(RULES);
    
    if (checkType(tokens.at(index + 0), COLON_DASH)) {
        index += 1;
    }
    
    std::vector<Predicate*> predicates = {};
    Predicate* thisPred = predicate(tokens, index);
    thisPred->setType(RULES);
    predicates.push_back(thisPred);
    
    predicates = predicateList(predicates, tokens, index);
    
    if (checkType(tokens.at(index + 0), PERIOD)) {
        index += 1;
    }
    
    Rule* result = new Rule();
    result->setHeadPredicate(head);
    result->setPredicates(predicates);
    
    return result;
}

Predicate* DatalogCheck::query(const std::vector<Token *> &tokens,
                               int &index) {
    /*
     query       ->      predicate Q_MARK
     */
    
    currentNonTerminal = "query";
    
    Predicate* query = predicate(tokens, index);
    
    if (checkType(tokens.at(index + 0), Q_MARK)) {
        index += 1;
    }
    
    query->setType(QUERIES);
    
    return query;
}

// MARK: - Predicates

Predicate* DatalogCheck::headPredicate(const std::vector<Token *> &tokens,
                                       int &index) {
    /*
     headPredicate    ->    ID LEFT_PAREN ID idList RIGHT_PAREN
     */
    
    currentNonTerminal = "headPredicate";
    std::string predID = "<NO_ID>";
    
    if (checkType(tokens.at(index + 0), ID)) {
        predID = tokens.at(index + 0)->getValue();
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    std::vector<std::string> foundIDs = {};
    if (checkType(tokens.at(index + 0), ID)) {
        foundIDs.push_back(tokens.at(index + 0)->getValue());
        index += 1;
    }
    
    foundIDs = idList(foundIDs, tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    Predicate* result = new Predicate(UNDEFINED, predID);
    result->setItems(foundIDs);
    
    return result;
}

Predicate* DatalogCheck::predicate(const std::vector<Token *> &tokens,
                                   int &index) {
    /*
     predicate        ->    ID LEFT_PAREN parameter parameterList
                            RIGHT_PAREN
     */
    
    currentNonTerminal = "predicate";
    std::string predID = "<NO_ID>";
    
    if (checkType(tokens.at(index + 0), ID)) {
        predID = tokens.at(index + 0)->getValue();
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    std::vector<std::string> params = {};
    params.push_back(parameter(tokens, index));
    params = parameterList(params, tokens, index);
    
    if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
        index += 1;
    }
    
    Predicate* result = new Predicate(UNDEFINED, predID);
    result->setItems(params);
    
    return result;
}

// MARK: - Long Lists

std::vector<Predicate*> DatalogCheck::predicateList(const std::vector<Predicate*> &foundPredicates,
                                                    const std::vector<Token *> &tokens,
                                                    int &index) {
    /*
     predicateList    ->    COMMA predicate predicateList | lambda
     */
    
    currentNonTerminal = "predicateList";
    std::vector<Predicate*> result = foundPredicates;
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return result;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    result.push_back(predicate(tokens, index));
    return predicateList(result, tokens, index);
}

std::vector<std::string> DatalogCheck::parameterList(const std::vector<std::string> &foundParams,
                                                     const std::vector<Token *> &tokens,
                                                     int &index) {
    /*
     parameterList    ->     COMMA parameter parameterList | lambda
     */
    
    currentNonTerminal = "parameterList";
    std::vector<std::string> result = foundParams;
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return result;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    result.push_back(parameter(tokens, index));
    return parameterList(result, tokens, index);
}

std::vector<std::string> DatalogCheck::stringList(const std::vector<std::string> &foundStrings,
                                                  const std::vector<Token *> &tokens,
                                                  int &index) {
    /*
     stringList       ->     COMMA STRING stringList | lambda
     */
    
    currentNonTerminal = "stringList";
    std::vector<std::string> result = foundStrings;
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return result;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), STRING)) {
        result.push_back(tokens.at(index + 0)->getValue());
        index += 1;
    }
    
    return stringList(result, tokens, index);
}

std::vector<std::string> DatalogCheck::idList(const std::vector<std::string> &foundIDs,
                                              const std::vector<Token *> &tokens,
                                              int &index) {
    /*
     idList           ->     COMMA ID idList | lambda
     */
    
    currentNonTerminal = "idList";
    std::vector<std::string> result = foundIDs;
    
    if (!peekType(tokens.at(index + 0), COMMA)) {
        return result;
    }
    
    if (checkType(tokens.at(index + 0), COMMA)) {
        index += 1;
    }
    
    if (checkType(tokens.at(index + 0), ID)) {
        result.push_back(tokens.at(index + 0)->getValue());
        index += 1;
    }
    
    return idList(result, tokens, index);
}


// MARK: - Parts

std::string DatalogCheck::parameter(const std::vector<Token *> &tokens,
                                    int &index) {
    /*
     parameter     ->       STRING | ID | expression
     */
    
    currentNonTerminal = "parameter";
    std::string result = "";
    
    if (peekType(tokens.at(index + 0), STRING)) {
        result = tokens.at(index + 0)->getValue();
        index += 1;
        return result;
    }
    
    if (peekType(tokens.at(index + 0), ID)) {
        result = tokens.at(index + 0)->getValue();
        index += 1;
        return result;
    }
    
    return expression(tokens, index);
}

std::string DatalogCheck::expression(const std::vector<Token *> &tokens,
                                     int &index) {
    /*
     expression    ->       LEFT_PAREN parameter operator parameter
                            RIGHT_PAREN
     */
    
    currentNonTerminal = "expression";
    std::string result = "";
    
    if (checkType(tokens.at(index + 0), LEFT_PAREN)) {
        index += 1;
    }
    
    std::string lhs = parameter(tokens, index);
    if (lhs.empty()) {
        return "";
    }
    
    std::string op = this->op(tokens, index);
    if (op.empty()) {
        return "";
    }
    
    std::string rhs = parameter(tokens, index);
    if (rhs.empty()) {
        return "";
    }
    
//    if (parameter(tokens, index) &&
//            op(tokens, index) &&
//            parameter(tokens, index)) {
//
        if (checkType(tokens.at(index + 0), RIGHT_PAREN)) {
            result = lhs + op + rhs;
            index += 1;
        }
//    }
    
    return result;
}

std::string DatalogCheck::op(const std::vector<Token *> &tokens, int &index) {
    /*
     operator      ->       ADD | MULTIPLY
     */
    
    currentNonTerminal = "operator";
    std::string result = "";
    
    if (checkType(tokens.at(index + 0), { ADD, MULTIPLY })) {
        result = tokens.at(index + 0)->getValue();
        index += 1;
    }
    
    return result;
}

