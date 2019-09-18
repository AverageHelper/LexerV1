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

std::vector<Token*> collectedTokensFromFile(std::ifstream& file);
void printTokens(const std::vector<Token*>& tokens);
void releaseTokens(std::vector<Token*>& tokens);

int main(int argc, char* argv[]) {
    std::string filename = "";
    
    if (argc <= 1) {
        // If user didn't send anything in command line, ask for input.
        std::cout << "=== Welcome to RoLexer (V1) ===" << std::endl;
        std::cout << "Enter the name of a file to tokenize (include extension): ";
        std::cin >> filename;
        
    } else {
        // Silently take input if user passed a filename.
        filename = argv[1];
    }
    
    std::ifstream iFS = std::ifstream();
    
    // Open user file
    iFS.open(filename);
    while (!iFS.is_open()) {
        if (argc <= 1) {
            // Try again if user's filename didn't work.
            std::cout << "The file '" << filename
                << "' could not be opened. Enter another filename: ";
            std::cin >> filename;
            iFS.open(filename);
            
        } else {
            // Fail if user's filename didn't work.
            std::cout << "The file '" << filename << "' could not be opened." << std::endl;
            return 1;
        }
    }
    
    // Parse tokens
    std::vector<Token*> tokens = collectedTokensFromFile(iFS);
    iFS.close();
    
    printTokens(tokens);
    
    // Free our memory.
    releaseTokens(tokens);
    return 0;
}

// MARK: - Lexing

/// Parses tokens in the open @c file stream.
std::vector<Token*> collectedTokensFromFile(std::ifstream& file) {
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
                char colon = file.get();
                
                if (file.peek() == '-') {
                    file.ignore();
                    token = new Token(COLON_DASH, ":-", currentLine);
                } else {
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

/// Prints tokens in the given @c vector.
void printTokens(const std::vector<Token*>& tokens) {
    for (unsigned int i = 0; i < tokens.size(); i += 1) {
        std::cout << tokens.at(i)->toString() << std::endl;
    }
    
    std::cout << "Total Tokens = " << tokens.size() << std::endl;
}

/// Deletes the pointers in @c tokens and clears the vector.
void releaseTokens(std::vector<Token*>& tokens) {
    for (unsigned int i = 0; i < tokens.size(); i += 1) {
        delete tokens.at(i);
    }
    
    tokens.clear();
}
