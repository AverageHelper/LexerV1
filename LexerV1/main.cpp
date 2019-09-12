//
//  main.cpp
//  LexerV1
//
//  Created by James Robinson on 9/9/19.
//

#include <iostream>
#include <sstream>
#include <fstream>
#include "Recognizers.h"

void printTokensInFile(std::ifstream& file);

int main() {
    std::cout << "=== Welcome to RoLexer (V1) ===" << std::endl;
    std::cout << "Enter the name of a file to import (include extension): ";
    
    std::string filename = "";
    std::cin >> filename;
    
    std::ifstream iFS = std::ifstream();
    
    // Open user file
    iFS.open(filename);
    while (!iFS.is_open()) {
        std::cout << "That file could not be opened. Enter another filename: ";
        std::cin >> filename;
        iFS.open(filename);
    }
    
    std::cout << std::endl;
    printTokensInFile(iFS);
    std::cout << std::endl;
    
    iFS.close();
    return 0;
}

// MARK: - Lexing

/// Parses and prints tokens from open stream @c file.
void printTokensInFile(std::ifstream& file) {
    
    // Parse tokens from stream
    int currentLine = 1;
    int tokenCount = 0;
    
    while (!file.eof()) {
        char next = file.peek();
        
        switch (next) {
            case '\n':
            case EOF:
                currentLine += 1;
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
                Token token = OperatorRecognizer().recognizeTokenInStream(file);
                token.setLineNum(currentLine);
                std::cout << token.toString() << std::endl;
                break;
            }
                
            case ':': {
                Token token;
                char colon = file.get();
                
                if (file.peek() == '-') {
                    file.ignore();
                    token = Token(COLON_DASH, ":-", currentLine);
                } else {
                    token = Token(COLON, colon, currentLine);
                }
                
                std::cout << token.toString() << std::endl;
                break;
            }
                
            case '#': {
                Token token = CommentRecognizer().recognizeTokenInStream(file);
                token.setLineNum(currentLine);
                std::cout << token.toString() << std::endl;
                break;
            }
                
            case '\'': {
                Token token = StringRecognizer().recognizeTokenInStream(file);
                token.setLineNum(currentLine);
                std::cout << token.toString() << std::endl;
                break;
            }
                
            default: {
                Token token = IDRecognizer().recognizeTokenInStream(file);
                token.setLineNum(currentLine);
                std::cout << token.toString() << std::endl;
                break;
            }
        }
        
        tokenCount += 1;
    }
    
    Token eof = Token(EOF_T, "", currentLine);
    std::cout << eof.toString() << std::endl;
    tokenCount += 1;
    
    std::cout << "Total Tokens = " << tokenCount << std::endl;
}
