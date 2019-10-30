//
//  TestLexer.m
//  TestLexerV1
//
//  Created by James Robinson on 10/25/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//
//  Using instructions from
/*  https://hiltmon.com/blog/2019/02/09/testing-c-plus-plus-17-project-in-xcode-with-xctest/
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "LexerV1.h"

@interface TestLexer : XCTestCase

@property (nullable) NSURL *workingURL;

@end

@implementation TestLexer

// MARK: Setup

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *fileName = [NSString stringWithCString:__FILE_NAME__ encoding:NSUTF8StringEncoding];
    self.workingURL = [TestUtils workingOutputFileURLForTestFileNamed:fileName];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    if (self.workingURL != nil) {
        bool success = [TestUtils destroyFileAt:self.workingURL];
        XCTAssert(success, "Failed to clean up working directory at path %@", self.workingURL.path);
    }
}


// MARK: - Utility

- (nonnull NSString *)testFilesPathInDomain:(nullable NSString *)testDomain {
    return [TestUtils testFilesPathWithFolder:@"Lexer Test Files" inDomain:testDomain];
}


/// Returns the path of a test file with the given @c name from the given @c domain.
- (nonnull NSString *)filePathForTestFileNamed:(nonnull NSString *)testName
                                      inDomain:(nonnull NSString *)testDomain {
    NSString *path = [self testFilesPathInDomain:testDomain];    // ex: "100 Bucket"
    path = [path stringByAppendingPathComponent:testName];  // ex: "answer1"
    path = [path stringByAppendingPathExtension:@"txt"];
    
    return path;
}

- (std::ifstream)openInputStreamForTestNamed:(nonnull NSString *)testName
                                    inDomain:(nonnull NSString *)domain {
    NSString *path = [self testFilesPathInDomain:domain];
    path = [path stringByAppendingPathComponent:testName];  // ex: "in10"
    path = [path stringByAppendingPathExtension:@"txt"];
    
    int attempts = 0;
    std::ifstream iFS = std::ifstream();
    
    while (!iFS.is_open() && attempts < 5) {
        iFS.open(path.UTF8String);
        attempts += 1;
    }
    
    XCTAssert(iFS.is_open(), @"After 5 attempts, could not open file at %@: %s", path, strerror(errno));
    
    return iFS;
}



// MARK: - Lexer Output

- (nullable NSURL *)writeStringToWorkingDirectory:(nonnull NSString *)string {
    if (self.workingURL == nil) {
        NSLog(@"Unprepared with working URL.");
        XCTAssert(false, "Unprepared with working URL.");
        return nil;
    }
    
    NSError *writeError;
    [string writeToURL:self.workingURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];

    if (writeError != nil) {
        NSLog(@"String write failed to path %@, error: %@", self.workingURL.path, writeError);
        return nil;
    }
    
    return self.workingURL;
}


// MARK: - Major Tests

- (void)runLexerOnInputFile:(int)fileNum withPrefix:(nonnull NSString *)prefix
                   inDomain:(nonnull NSString *)fileDomain {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    return [self runLexerOnInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
}

- (void)runLexerOnInputFileNamed:(nonnull NSString *)testID
                      withPrefix:(nonnull NSString *)prefix
                        inDomain:(nonnull NSString *)fileDomain {
    NSString *testName = [prefix stringByAppendingString:testID];
    
    std::ifstream iFS = [self openInputStreamForTestNamed:testName inDomain:fileDomain];
    if (!iFS.is_open()) { return; }
    
    std::vector<Token*> tokens = collectedTokensFromFile(iFS);
    iFS.close();
    NSLog(@"Parsed %lu tokens", tokens.size());
    
    std::string tokenString = stringFromTokens(tokens);
    NSString *result = [NSString stringWithUTF8String:tokenString.c_str()];
    
    releaseTokens(tokens);
    
    // Write output
    NSURL *testResult = [self writeStringToWorkingDirectory:result];
    if (testResult == nil) {
        XCTAssert(false, "Failed to write output to test file.");
        return;
    }
    
    NSString *answerPrefix;
    if ([prefix isEqualToString:@"in"]) {
        answerPrefix = @"out";
    } else {
        answerPrefix = @"answer";
    }
    
    NSString *answerFileName = [answerPrefix stringByAppendingString:testID];
    NSString *answerKey = [self filePathForTestFileNamed:answerFileName inDomain:fileDomain];
    NSString *diff = [TestUtils getDiffBetweenFileAtPath:testResult.path andPath:answerKey];
    
    // Make sure diff comes out empty
    bool success = [diff isEqualToString:@"\n"] || [diff isEqualToString:@""];
    if (!success) {
        NSLog(@"%@", diff);
    }
    
    XCTAssert(success, @"diff '%@/%@.txt' returned '%@'", fileDomain, answerFileName, diff);
}


- (void)testBasicTests {
    NSString *domain = @"Basic Tests";
    
    for (int testNum = 10; testNum <= 20; testNum++) {
        [self runLexerOnInputFile:testNum withPrefix:@"in" inDomain:domain];
    }
    
    for (int testNum = 61; testNum <= 62; testNum++) {
        [self runLexerOnInputFile:testNum withPrefix:@"in" inDomain:domain];
    }
}

- (void)test70Bucket {
    NSString *domain = @"70 Bucket";
    [self runLexerOnInputFile:1 withPrefix:@"test_case" inDomain:domain];
    for (int testNum = 3; testNum <= 7; testNum++) {
        [self runLexerOnInputFile:testNum withPrefix:@"test_case" inDomain:domain];
    }
    [self runLexerOnInputFileNamed:@"noway" withPrefix:@"test_case" inDomain:domain];
}

- (void)test90Bucket {
    NSString *domain = @"90 Bucket";
    for (int testNum = 1; testNum <= 3; testNum++) {
        [self runLexerOnInputFile:testNum withPrefix:@"test_case" inDomain:domain];
    }
}

- (void)test100Bucket {
    NSString *domain = @"100 Bucket";
    [self runLexerOnInputFile:1 withPrefix:@"test_case" inDomain:domain];
    [self runLexerOnInputFile:2 withPrefix:@"test_case" inDomain:domain];
}

- (void)testLexerPerformance {
    [self measureBlock:^{
        [self runLexerOnInputFile:1 withPrefix:@"test_case" inDomain:@"100 Bucket"];
    }];
}

// MARK: Minor Tests

- (void)testIdentifiers {
    std::istringstream input = std::istringstream("three identifiers here WithSomeWe1rdValu3s");
    while (!input.eof()) {
        if (input.peek() == ' ') {
            input.ignore();
        }
        Token* result = IDRecognizer().recognizeTokenInStream(input);
        XCTAssert(result->getType() == ID,
                  @"Type of '%s' was %s", result->getValue().c_str(), stringForTokenType(result->getType()).c_str());
        delete result;
    }
    
    input.str("0this 9is _invalid for_a_string");
    while (!input.eof()) {
        if (input.peek() == ' ') {
            input.ignore();
        }
        Token* result = IDRecognizer().recognizeTokenInStream(input);
        XCTAssert(result->getType() == UNDEFINED,
                  @"Type of '%s' was %s", result->getValue().c_str(), stringForTokenType(result->getType()).c_str());
        delete result;
    }
}

- (void)testStrings {
    std::istringstream input =
        std::istringstream("'these' 'should ' ' all' 'be' 'SWwfet tein wer ' 'It''s dead, Jim!'");
    NSMutableArray *validStrings = [NSMutableArray array];
    
    while (!input.eof()) {
        Token* result = StringRecognizer(nullptr).recognizeTokenInStream(input);
        
        // Ignore undefined single-space tokens
        if (result->getType() == UNDEFINED &&
            result->getValue() == " ") {
            delete result;
            continue;
        }
        XCTAssertEqual(result->getType(), STRING,
                       @"Type of '%s' was %s", result->getValue().c_str(), stringForTokenType(result->getType()).c_str());
        if (result->getType() == STRING) {
            NSString *value = [NSString stringWithCString:result->getValue().c_str() encoding:NSUTF8StringEncoding];
            [validStrings addObject:value];
        } else {
            NSLog(@"Incorrect token type: %s", result->toString().c_str());
        }
        delete result;
    }
    
    NSMutableString *joinedResults = [NSMutableString string];
    for (NSString *result in validStrings) {
        [joinedResults appendString:result];
        [joinedResults appendString:@"\n"];
    }
    
    XCTAssertEqual(validStrings.count, 6, "%@", joinedResults);
    
    
    input.str("invalid strings ");
    while (!input.eof()) {
        if (input.peek() == ' ') {
            input.ignore();
        }
        Token* result = StringRecognizer(nullptr).recognizeTokenInStream(input);
        XCTAssert(result->getType() == UNDEFINED,
                  @"Type of '%s' was %s", result->getValue().c_str(), stringForTokenType(result->getType()).c_str());
        delete result;
    }
}

- (void)testComments {
    std::istringstream input =
        std::istringstream("#| comment |# #||# # all of the comments");
    NSMutableArray *validComments = [NSMutableArray array];
    
    while (!input.eof()) {
        Token* result = CommentRecognizer(nullptr).recognizeTokenInStream(input);
        
        // Ignore undefined single-space tokens
        if (result->getType() == UNDEFINED &&
            result->getValue() == " ") {
            delete result;
            continue;
        }
        
        XCTAssertEqual(result->getType(), COMMENT,
                       @"Type of '%s' was %s", result->getValue().c_str(), stringForTokenType(result->getType()).c_str());
        if (result->getType() == COMMENT) {
            NSString *value = [NSString stringWithCString:result->getValue().c_str() encoding:NSUTF8StringEncoding];
            [validComments addObject:value];
        } else {
            NSLog(@"Incorrect token type: %s", result->toString().c_str());
        }
        delete result;
    }
    
    NSMutableString *joinedResults = [NSMutableString string];
    for (NSString *result in validComments) {
        [joinedResults appendString:result];
        [joinedResults appendString:@"\n"];
    }
    
    XCTAssertEqual(validComments.count, 3, "%@", joinedResults);
    
    
    input.str("invalid comments #|are here");
    while (!input.eof()) {
        if (input.peek() == ' ') {
            input.ignore();
        }
        Token* result = CommentRecognizer(nullptr).recognizeTokenInStream(input);
        XCTAssert(result->getType() == UNDEFINED,
                  @"Type of '%s' was %s", result->getValue().c_str(), stringForTokenType(result->getType()).c_str());
        delete result;
    }
}

@end
