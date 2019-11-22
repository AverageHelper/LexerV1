//
//  Database.h
//  LexerV1
//
//  Created by James Robinson on 11/4/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef Database_h
#define Database_h

#include <string>
#include <vector>
#include "Relation.h"
#include "Tuple.h"

class Database {
private:
    std::vector<Relation*> relations;
    
public:
    Database();
    ~Database();
    
    const std::vector<Relation*> getRelations();
    /// Adds the given @c relation to the database.
    /// @returns @c true if the relation was added.
    bool addRelation(Relation* relation);
    Relation* relationWithName(std::string name);
};

#endif /* Database_h */
