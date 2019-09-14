//
//  IDRecognizer.h
//  LexerV1
//
//  Created by James Robinson on 9/11/19.
//

#ifndef IDRecognizer_h
#define IDRecognizer_h

#include <istream>
#include "Recognizer.h"

class IDRecognizer: Recognizer {
private:
    std::string buffer = "";
    
public:
    virtual Token* recognizeTokenInStream(std::istream& stream);
};

#endif /* IDRecognizer_h */
