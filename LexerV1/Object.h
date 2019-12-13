//
//  Object.h
//  LexerV1
//
//  Created by James Robinson on 12/9/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#include <iostream>

class Object {
private:
    int referenceCount = 0;
    
public:
    ~Object() {
        if (this->isOwned()) {
            std::cout << "--- WARNING: Deallocated an owned Object ---" << std::endl;
        }
    }
    
    void retain() {
        referenceCount += 1;
    }
    
    void release() {
        referenceCount -= 1;
        if (referenceCount < 0) {
            std::cout << "--- WARNING: An Object's referenceCount descended below 0 ---" << std::endl;
        }
    }
    
    bool isOwned() const {
        return referenceCount != 0;
    }
};
