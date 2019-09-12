//
//  StringRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "StringRecognizer.h"

Token StringRecognizer::recognizeTokenInStream(std::istream& stream) {
    char next = stream.peek();
    
    if (next != '\'') {
        stream.ignore();
        return Token(UNDEFINED, stream.get(), -1);
    }
    
    while (next != EOF) {
        char thisChar = stream.get();
        next = stream.peek();
        
        buffer.append(std::string(1, thisChar));
        
        if (buffer.size() > 1 &&
            thisChar == '\'' &&
            next != '\'') {
            // A ' that isn't followed by another ' means end of the string.
            break;
        }
        
        if (next == EOF) {
            return Token(UNDEFINED, buffer, -1);
        }
    }
    
    return Token(STRING, buffer, -1);
}
