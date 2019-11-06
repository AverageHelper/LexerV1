//
//  Tuple.cpp
//  LexerV1
//
//  Created by James Robinson on 11/4/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include "Tuple.h"

Tuple::Tuple(std::vector<std::string> contents) {
    for (unsigned int i = 0; i < contents.size(); i += 1) {
        this->push_back(contents.at(i));
    }
}

Tuple::Tuple(const Tuple &other) {
    for (unsigned int i = 0; i < other.size(); i += 1) {
        this->push_back(other.at(i));
    }
}
