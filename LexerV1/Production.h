//
//  Production.h
//  LexerV1
//
//  Created by James Robinson on 9/30/19.
//

#ifndef Production_h
#define Production_h

#include <iostream>
#include <sstream>
#include <exception>
#include <string>
#include <vector>
#include "Token.h"

class Production {
public:
    /// Returns a string representation of the receiver.
    virtual std::string toString() = 0;
};

#endif /* Production_h */