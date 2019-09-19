//
//  IDRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "IDRecognizer.h"

Token* IDRecognizer::recognizeTokenInStream(std::istream& stream) {
    // s0: Await input
    char next = stream.peek();
    
    if (isalpha(next)) {
        // s1: Input begins a valid identifier.
        buffer.append(std::string(1, stream.get()));
        next = stream.peek();
    } else {
        // s3 (reject): Input didn't start with an alphabetic character.
        return new Token(UNDEFINED, stream.get(), -1);
    }
    
    while (isalnum(next)) {
        // s1: Await input, until we foresee a non-identifier character.
        buffer.append(std::string(1, stream.get()));
        next = stream.peek();
    }
    
    // s2: Identifier is valid.
    
    if (stringIsKeyword(buffer)) {
        // s2 (accept): Identifier is a special token.
        TokenType type = tokenTypeForString(buffer);
        return new Token(type, buffer, -1);
    }
    
    // s2 (accept): Identifier is valid.
    return new Token(ID, buffer, -1);
}
