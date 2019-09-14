//
//  CommentRecognizer.cpp
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#include "CommentRecognizer.h"

/// Returns @c true if the first two characters of the receiver's buffer
/// begin a block comment. (i.e. "#|")
bool CommentRecognizer::isBlock() {
    if (buffer.size() < 2) {
        return false;
    }
    return (buffer[0] == '#') && (buffer[1] == '|');
}

Token* CommentRecognizer::recognizeTokenInStream(std::istream& stream) {
    // s1: Await input
    char next = stream.peek();
    
    if (next != '#') {
        // s2 (reject): Input doesn't begin a valid comment.
        return new Token(UNDEFINED, stream.get(), -1);
    }
    
    while (next != EOF && !(!isBlock() && next == '\n')) {
        // s3: Await input
        char thisChar = stream.get();
        next = stream.peek();
        
        buffer.append(std::string(1, thisChar));
        
        if (isBlock() && thisChar == '|' && next == '#') {
            // s4 (accept): Block comment has found its terminator
            buffer.append(std::string(1, stream.get()));
            break;
        }
        
        if (isBlock() && next == EOF) {
            // s2 (reject): Block comment hit end of line before termination.
            return new Token(UNDEFINED, buffer, -1);
        }
    }
    
    // s4 (accept): Terminate comment (either by new line or terminator, if block)
    return new Token(COMMENT, buffer, -1);
}
