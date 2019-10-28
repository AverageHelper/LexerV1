//
//  StringRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "StringRecognizer.h"

StringRecognizer::StringRecognizer(int* lineNum) {
    this->buffer = "";
    this->lineNum = lineNum;
    this->state = 0;
}

Token* StringRecognizer::applyState() {
    switch (state) {
        case 4: return new Token(UNDEFINED, buffer, -1);
        case 3: return new Token(STRING, buffer, -1);
        case 2:
        case 1:
        default: return nullptr;
    }
}

Token* StringRecognizer::recognizeTokenInStream(std::istream& stream) {
    // s0: Await input
    char next = stream.peek();
    Token* appliedToken;
    
    if (next != '\'') {
        return new Token(UNDEFINED, stream.get(), -1);
    }
    
    state = 1;
    
    while (next != EOF) {
        char thisChar = stream.get();
        next = stream.peek();
        
        buffer.append(std::string(1, thisChar));
        
        if (thisChar == '\n' && lineNum != nullptr) {
            // Handle line count
            (*lineNum) += 1;
            continue;
        }
        
        if (buffer.size() > 1 && state == 1 && thisChar == '\'') {
            // Listen now for next ' for whether terminator or apostrophe
            state = 2;
        }
        
        if (state == 2 && next == '\'') {
            // Apostrophe: move along
            buffer.append(std::string(1, stream.get()));
            state = 1;
            
        } else if (state == 2) {
            // Terminator
            state = 3;
            appliedToken = applyState();
            if (appliedToken != nullptr) {
                return appliedToken;
            }
        }
        
        if (next == EOF) {
            // Shouldn't see EOF before terminator
            state = 4;
            appliedToken = applyState();
            if (appliedToken != nullptr) {
                return appliedToken;
            }
        }
    }
    
    state = 4;
    return applyState();
}

/*
Token* StringRecognizer::recognizeTokenInStream(std::istream& stream) {
    // s1: Await input
    char next = stream.peek();
    
    if (next != '\'') {
        // s3 (reject): Input doesn't begin a valid string.
        return new Token(UNDEFINED, stream.get(), -1);
    }
    
    while (next != EOF) {
        // s1: Await string input/possible termination, but may be escaped '
        char thisChar = stream.get();
        next = stream.peek();
        
        buffer.append(std::string(1, thisChar));
        
        if (thisChar == '\n' && lineNum != nullptr) {
            (*lineNum) += 1;
            continue;
        }
        
        if (next == EOF) {
            // s3 (reject): Input stops here, leaving the string unterminated.
            return new Token(UNDEFINED, buffer, -1);
        }
        
        if (thisChar == '\'') {
            // s2: Peek input. Return to s1 if next is '. s3 (accept) otherwise.
            
            if (next != '\'' && buffer.size() > 2 && buffer[buffer.size() - 2] != '\'') {
                break;
            }
        }
    }
    
    // s5 (accept): String terminates.
    return new Token(STRING, buffer, -1);
}

*/
