//
//  OperatorRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "OperatorRecognizer.h"

Token OperatorRecognizer::recognizeTokenInStream(std::istream& stream) {
    // switch first character of `stream`. If it's a valid operator, read it, then return the token.
    char next = stream.peek();
    
    switch (next) {
        case ',': return Token(COMMA, stream.get(), -1); break;
        case '.': return Token(PERIOD, stream.get(), -1); break;
        case '?': return Token(Q_MARK, stream.get(), -1); break;
        case '(': return Token(LEFT_PAREN, stream.get(), -1); break;
        case ')': return Token(RIGHT_PAREN, stream.get(), -1); break;
        case ':': return Token(COLON, stream.get(), -1); break;
        case '*': return Token(MULTIPLY, stream.get(), -1); break;
        case '+': return Token(ADD, stream.get(), -1); break;
            
        default: return Token(UNDEFINED, stream.get(), -1);
    }
}
