//
//  OperatorRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "OperatorRecognizer.h"

Token* OperatorRecognizer::recognizeTokenInStream(std::istream& stream) {
    // s0: Await input
    char next = stream.peek();
    
    switch (next) {
        // s1 (accept): Valid operator
        case ',': return new Token(COMMA, stream.get(), -1); break;
        case '.': return new Token(PERIOD, stream.get(), -1); break;
        case '?': return new Token(Q_MARK, stream.get(), -1); break;
        case '(': return new Token(LEFT_PAREN, stream.get(), -1); break;
        case ')': return new Token(RIGHT_PAREN, stream.get(), -1); break;
        case ':': return new Token(COLON, stream.get(), -1); break;
        case '*': return new Token(MULTIPLY, stream.get(), -1); break;
        case '+': return new Token(ADD, stream.get(), -1); break;
        
        // s2 (reject): Unknown token
        default: return new Token(UNDEFINED, stream.get(), -1);
    }
}
