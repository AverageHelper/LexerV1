//
//  Token.h
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef Token_h
#define Token_h

#include "StandardTokens.h"

class Token {
private:
    TokenType type;
    std::string value;
    int lineNum;
    
    std::string typeString() const {
        switch (type) {
            case COMMA: return "COMMA";
            case PERIOD: return "PERIOD";
            case Q_MARK: return "Q_MARK";
            case LEFT_PAREN: return "LEFT_PAREN";
            case RIGHT_PAREN: return "RIGHT_PAREN";
            case COLON: return "COLON";
            case COLON_DASH: return "COLON_DASH";
            case MULTIPLY: return "MULTIPLY";
            case ADD: return "ADD";
            case SCHEMES: return "SCHEMES";
            case FACTS: return "FACTS";
            case RULES: return "RULES";
            case QUERIES: return "QUERIES";
            case ID: return "ID";
            case STRING: return "STRING";
            case COMMENT: return "COMMENT";
            case EOF_T: return "EOF";
            case UNDEFINED:
            default: return "UNDEFINED";
        }
    }
    
public:
    TokenType getType() const {
        return this->type;
    }
    
    std::string getValue() const {
        return this->value;
    }
    
    int getLineNum() const {
        return this->lineNum;
    }
    
    /// Returns a string describing the receiver in the form @c (type,"value",line).
    std::string toString() const {
        return "("
                + typeString() + ","
                + "\"" + value + "\","
                + std::to_string(lineNum)
                + ")";
    }
    
    void setLineNum(const int lineNum) {
        this->lineNum = lineNum;
    }
    
    Token() {
        this->type = UNDEFINED;
        this->value = "";
        this->lineNum = 0;
    }
    
    Token(const Token &other) {
        this->type = other.type;
        this->value = other.value;
        this->lineNum = other.lineNum;
    }
    
    Token(const TokenType type,
          const std::string value = "",
          const int lineNum = -1) {
        this->type = type;
        this->value = value;
        this->lineNum = lineNum;
    }
    
    Token(const TokenType type,
          const char value,
          const int lineNum) {
        this->type = type;
        this->value = std::string(1, value);
        this->lineNum = lineNum;
    }
};

#endif /* Token_h */
