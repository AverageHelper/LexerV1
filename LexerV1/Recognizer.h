//
//  Recognizer.h
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#ifndef Recognizer_h
#define Recognizer_h

#include <istream>
#include "Token.h"

class Recognizer {
public:
    virtual Token* recognizeTokenInStream(std::istream& stream) = 0;
};

#endif /* Recognizer_h */
