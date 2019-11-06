//
//  Tuple.h
//  LexerV1
//
//  Created by James Robinson on 11/4/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef Tuple_h
#define Tuple_h

#include <string>
#include <vector>

class Tuple: public std::vector<std::string> {
public:
    Tuple(std::vector<std::string> contents = {});
    Tuple(const Tuple &other);
};

#endif /* Tuple_h */
