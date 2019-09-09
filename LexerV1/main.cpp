//
//  main.cpp
//  LexerV1
//
//  Created by James Robinson on 9/9/19.
//

#include <iostream>
#include <string>
#include <sstream>
#include <fstream>

const int MAIN_MENU_IMPORT_FILE = 0;
const int MAIN_MENU_IMPORT_TEXT = 1;
const std::string ERROR_CRIT_FAIL = "ERROR_CRIT_FAIL";

int runStartMenu();
std::string importFile();
std::string importText();
int beginLexing(std::string text);

int main() {
    std::cout << "Hello, World!" << std::endl << std::endl;
    
    std::string userCode = "";
    int option = runStartMenu();
    
    switch (option) {
        case MAIN_MENU_IMPORT_FILE:
            // Import a file
            userCode = importFile();
            if (userCode == ERROR_CRIT_FAIL) {
                std::cout << "That file could not be opened." << std::endl;
            }
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

std::string getUserLine() {
    std::string userInput = "";
    
    std::cin.ignore();
    getline(std::cin, userInput);
    
    return userInput;
}

std::string importFile() {
    std::cout << "Enter the name of a file to import (include extension): ";
    
    std::string filename = "";
    std::cin >> filename;
    
    std::ifstream iFS = std::ifstream();
    
    // Open user file
    iFS.open(filename);
    if (!iFS.is_open()) {
        return ERROR_CRIT_FAIL;
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

std::string importText() {
    std::cout << "Enter a line of code: " << std::endl;
    
    return getUserLine();
}

int beginLexing(std::string text) {
//    std::ostringstream stream = std::ostringstream(text);
    
    std::cout << text << std::endl;
    
    return 0;
}
