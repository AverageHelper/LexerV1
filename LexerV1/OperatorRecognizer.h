//
//  OperatorRecognizer.h
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#ifndef OperatorRecognizer_h
#define OperatorRecognizer_h

#include "Recognizer.h"

class OperatorRecognizer: Recognizer {
public:
    virtual Token recognizeTokenInStream(std::istream& stream);
};

#endif /* OperatorRecognizer_h */
