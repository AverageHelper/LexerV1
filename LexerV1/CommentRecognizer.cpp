//
//  CommentRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "CommentRecognizer.h"

bool CommentRecognizer::isBlock() {
    if (buffer.size() < 2) {
        return false;
    }
    
    return (buffer[0] == '#') && (buffer[1] == '|');
}

Token CommentRecognizer::recognizeTokenInStream(std::istream& stream) {
    char next = stream.peek();
    
    if (next != '#') {
        stream.ignore();
        return Token(UNDEFINED, stream.get(), -1);
    }
    
    while (next != EOF && !(!isBlock() && next == '\n')) {
        char thisChar = stream.get();
        next = stream.peek();
        
        buffer.append(std::string(1, thisChar));
        
        if (thisChar == '|' && next == '#') {
            buffer.append(std::string(1, stream.get()));
            break;
        }
        
        if (isBlock() && next == EOF) {
            return Token(UNDEFINED, buffer, -1);
        }
    }
    
    return Token(COMMENT, buffer, -1);
}
