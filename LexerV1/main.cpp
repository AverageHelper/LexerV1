//
//  main.cpp
//  LexerV1
//
//  Created by James Robinson on 9/9/19.
//

#include <iostream>
#include <string>
#include <vector>
#include <sstream>
#include <fstream>

const int MAIN_MENU_IMPORT_FILE = 0;
const int MAIN_MENU_IMPORT_TEXT = 1;

int runStartMenu();
std::string importFile();
std::string importText();
int beginLexing(std::string text);

int main() {
    std::cout << "=== Welcome to RoLexer (V1) ===" << std::endl << std::endl;
    
    std::string userCode = "";
    int option = runStartMenu();
    
    switch (option) {
        case MAIN_MENU_IMPORT_FILE:
            // Import a file
            userCode = importFile();
            break;
            
        case MAIN_MENU_IMPORT_TEXT:
            // Await text input
            userCode = importText();
            break;
            
        default: break;
    }
    
    return beginLexing(userCode);
}

/// Prints the import menu, returning the number of available options.
int printImportMenu() {
    std::cout << "Select an import option:" << std::endl;
    
    std::cout << "(" << MAIN_MENU_IMPORT_FILE << ") Import a file" << std::endl;
    std::cout << "(" << MAIN_MENU_IMPORT_TEXT << ") Enter text" << std::endl;
    
    std::cout << std::endl << "Selection: ";
    
    return 2;
}

/// Prints the main menu to the standard output.
/// Returns the user's selected option. (See the MAIN_MENU constants)
int runStartMenu() {
    int userOption = -1;
    
    const int available = printImportMenu();
    std::cin >> userOption;
    
    while (std::cin.fail() || userOption < 0 || userOption >= available) {
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        std::cout << "Please enter a number between 0 and " << available - 1 << ".";
        
        std::cout << std::endl << std::endl;
        printImportMenu();
        std::cin >> userOption;
    }
    
    return userOption;
}

/// Returns a line from the standard input.
std::string getUserLine() {
    std::string userInput = "";
    
    std::cin.ignore();
    getline(std::cin, userInput);
    
    return userInput;
}

/// Returns the contents of a file whose name the user provides.
std::string importFile() {
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
    
    std::string input = "";
    getline(iFS, input);
    
    // Read contents of file
    while (!iFS.eof()) {
        input += "\n";
        std::string nextLine = "";
        getline(iFS, nextLine);
        input += nextLine;
    }
    iFS.close();
    
    return input;
}

/// Returns a line from the user.
std::string importText() {
    std::cout << "Enter a line of code: " << std::endl;
    
    return getUserLine();
}

/// Performs the bulk of the pattern recognition.
std::vector<std::string> parseTokensFromString(std::string input) {
    std::vector<std::string> result = std::vector<std::string>();
    
    // Find patterns in `input`
    result.push_back(input);
    
    return result;
}

/// Parses tokens from `text`. If successful, returns 0;
int beginLexing(std::string text) {
    std::istringstream stream = std::istringstream(text);
    std::vector<std::string> tokens = std::vector<std::string>();
    
    // Parse tokens from stream
    while (!stream.eof()) {
        std::string blob = "";
        stream >> blob;
        std::vector<std::string> blobTokens = parseTokensFromString(blob);
        for (unsigned int i = 0; i < blobTokens.size(); i += 1) {
            tokens.push_back(blobTokens.at(i));
        }
    }
    
    std::cout << "Found " << tokens.size() << " tokens." << std::endl;
    
    return 0;
}
