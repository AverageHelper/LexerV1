//
//  TestLexer.m
//  TestLexerV1
//
//  Created by James Robinson on 10/25/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <fstream>
#import <vector>
#import <string>
#include "Lexer.h"

@interface TestLexer : XCTestCase

@property (nullable) NSURL *workingURL;

@end

@implementation TestLexer

// MARK: Setup

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.workingURL = [self workingOutputFileURL];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    if (self.workingURL != nil) {
        [self destroyWorkingOutputFileAt:self.workingURL];
    }
}


// MARK: - Utility

- (nonnull NSString *)testFilesPathInDomain:(nullable NSString *)testDomain {
    NSString *path = [NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding];
    path = [path stringByDeletingLastPathComponent];
    path = [path stringByAppendingPathComponent:@"Lexer Test Files"];
    
    if (testDomain != nil) {
        path = [path stringByAppendingPathComponent:testDomain];
    }
    
    return path;
}

- (nullable NSString *)contentsOfFileAtPath:(nonnull NSString *)path {
    NSError *error;
    
    NSString* answerKey =
        [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    XCTAssert(error == nil, @"File read error");
    if (error != nil) {
        NSLog(@"\n\n**File read error**\nFile path: %@", path);
        NSLog(@"Error %@", error);
    }
    
    return answerKey;
}

- (nonnull NSString *)getDiffBetweenFileAtPath:(nonnull NSString *)path1 andPath:(nonnull NSString *)path2 {
    NSTask *diffTask = [[NSTask alloc] init];
    [diffTask setCurrentDirectoryPath:@"~"];
    [diffTask setLaunchPath:@"/usr/bin/diff"];
    [diffTask setArguments:[NSArray arrayWithObjects:path1, path2, nil]];
    
    NSPipe *output = [NSPipe pipe];
    if (output == nil) {
        NSLog(@"Failed to create output pipe for diff command.");
        return @"Failed to create output pipe for diff command.";
    }
    
    [diffTask setStandardOutput:output];
    
    NSError *launchError;
    [diffTask launchAndReturnError:&launchError];
    if (launchError != nil) {
        NSLog(@"Diff command failed with error: %@", launchError);
        return [NSString stringWithFormat:@"%@", launchError];
    }
    
    NSError *readError;
    NSData *diffResult = [[output fileHandleForReading] readDataToEndOfFileAndReturnError:&readError];
    
    if (readError != nil) {
        NSLog(@"Diff output read failed with error: %@", readError);
        return [NSString stringWithFormat:@"%@", readError];
    }
    
    NSString *diff = [[NSString alloc] initWithData:diffResult encoding:NSUTF8StringEncoding];
    if (diff == nil) {
        NSLog(@"Diff output was unreadable in UTF8 encoding.");
        return @"Diff output was unreadable in UTF8 encoding.";
    }
    
    return diff;
}


/// Returns the path of a test file with the given @c name from the given @c domain.
- (nonnull NSString *)filePathForTestFileNamed:(nonnull NSString *)testName inDomain:(nonnull NSString *)testDomain {
    NSString *path = [self testFilesPathInDomain:testDomain];    // ex: "100 Bucket"
    path = [path stringByAppendingPathComponent:testName];  // ex: "answer1"
    path = [path stringByAppendingPathExtension:@"txt"];
    
    return path;
}

- (std::ifstream)openInputStreamForTestNamed:(nonnull NSString *)testName inDomain:(nonnull NSString *)domain {
    NSString *path = [self testFilesPathInDomain:domain];
    path = [path stringByAppendingPathComponent:testName];  // ex: "in10"
    path = [path stringByAppendingPathExtension:@"txt"];
    
    std::ifstream iFS = std::ifstream();
    iFS.open(path.UTF8String);
    
    XCTAssert(iFS.is_open(), @"Could not open file at %@", path);
    if (!iFS.is_open()) {
        NSLog(@"Could not open file at %s", path.UTF8String);
    }
    
    return iFS;
}



// MARK: - Lexer Output

- (void)destroyWorkingOutputFileAt:(nonnull NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *deleteError;
    bool success = [fileManager removeItemAtURL:fileURL error:&deleteError];
    
    if (!success || deleteError != nil) {
        NSLog(@"Failed to remove directory at path %@", fileURL.path);
        XCTAssert(false, "Failed to clean up working directory at path %@", fileURL.path);
    }
}

- (nullable NSURL *)workingOutputFileURL {
    NSUUID *operationID = [NSUUID UUID];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *tmp = [fileManager temporaryDirectory];
    // ...tmp/TestLexer
    NSString *fileName = [NSString stringWithCString:__FILE_NAME__ encoding:NSUTF8StringEncoding];
    fileName = [fileName stringByDeletingPathExtension];
    tmp = [tmp URLByAppendingPathComponent:fileName isDirectory:YES];
    
    NSError *folderCreateError;
    [fileManager createDirectoryAtURL:tmp withIntermediateDirectories:YES attributes:nil error:&folderCreateError];
    if (folderCreateError != nil) {
        NSLog(@"Failed to create output directory at path %@", tmp.path);
        return nil;
    }
    // ...tmp/TestLexer/<UUID>
    tmp = [tmp URLByAppendingPathComponent:operationID.UUIDString isDirectory:false];
    tmp = [tmp URLByAppendingPathExtension:@"txt"];
    
    bool result = [fileManager createFileAtPath:tmp.path contents:nil attributes:nil];
    if (!result) {
        NSLog(@"Failed to create file at path %@", tmp.path);
        return nil;
    }
    
    return tmp;
}

- (nullable NSURL *)writeStringToWorkingDirectory:(nonnull NSString *)string {
    if (self.workingURL == nil) {
        NSLog(@"Unprepared with working URL.");
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

- (void)runLexerOnInputFile:(int)fileNum withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    [self runLexerOnInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
}

- (void)runLexerOnInputFileNamed:(nonnull NSString *)testID withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain {
    NSString *testName = [prefix stringByAppendingString:testID];
    
    std::ifstream iFS = [self openInputStreamForTestNamed:testName inDomain:fileDomain];
    if (!iFS.is_open()) { return; }
    
    std::vector<Token*> tokens = collectedTokensFromFile(iFS);
    iFS.close();
    NSLog(@"Parsed %lu tokens", tokens.size());
    
    std::string tokenString = stringFromTokens(tokens);
    NSString *result = [NSString stringWithUTF8String:tokenString.c_str()];
    
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
    NSString *diff = [self getDiffBetweenFileAtPath:testResult.path andPath:answerKey];
    
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
