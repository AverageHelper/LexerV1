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


// MARK: Utility

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

- (NSString *)getDiffBetweenFileAtPath:(NSString *)path1 andPath:(NSString *)path2 {
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
- (NSString *)filePathForTestFileNamed:(NSString *)testName inDomain:(NSString *)testDomain {
    NSString *path = [self testFilesPathInDomain:testDomain];    // ex: "100 Bucket"
    path = [path stringByAppendingPathComponent:testName];  // ex: "answer1"
    path = [path stringByAppendingPathExtension:@"txt"];
    
    return path;
}

/// Checks that the given program output matches the TA's outfile example.
- (bool)output:(NSString *)output passesTest:(NSString *)testID withSolutionPrefix:(NSString *)prefix inDomain:(NSString *)testDomain {
    NSString *answerDocName = [prefix stringByAppendingString:testID];
    
    NSString *path = [self filePathForTestFileNamed:answerDocName inDomain:testDomain];
    NSLog(@"Path to answer key: %@", path);
    
    NSString* answerKey = [self contentsOfFileAtPath:path];
    
    bool areIdentical = [output isEqualToString:answerKey];
    
    if (!areIdentical) {
        NSLog(@"key: \n%@\nEOF\n", answerKey);
        NSLog(@"output: \n%@\nEOF\n", output);
    }
    
    return areIdentical;
}


- (std::ifstream)openInputStreamForTestNamed:(NSString *)testName inDomain:(NSString *)domain {
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



- (void)testOutputCheck {
    NSString *basicOutput11 = @"(COMMENT,\"# undefined character\",3)\n"
                                "(UNDEFINED,\"@\",5)\n"
                                "(EOF,\"\",8)\n"
                                "Total Tokens = 3";
    
    bool result1 = [self output:basicOutput11 passesTest:@"11" withSolutionPrefix:@"out" inDomain:@"Basic Tests"];
    XCTAssert(result1);
    
    NSString *bigAnswer2 =
    @"(COMMENT,\"# For use ONLY during the Fall 2019 semester\",1)\n"
    "(COMMENT,\"# Copyright Cory Barker, Brigham Young University, August 2019\",2)\n"
    "(UNDEFINED,\"#|\n"
    "\n"
    "############################################################\n"
    "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n"
    "############################################################\n"
    "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n"
    "\n"
    "#|\n"
    "\n"
    "#\n"
    "\",5)\n"
    "(EOF,\"\",15)\n"
    "Total Tokens = 4";
    
    bool result2 = [self output:bigAnswer2 passesTest:@"2" withSolutionPrefix:@"answer" inDomain:@"100 Bucket"];
    XCTAssert(result2);
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

- (nullable NSURL *)writeStringToWorkingDirectory:(NSString *)string {
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


// MARK: - Lexer Tests

- (void)runLexerOnInputFile:(int)fileNum withPrefix:(NSString *)prefix inDomain:(NSString *)fileDomain {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    [self runLexerOnInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
}

- (void)runLexerOnInputFileNamed:(NSString *)testID withPrefix:(NSString *)prefix inDomain:(NSString *)fileDomain {
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

@end
