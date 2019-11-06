//
//  Relation.h
//  LexerV1
//
//  Created by James Robinson on 11/4/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef Relation_h
#define Relation_h

#include <string>
#include <set>
#include "Tuple.h"

class Relation {
private:
    std::string name;
    Tuple scheme;
    std::set<Tuple> contents;
    
public:
    Relation(const std::string name, Tuple scheme = Tuple());
    ~Relation();
    
    const std::string getName();
    
    void setScheme(Tuple scheme);
    Tuple getScheme();
    size_t getColumnCount();
    
    /// Adds the @c Tuple to the relation.  The tuple @b must contain exactly the number of elements specified in the relation.
    bool addTuple(Tuple element);
    const std::set<Tuple> getContents();
    
    /// Given a name @e in the schema, and a new name @e not in the schema, pretend the name is actually the new name.
    Relation* rename(std::string oldName, std::string newName);
    
    /// Get tuples that satisfy a condition of attributes in the schema.
    Relation* select(Tuple parameters);
    
    /// Keep only the columns from the relation that correspond to the positions of the variables in the query.
    Relation* project(Tuple scheme);
};

#endif /* Relation_h */
