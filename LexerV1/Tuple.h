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
#include <set>

class Tuple: public std::vector<std::string> {
public:
    Tuple(std::vector<std::string> contents = {});
    Tuple(const Tuple &other);
    
    /// Concatinates the values of @c other uniquely with the receiver's contents.
    Tuple combinedWith(const Tuple& other) const;
    
    /// Returns the first index where @c val can be found in the tuple.
    ///
    /// @returns An index, or -1 if @c val cannot be found.
    int firstIndexOf(const std::string& val) const;
    
    /// Contactinates the receiver's contents.
    std::string toString() const;
};

#endif /* Tuple_h */
