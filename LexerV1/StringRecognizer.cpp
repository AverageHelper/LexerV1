//
//  StringRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "StringRecognizer.h"

Token* StringRecognizer::recognizeTokenInStream(std::istream& stream) {
    // s1: Await input
    char next = stream.peek();
    
    if (next != '\'') {
        // s2 (reject): Input doesn't begin a valid string.
        return new Token(UNDEFINED, stream.get(), -1);
    }
    
    while (next != EOF) {
        // s3/s4: Await string input/possible termination, but may be escaped '
        char thisChar = stream.get();
        next = stream.peek();
        
        buffer.append(std::string(1, thisChar));
        
        if (next == EOF) {
            // s2 (reject): Input stops here, leaving the string unterminated.
            return new Token(UNDEFINED, buffer, -1);
        }
        
        if (buffer.size() > 1 &&
            thisChar == '\'' &&
            next != '\'') {
            
            if (buffer.size() == 2 ||
                buffer[buffer.size() - 2] != '\'') {
                // s5 (accept): Not escaped. String terminates.
                break;
            }
            
        }
    }
    
    // s5 (accept): String terminates.
    return new Token(STRING, buffer, -1);
}
