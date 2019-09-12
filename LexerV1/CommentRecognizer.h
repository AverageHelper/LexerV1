//
//  CommentRecognizer.h
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#ifndef CommentRecognizer_h
#define CommentRecognizer_h

#include "Recognizer.h"

// Get "'", accept anything else, end at next "'" that doesn't preceed another.
class CommentRecognizer: Recognizer {
private:
    std::string buffer = "";
    bool isBlock();
    
public:
    virtual Token recognizeTokenInStream(std::istream& stream);
};

#endif /* CommentRecognizer_h */
