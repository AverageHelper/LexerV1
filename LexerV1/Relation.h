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
#include <vector>
#include "Tuple.h"

class Relation {
private:
    std::string name;
    Tuple scheme;
    std::set<Tuple> contents;
    
    /// Removes columns from @c otherScheme which are not found in the relation's scheme.
    ///
    /// Has no effect on the relation's solumns or scheme.
    void stripExtraColsFromScheme(Tuple &otherScheme) const;
    
    /// Returns @c true if @c domain contains @c query.
    bool vectorContainsValue(const std::vector<std::string> &domain, const std::string &query) const;
    
    /// Returns the index of @c col in @c domain, or -1 if it is not found.
    int indexForColumnInTuple(std::string col, const Tuple &domain);
    
    /// Swaps the relation's scheme and values at index @c oldCol with @c newCol.
    ///
    /// If @c newCol exceeds the scheme's last index, swaps with the last column instead.
    void swapColumns(size_t oldCol, size_t newCol);
    
    /// Strips all columns following @c col from the relation, including @c col.
    void keepOnlyColumnsUntil(size_t col);
    
public:
    Relation(const Relation &other);
    Relation(const std::string name, Tuple scheme = Tuple());
    ~Relation();
    
    std::string getName() const;
    Tuple getScheme() const;
    size_t getColumnCount() const;
    
    /// Adds the @c Tuple to the relation.  The tuple @b must contain exactly the number of elements specified in the relation.
    bool addTuple(Tuple element);
    std::set<Tuple> getContents() const;
    std::vector<Tuple> listContents() const;
    
    int indexForColumnInScheme(std::string col);
    
    
    /// Given a name @e in the schema, and a new name @e not in the schema, pretend the name is actually the new name.
    Relation* rename(std::string oldCol, std::string newCol) const;
    
    
    /// Get tuples whose values match each equivalence pair given in @c queries.
    ///
    /// Each @c pair denotes a column index and an expected value to find at that index. Each @c Tuple in the resulting @c Relation will contain values at each index that match the query's value.
    ///
    /// A query is ignored if its column index is not valid for the relation's scheme.
    ///
    /// @returns A new @c Relation whose rows match the query.
    Relation* select(std::vector< std::pair<size_t, std::string> > queries) const;
    
    
    /// Get tuples whose values match each equivalence pair given in @c queries.
    ///
    /// Each @c pair denotes two column indices. Each @c Tuple in the resulting @c Relation will contain matching values at both indices.
    /// That is, the value at the first index matches the value at the second.
    ///
    /// A query is ignored if either column index is not valid for the relation's scheme.
    ///
    /// @returns A new @c Relation whose rows match the query.
    Relation* select(std::vector< std::pair<size_t, size_t> > queries) const;
    
    
    /// Keep only the columns from the relation that correspond to the positions of the variables in the query.
    Relation* project(Tuple otherScheme) const;
    
    bool operator==(const Relation &other);
};

#endif /* Relation_h */
