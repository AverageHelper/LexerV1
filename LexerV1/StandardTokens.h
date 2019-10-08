//
//  StandardTokens.h
//  LexerV1
//
//  Created by James Robinson on 9/10/19.
//

#ifndef StandardTokens_h
#define StandardTokens_h

#include <string>
#include <map>
#include <vector>

enum TokenType {
    COMMA,
    PERIOD,
    Q_MARK,
    LEFT_PAREN,
    RIGHT_PAREN,
    COLON,
    COLON_DASH,
    MULTIPLY,
    ADD,
    SCHEMES,
    FACTS,
    RULES,
    QUERIES,
    ID,
    STRING,
    COMMENT,
    UNDEFINED,
    EOF_T
};

// Terminals
static const std::map<TokenType, std::string> TERMINALS = {
    {COMMA,         ","},
    {PERIOD,        "."},
    {Q_MARK,        "?"},
    {LEFT_PAREN,    "("},
    {RIGHT_PAREN,   ")"},
    {COLON,         ":"},
    {COLON_DASH,    ":-"},
    {MULTIPLY,      "*"},
    {ADD,           "+"},
    {SCHEMES,       "Schemes"},
    {FACTS,         "Facts"},
    {RULES,         "Rules"},
    {QUERIES,       "Queries"},
    {COMMENT,       "#"}
};

static const std::vector<std::string> KEY_WORDS = {
    "Schemes",
    "Facts",
    "Rules",
    "Queries"
};

inline bool stringIsKeyword(const std::string query) {
    for (unsigned int i = 0; i < KEY_WORDS.size(); i += 1) {
        if (query == KEY_WORDS.at(i)) {
            return true;
        }
    }
    return false;
}


inline TokenType tokenTypeForString(const std::string input) {
    if (input == TERMINALS.at(COMMA)) {
        return COMMA;
    }
    else if (input == TERMINALS.at(PERIOD)) {
        return PERIOD;
    }
    else if (input == TERMINALS.at(Q_MARK)) {
        return Q_MARK;
    }
    else if (input == TERMINALS.at(LEFT_PAREN)) {
        return LEFT_PAREN;
    }
    else if (input == TERMINALS.at(RIGHT_PAREN)) {
        return RIGHT_PAREN;
    }
    else if (input == TERMINALS.at(COLON)) {
        return COLON;
    }
    else if (input == TERMINALS.at(COLON_DASH)) {
        return COLON_DASH;
    }
    else if (input == TERMINALS.at(MULTIPLY)) {
        return MULTIPLY;
    }
    else if (input == TERMINALS.at(ADD)) {
        return ADD;
    }
    else if (input == TERMINALS.at(SCHEMES)) {
        return SCHEMES;
    }
    else if (input == TERMINALS.at(FACTS)) {
        return FACTS;
    }
    else if (input == TERMINALS.at(RULES)) {
        return RULES;
    }
    else if (input == TERMINALS.at(QUERIES)) {
        return QUERIES;
    }
    else {
        return UNDEFINED;
    }
}

inline std::string stringForTokenType(const TokenType type) {
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
        case UNDEFINED: return "UNDEFINED";
        case EOF_T: return "EOF";
    }
}

#endif /* StandardTokens_h */
