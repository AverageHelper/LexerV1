//
//  TestDatalogProgram.m.
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

@interface TestGrammar : XCTestCase

@property (nullable) NSURL *workingURL;

@end

@implementation TestGrammar

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
    path = [path stringByAppendingPathComponent:@"Grammar Test Files"];
    
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
    
    int attempts = 0;
    std::ifstream iFS = std::ifstream();
    
    while (!iFS.is_open() && attempts < 5) {
        iFS.open(path.UTF8String);
        attempts += 1;
    }
    
    XCTAssert(iFS.is_open(), @"After 5 attempts, could not open file at %@: %s", path, strerror(errno));
    
    return iFS;
}

// MARK: - Grammar Output

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

- (void)releaseAllTokensInVector:(std::vector<Token*>)tokens {
    for (unsigned int i = 0; i < tokens.size(); i += 1) {
        delete tokens.at(i);
    }
}

- (std::vector<Token*>)tokensFromInputFile:(int)fileNum withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    return [self tokensFromInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
}

- (std::vector<Token*>)tokensFromInputFileNamed:(nonnull NSString *)testID withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain {
    NSString *testName = [prefix stringByAppendingString:testID];
    
    std::ifstream iFS = [self openInputStreamForTestNamed:testName inDomain:fileDomain];
    if (!iFS.is_open()) { return std::vector<Token*>(); }
    
    std::vector<Token*> tokens = collectedTokensFromFile(iFS);
    iFS.close();
    NSLog(@"Parsed %lu tokens", tokens.size());
    
    return tokens;
}

- (void)runDatalogOnInputFile:(int)fileNum withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain {
    return [self runDatalogOnInputFile:fileNum
                            withPrefix:prefix
                              inDomain:fileDomain
                         expectSuccess:true];
}

- (void)runDatalogOnInputFile:(int)fileNum withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain expectSuccess:(bool)expectSuccess {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    return [self runDatalogOnInputFileNamed:testID
                                 withPrefix:prefix
                                   inDomain:fileDomain
                              expectSuccess:expectSuccess];
}

- (void)runDatalogOnInputFileNamed:(nonnull NSString *)testID withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain {
    return [self runDatalogOnInputFileNamed:testID
                                 withPrefix:prefix
                                   inDomain:fileDomain
                              expectSuccess:true];
}

- (void)runDatalogOnInputFileNamed:(nonnull NSString *)testID withPrefix:(nonnull NSString *)prefix inDomain:(nonnull NSString *)fileDomain expectSuccess:(bool)expectSuccess {
    std::vector<Token*> tokens = [self tokensFromInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
    
    if (tokens.empty()) {
        XCTAssert(false, "%@%@ in %@ should have at least one token to test on.", prefix, testID, fileDomain);
        return;
    }
    
    DatalogCheck checker = DatalogCheck();
    checker.debugLogging = true;
    DatalogProgram* result = nullptr;
    result = checker.checkGrammar(tokens);
    
    if (expectSuccess) {
        XCTAssertNotEqual(result, nullptr, "Expected datalog program for test %@%@ in %@", prefix, testID, fileDomain);
    } else {
        XCTAssertEqual(result, nullptr, "Expected nullptr for test %@%@ in %@", prefix, testID, fileDomain);
    }
    
    [self releaseAllTokensInVector:tokens];
    
    if (result == nullptr) {
        return;
    }
    
    // Write output
    NSString *resultString = [NSString stringWithCString:result->toString().c_str() encoding:NSUTF8StringEncoding];
    // FIXME: This is fake. Need somehow to get program output, or rewrite program to deliver output differently.
    resultString = [@"Success!\n" stringByAppendingString:resultString];
    resultString = [resultString stringByAppendingString:@"\n"];
    NSURL *testResult = [self writeStringToWorkingDirectory:resultString];
    if (testResult == nil) {
        XCTAssert(false, "Failed to write output to test file.");
        return;
    }
    
    if (result != nullptr) {
        delete result;
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

- (void)testDatalogCheckWithGoodInput {
    NSString *domain = @"Basic Tests";
    
    [self runDatalogOnInputFile:21 withPrefix:@"in" inDomain:domain];
    [self runDatalogOnInputFile:26 withPrefix:@"in" inDomain:domain];
    [self runDatalogOnInputFile:29 withPrefix:@"in" inDomain:domain];
    [self runDatalogOnInputFile:61 withPrefix:@"in" inDomain:domain];
    [self runDatalogOnInputFile:62 withPrefix:@"in" inDomain:domain];
}

- (void)testDatalogCheckWithBadInput {
    NSString *domain = @"Basic Tests";
    
    for (int testNum = 22; testNum <= 25; testNum += 1) {
//        NSLog(@"%@ TestNum: %i", domain, testNum);
        [self runDatalogOnInputFile:testNum withPrefix:@"in" inDomain:domain expectSuccess:false];
    }
    [self runDatalogOnInputFile:27 withPrefix:@"in" inDomain:domain expectSuccess:false];
    [self runDatalogOnInputFile:28 withPrefix:@"in" inDomain:domain expectSuccess:false];
}

- (void)test80Bucket {
    NSString *domain = @"80 Bucket";
    NSString *prefix = @"test_case";
    
    // Good input
    [self runDatalogOnInputFile:0 withPrefix:prefix inDomain:domain];
    [self runDatalogOnInputFile:4 withPrefix:prefix inDomain:domain];
    [self runDatalogOnInputFile:5 withPrefix:prefix inDomain:domain];
    
    // Bad input
    for (int testNum = 1; testNum <= 3; testNum += 1) {
        [self runDatalogOnInputFile:testNum withPrefix:prefix inDomain:domain expectSuccess:false];
    }
    for (int testNum = 6; testNum <= 8; testNum += 1) {
        [self runDatalogOnInputFile:testNum withPrefix:prefix inDomain:domain expectSuccess:false];
    }
}

- (void)test100Bucket {
    NSString *domain = @"100 Bucket";
    NSString *prefix = @"test_case";
    
    // Good input
    [self runDatalogOnInputFile:0 withPrefix:prefix inDomain:domain];
    [self runDatalogOnInputFile:1 withPrefix:prefix inDomain:domain];
    
    // Bad input
    [self runDatalogOnInputFile:2 withPrefix:prefix inDomain:domain expectSuccess:false];
}

- (void)testDatalogCheckRaceLogging {
    [self measureBlock:^{
        for (int testNum = 22; testNum <= 25; testNum += 1) {
            NSLog(@"Basic Tests TestNum: %i", testNum); // This line seems to fix a tester race condition...
            [self runDatalogOnInputFile:testNum withPrefix:@"in" inDomain:@"Basic Tests" expectSuccess:false];
        }
    }];
}

- (void)testDatalogCheckRaceSansLogging {
    [self measureBlock:^{
        for (int testNum = 22; testNum <= 25; testNum += 1) {
            [self runDatalogOnInputFile:testNum withPrefix:@"in" inDomain:@"Basic Tests" expectSuccess:false];
        }
    }];
}

- (void)testDatalogPerformance {
    [self measureBlock:^{
        [self runDatalogOnInputFile:61 withPrefix:@"in" inDomain:@"Basic Tests"];
    }];
}

@end
