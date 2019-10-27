//
//  main.cpp
//  LexerV1
//
//  Created by James Robinson on 9/9/19.
//

#include <iostream>
#include <fstream>
#include "Lexer.h"
#include "Recognizers.h"
#include "DatalogCheck.h"

int main(int argc, char* argv[]) {
    std::string filename = "";
    bool uiLogging = (argc <= 1);
    
    if (uiLogging) {
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
        if (uiLogging) {
            // Try again if user's filename didn't work.
            std::cout << "The file '" << filename
                << "' could not be opened. Enter another filename: ";
            std::cin >> filename;
            iFS.open(filename);
            
        } else {
            // Fail if user's filename didn't work.
            std::cout << "The file '" << filename << "' could not be opened." << std::endl;
            return 0;
        }
    }
    
    // Parse tokens
    std::vector<Token*> tokens = collectedTokensFromFile(iFS);
    iFS.close();
    
//    printTokens(tokens);
//    return 0;
    
    DatalogCheck checker = DatalogCheck();
    checker.debugLogging = true;

    DatalogProgram* result = nullptr;
    result = checker.checkGrammar(tokens);

    if (result != nullptr) {
        std::cout << result->toString() << std::endl;
    }

    if (result != nullptr) {
        delete result;
    }

    // Free our memory.
    releaseTokens(tokens);
    return 0;
}
