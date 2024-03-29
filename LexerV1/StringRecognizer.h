//
//  StringRecognizer.h
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#ifndef StringRecognizer_h
#define StringRecognizer_h

#include "Recognizer.h"

// Get "'", accept anything else, end at next "'" that doesn't preceed another.
class StringRecognizer: Recognizer {
private:
    std::string buffer = "";
    int* lineNum = nullptr;
    int state = 0;
    Token* applyState();
    
public:
    StringRecognizer(int* lineNum);
    virtual Token* recognizeTokenInStream(std::istream& stream);
};

#endif /* StringRecognizer_h */
