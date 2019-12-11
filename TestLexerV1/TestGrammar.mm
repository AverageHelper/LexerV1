//
//  TestGrammar.mm
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

+(void)tearDown {
    NSString *fileName = [NSString stringWithCString:__FILE_NAME__ encoding:NSUTF8StringEncoding];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *tmp = [fileManager temporaryDirectory];
    
    // ...tmp/TestDependencyGraph
    fileName = [fileName stringByDeletingPathExtension];
    tmp = [tmp URLByAppendingPathComponent:fileName isDirectory:YES];
    
    [TestUtils destroyFileAt:tmp];
}

// MARK: - Utility

- (nonnull NSString *)testFilesPathInDomain:(nullable NSString *)testDomain {
    return [TestUtils testFilesPathWithFolder:@"Grammar Test Files" inDomain:testDomain];
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

// MARK: - Grammar Output

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

- (void)releaseAllTokensInVector:(std::vector<Token*>)tokens {
    for (unsigned int i = 0; i < tokens.size(); i += 1) {
        delete tokens.at(i);
    }
}

- (std::vector<Token*>)tokensFromInputFile:(int)fileNum
                                withPrefix:(nonnull NSString *)prefix
                                  inDomain:(nonnull NSString *)fileDomain {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    return [self tokensFromInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
}

- (std::vector<Token*>)tokensFromInputFileNamed:(nonnull NSString *)testID
                                     withPrefix:(nonnull NSString *)prefix
                                       inDomain:(nonnull NSString *)fileDomain {
    NSString *testName = [prefix stringByAppendingString:testID];
    
    std::ifstream iFS = [self openInputStreamForTestNamed:testName inDomain:fileDomain];
    if (!iFS.is_open()) { return std::vector<Token*>(); }
    
    std::vector<Token*> tokens = collectedTokensFromFile(iFS);
    iFS.close();
    NSLog(@"Parsed %lu tokens", tokens.size());
    
    return tokens;
}

- (void)runDatalogOnInputFile:(int)fileNum
                   withPrefix:(nonnull NSString *)prefix
                     inDomain:(nonnull NSString *)fileDomain {
    return [self runDatalogOnInputFile:fileNum
                            withPrefix:prefix
                              inDomain:fileDomain
                         expectSuccess:true];
}

- (void)runDatalogOnInputFile:(int)fileNum
                   withPrefix:(nonnull NSString *)prefix
                     inDomain:(nonnull NSString *)fileDomain
                expectSuccess:(bool)expectSuccess {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    return [self runDatalogOnInputFileNamed:testID
                                 withPrefix:prefix
                                   inDomain:fileDomain
                              expectSuccess:expectSuccess];
}

- (void)runDatalogOnInputFileNamed:(nonnull NSString *)testID
                        withPrefix:(nonnull NSString *)prefix
                          inDomain:(nonnull NSString *)fileDomain {
    return [self runDatalogOnInputFileNamed:testID
                                 withPrefix:prefix
                                   inDomain:fileDomain
                              expectSuccess:true];
}

- (void)runDatalogOnInputFileNamed:(nonnull NSString *)testID
                        withPrefix:(nonnull NSString *)prefix
                          inDomain:(nonnull NSString *)fileDomain
                     expectSuccess:(bool)expectSuccess {
    std::vector<Token*> tokens = [self tokensFromInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
    
    if (tokens.empty()) {
        XCTAssert(false, "%@%@ in %@ should have at least one token to test on.", prefix, testID, fileDomain);
        return;
    }
    
    DatalogCheck checker = DatalogCheck();
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
    NSString *resultString = [NSString stringWithCString:checker.getResultMsg().c_str() encoding:NSUTF8StringEncoding];
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
    NSString *diff = [TestUtils getDiffBetweenFileAtPath:testResult.path andPath:answerKey];
    
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

- (void)testIdentifier {
    DatalogProgram program = DatalogProgram();
    std::string identifier = "This is me!";
    program.setIdentifier(identifier);
    XCTAssertEqual(program.getIdentifier(), identifier);
}

- (void)testProgramSetters {
    DatalogProgram program = DatalogProgram();
    
    Predicate* scheme = new Predicate(UNDEFINED, "A scheme.");
    Predicate* fact = new Predicate(UNDEFINED, "A fact.");
    Rule* rule = new Rule();
    Predicate* query = new Predicate(UNDEFINED, "A query.");
    
    XCTAssertEqual(program.addScheme(scheme), 1, "Failed to add scheme.");
    XCTAssertEqual(program.getSchemes().size(), 1, "Program has wrong scheme count.");
    
    XCTAssertEqual(program.addFact(fact), 1, "Failed to add fact.");
    XCTAssertEqual(program.getFacts().size(), 1, "Program has wrong fact count.");
    
    XCTAssertEqual(program.addRule(rule), 1, "Failed to add rule.");
    XCTAssertEqual(program.getRules().size(), 1, "Program has wrong rule count.");
    
    XCTAssertEqual(program.addQuery(query), 1, "Failed to add query.");
    XCTAssertEqual(program.getQueries().size(), 1, "Program has wrong query count.");
    
    // DatalogProgram deconstructor should deallocate its children.
}

- (void)testPredicate {
    Rule rule = Rule();
    Predicate* predicate = new Predicate(UNDEFINED, "A predicate.");
    
    XCTAssertEqual(predicate->getType(), UNDEFINED, "Wrong type on predicate.");
    predicate->setType(STRING);
    XCTAssertEqual(predicate->getType(), STRING, "Wrong predicate type after setter.");
    
    predicate->addItem("A");
    predicate->addItem("B");
    XCTAssertEqual(predicate->getItems().size(), 2, "Failed to add two items to predicate.");
    
    XCTAssertEqual(rule.addPredicate(predicate), 1, "Failed to add predicate.");
    XCTAssertEqual(rule.getPredicates().size(), 1, "Failed to add predicate.");
    
    // Rule deletes its predicates.
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
