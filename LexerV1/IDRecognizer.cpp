//
//  IDRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "IDRecognizer.h"

Token IDRecognizer::recognizeTokenInStream(std::istream& stream) {
    char next = stream.peek();
    
    if (isalpha(next)) {
        buffer.append(std::string(1, stream.get()));
        next = stream.peek();
    } else {
        return Token(UNDEFINED, stream.get(), -1);
    }
    
    while (isalnum(next)) {
        buffer.append(std::string(1, stream.get()));
        next = stream.peek();
    }
    
    // If our buffer contains a token, return that instead.
    if (stringIsKeyword(buffer)) {
        TokenType type = tokenTypeForString(buffer);
        return Token(type, buffer, -1);
    }
    
    return Token(ID, buffer, -1);
}
