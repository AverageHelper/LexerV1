//
//  Lexer.h
//  LexerV1
//
//  Created by James Robinson on 10/25/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#ifndef Lexer_h
#define Lexer_h

#include <iostream>
#include <sstream>
#include <vector>
#include <string>
#include <fstream>
#include "Recognizers.h"

/// Parses tokens in the open @c file stream.
inline std::vector<Token*> collectedTokensFromFile(std::ifstream& file) {
    std::vector<Token*> tokens = std::vector<Token*>();
    
    // Parse tokens from stream
    int currentLine = 1;
    
    while (!file.eof()) {
        char next = file.peek();
        
        switch (next) {
            case '\n':
                currentLine += 1;
                file.ignore();
                continue;
                
            case EOF:
                file.ignore();
                continue;
                
            case ' ':
                file.ignore();
                continue;
                
            case ',':
            case '.':
            case '?':
            case '(':
            case ')':
            case '*':
            case '+': {
                Token* token = OperatorRecognizer().recognizeTokenInStream(file);
                token->setLineNum(currentLine);
                tokens.push_back(token);
                break;
            }
                
            case ':': {
                Token* token;
                // s0: Await input
                char colon = file.get();
                // s1: We have a colon
                
                if (file.peek() == '-') {
                    // s2 (accept): Receive dash, -> Token(':-')
                    file.ignore();
                    token = new Token(COLON_DASH, ":-", currentLine);
                } else {
                    // s3 (accept): Peek something else, -> Token(':')
                    token = new Token(COLON, colon, currentLine);
                }
                
                tokens.push_back(token);
                break;
            }
                
            case '#': {
                int firstLine = currentLine;
                Token* token = CommentRecognizer(&currentLine).recognizeTokenInStream(file);
                token->setLineNum(firstLine);
                tokens.push_back(token);
                break;
            }
                
            case '\'': {
                int firstLine = currentLine;
                Token* token = StringRecognizer(&currentLine).recognizeTokenInStream(file);
                token->setLineNum(firstLine);
                tokens.push_back(token);
                break;
            }
                
            default: {
                Token* token = IDRecognizer().recognizeTokenInStream(file);
                token->setLineNum(currentLine);
                tokens.push_back(token);
                break;
            }
        }
    }
    
    Token* eof = new Token(EOF_T, "", currentLine);
    tokens.push_back(eof);
    
    return tokens;
}

inline std::string stringFromTokens(const std::vector<Token*>& tokens) {
    std::ostringstream stm = std::ostringstream();
    
    for (unsigned int i = 0; i < tokens.size(); i += 1) {
        stm << tokens.at(i)->toString() << std::endl;
    }
    
    stm << "Total Tokens = " << tokens.size();
    
    return stm.str();
}

/// Prints tokens in the given @c vector.
inline void printTokens(const std::vector<Token*>& tokens) {
    std::cout << stringFromTokens(tokens) << std::endl;
}

/// Deletes the pointers in @c tokens and clears the vector.
inline void releaseTokens(std::vector<Token*>& tokens) {
    for (unsigned int i = 0; i < tokens.size(); i += 1) {
        delete tokens.at(i);
    }
    
    tokens.clear();
}

#endif /* Lexer_h */
