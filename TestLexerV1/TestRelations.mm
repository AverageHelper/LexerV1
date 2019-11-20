//
//  TestRelations.mm
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

@interface TestRelations : XCTestCase

@property (nullable) NSURL *workingURL;
@property (nullable) DatalogProgram *program;

@end

@implementation TestRelations

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
    return [TestUtils testFilesPathWithFolder:@"Relation Test Files" inDomain:testDomain];
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

- (nullable DatalogProgram *)datalogFromInputFile:(int)fileNum
                                       withPrefix:(nonnull NSString *)prefix
                                         inDomain:(nonnull NSString *)fileDomain {
    return [self datalogFromInputFile:fileNum
                           withPrefix:prefix
                             inDomain:fileDomain
                        expectSuccess:true];
}

- (nullable DatalogProgram *)datalogFromInputFile:(int)fileNum
                                       withPrefix:(nonnull NSString *)prefix
                                         inDomain:(nonnull NSString *)fileDomain
                                    expectSuccess:(bool)expectSuccess {
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    return [self datalogForInputFileNamed:testID
                               withPrefix:prefix
                                 inDomain:fileDomain
                            expectSuccess:expectSuccess];
}

- (nullable DatalogProgram *)datalogForInputFileNamed:(nonnull NSString *)testID
                                           withPrefix:(nonnull NSString *)prefix
                                             inDomain:(nonnull NSString *)fileDomain {
    return [self datalogForInputFileNamed:testID
                               withPrefix:prefix
                                 inDomain:fileDomain
                            expectSuccess:true];
}

- (nullable DatalogProgram *)datalogForInputFileNamed:(nonnull NSString *)testID
                                           withPrefix:(nonnull NSString *)prefix
                                             inDomain:(nonnull NSString *)fileDomain
                                        expectSuccess:(bool)expectSuccess {
    std::vector<Token*> tokens = [self tokensFromInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
    
    if (tokens.empty()) {
        XCTAssert(false, "%@%@ in %@ should have at least one token to test on.", prefix, testID, fileDomain);
        return nil;
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
        return nil;
    }
    
    // Write output
    NSString *resultString = [NSString stringWithCString:checker.getResultMsg().c_str() encoding:NSUTF8StringEncoding];
    resultString = [resultString stringByAppendingString:@"\n"];
    NSURL *testResult = [self writeStringToWorkingDirectory:resultString];
    if (testResult == nil) {
        XCTAssert(false, "Failed to write output to test file.");
        return nil;
    }
    
    return result;
    
//    NSString *answerPrefix;
//    if ([prefix isEqualToString:@"in"]) {
//        answerPrefix = @"out";
//    } else {
//        answerPrefix = @"answer";
//    }
//
//    NSString *answerFileName = [answerPrefix stringByAppendingString:testID];
//    NSString *answerKey = [self filePathForTestFileNamed:answerFileName inDomain:fileDomain];
//    NSString *diff = [TestUtils getDiffBetweenFileAtPath:testResult.path andPath:answerKey];
//
//    // Make sure diff comes out empty
//    bool success = [diff isEqualToString:@"\n"] || [diff isEqualToString:@""];
//    if (!success) {
//        NSLog(@"%@", diff);
//    }
//
//    XCTAssert(success, @"diff '%@/%@.txt' returned '%@'", fileDomain, answerFileName, diff);
}

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

//- (void)testDatabaseParse {
//    
//}

// MARK: - Structures

- (void)testTupleInit {
    std::vector<std::string> stuff = { "A", "B", "C" };
    Tuple tuple = Tuple(stuff);
    XCTAssertEqual(tuple.size(), stuff.size(), "Tuple failed to initialize.");
}

- (void)testRelationScheme {
    Relation relation = Relation("R", Tuple({ "A", "B", "C" }));
    XCTAssertEqual(relation.getScheme(), Tuple({ "A", "B", "C" }), "Incorrect scheme.");
    XCTAssertEqual(relation.getColumnCount(), 3, "Wrong column count.");
    
    relation = Relation("R", Tuple({ "N", "A", "P" }));
    XCTAssertEqual(relation.getColumnCount(), 3, "Wrong column count.");
    
    XCTAssert(relation.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234" })), "Wrong size tuple.");
    XCTAssert(relation.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678" })), "Wrong size tuple.");
    XCTAssert(relation.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999" })), "Wrong size tuple.");
    XCTAssert(relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" })), "Wrong size tuple.");
    // Intentional duplicate
    XCTAssert(relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" })), "Wrong size tuple.");
    
    XCTAssertEqual(relation.getContents().size(), 4, "Wrong content size.");
}

- (void)testAddingTuple {
    Relation relation = Relation("R", Tuple({ "A", "B", "C" }));
    Tuple good = Tuple({ "A thing", "Something else", "This guy" });
    XCTAssert(relation.addTuple(good), "Failed to add tuple: wrong column count.");
    XCTAssertEqual(relation.getContents().size(), 1, "Failed to add tuple.");
    
    Tuple tooSmall = Tuple({ "Only one" });
    XCTAssertFalse(relation.addTuple(tooSmall), "Added a too-small tuple.");
    XCTAssertEqual(relation.getContents().size(), 1, "Relation size is incorrect.");
    
    Tuple tooLarge = Tuple({ "one", "two", "three", "four" });
    XCTAssertFalse(relation.addTuple(tooLarge), "Added a too-large tuple.");
    XCTAssertEqual(relation.getContents().size(), 1, "Relation size is incorrect.");
}

- (void)testSchemeImport {
    DatalogProgram* program = [self datalogFromInputFile:5 withPrefix:@"test_case" inDomain:@"100 Bucket"];
    if (program == nullptr) {
        XCTAssertNotEqual(program, nullptr, "100 Bucket/test_case5 returned nil program.");
        return;
    }
    Database* database = new Database();
    
    // Evaluate Schemes
    for (unsigned int schemeIdx = 0; schemeIdx < program->getSchemes().size(); schemeIdx += 1) {
        Predicate* scheme = program->getSchemes().at(schemeIdx);
        std::vector<std::string> titles = scheme->getItems();
        
        Relation* relation = new Relation(scheme->getIdentifier(), scheme->getItems());
        XCTAssertEqual(relation->getScheme().size(), scheme->getItems().size(), "Relation has scheme of %lu elements. Expected %lu.", relation->getScheme().size(), scheme->getItems().size());
        database->addRelation(relation);
    }
    
    XCTAssertEqual(database->getRelations().size(), 3, "Database has wrong number of schemes.");
    
    delete program;
    delete database;
}

- (void)testFactsImport {
    DatalogProgram* program = [self datalogFromInputFile:5 withPrefix:@"test_case" inDomain:@"100 Bucket"];
    if (program == nullptr) {
        XCTAssertNotEqual(program, nullptr, "100 Bucket/test_case5 returned nil program.");
        return;
    }
    Database* database = new Database();
    
    // Evaluate Schemes
    for (unsigned int schemeIdx = 0; schemeIdx < program->getSchemes().size(); schemeIdx += 1) {
        Predicate* scheme = program->getSchemes().at(schemeIdx);
        std::vector<std::string> titles = scheme->getItems();
        
        Relation* relation = new Relation(scheme->getIdentifier(), scheme->getItems());
        database->addRelation(relation);
    }
    
    // Evaluate Facts
    int factsProcessed = 0;
    for (unsigned int factIdx = 0; factIdx < program->getFacts().size(); factIdx += 1) {
        Predicate* fact = program->getFacts().at(factIdx);
        std::vector<std::string> items = fact->getItems();
        
        Relation* relation = database->relationWithName(fact->getIdentifier());
        XCTAssertNotEqual(relation, nullptr, "Relation was nil.");
        
        if (relation != nullptr) {
            Tuple tuple = Tuple(items);
            XCTAssert(relation->addTuple(tuple), "Failed to add tuple: wrong number of elements.");
        }
        XCTAssertFalse(relation->getContents().empty(), "Failed to add tuple.");
        
        factsProcessed += 1;
    }
    
    XCTAssertGreaterThan(factsProcessed, 0, "No facts processed, out of %lu", program->getFacts().size());
    XCTAssertEqual(database->getRelations().size(), 3, "Database has wrong number of schemes.");
    
    delete program;
    delete database;
}

// MARK: - Rename

- (void)testRename {
    Relation relation = Relation("R", Tuple({ "A", "B", "C" }));
    relation.addTuple(Tuple({ "1", "2", "3" }));
    
    // Renaming outside of the domain should do nothing
    XCTAssert(relation == relation.rename("D", "X"),
              "Failed to escape gracefully.");
    
    Relation renamed = relation.rename("A", "X");
    XCTAssertEqual(relation.getScheme().at(0), "A");
    XCTAssertEqual(renamed.getScheme().at(0), "X");
    XCTAssertEqual(relation.getContents().size(), renamed.getContents().size(),
                   "Wrong contents after rename.");
    XCTAssertEqual(relation.listContents().at(0), Tuple({ "1", "2", "3" }),
                   "Wrong contents after rename.");
    
    renamed = relation.rename("C", "X");
    XCTAssertEqual(relation.getScheme().at(2), "C");
    XCTAssertEqual(renamed.getScheme().at(2), "X");
    XCTAssertEqual(relation.getContents().size(), renamed.getContents().size(),
                   "Wrong contents after rename.");
    XCTAssertEqual(relation.listContents().at(0), Tuple({ "1", "2", "3" }),
                   "Wrong contents after rename.");
    
    renamed = relation.rename("B", "A");
    XCTAssert(relation == renamed, "Inadvertently duplicated scheme column.");
    XCTAssertEqual(renamed.getScheme(), Tuple({ "A", "B", "C" }),
                   "Inadvertently duplicated scheme column.");
    XCTAssertEqual(relation.getContents().size(), renamed.getContents().size(),
                   "Wrong contents after rename.");
    XCTAssertEqual(relation.listContents().at(0), Tuple({ "1", "2", "3" }),
                   "Wrong contents after rename.");
    
    renamed = relation.rename("B", "C");
    XCTAssert(relation == renamed, "Inadvertently duplicated scheme column.");
    XCTAssertEqual(renamed.getScheme(), Tuple({ "A", "B", "C" }),
                   "Inadvertently duplicated scheme column.");
    XCTAssertEqual(relation.getContents().size(), renamed.getContents().size(),
                   "Wrong contents after rename.");
    XCTAssertEqual(relation.listContents().at(0), Tuple({ "1", "2", "3" }),
                   "Wrong contents after rename.");
}

// MARK: - Select

- (void)testSelectConstants {
    Relation relation = Relation("R", Tuple({ "N", "A", "P" }));
    relation.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234" }));
    relation.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678" }));
    relation.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999" }));
    relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" }));
    
    Tuple scheme = relation.getScheme();
    
    
    // One name
    int colIfFound = scheme.firstIndexOf("N");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'N' is not in the scheme");
    
    size_t col = static_cast<size_t>(colIfFound);
    std::pair<size_t, std::string> query = std::make_pair(col, "C. Brown"); // σ N='C. Brown'
    Relation result = relation.select({ query });
    
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), 1,
                   "Select operation found %lu results, not 1.", result.getContents().size());
    
    
    // One address
    colIfFound = scheme.firstIndexOf("A");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'A' is not in the scheme");
    
    col = static_cast<size_t>(colIfFound);
    query = std::make_pair(col, "12 Apple St."); // σ A='12 Apple St.'
    result = relation.select({ query });
    
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), 2,
                   "Select operation found %lu results, not 2.", result.getContents().size());
    
    
    // Nonexistent address
    query = std::make_pair(col, "42 Wallaby Way"); // σ A='42 Wallaby Way'
    result = relation.select({ query });
    
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), 0,
                   "Select operation found %lu results, not 0.", result.getContents().size());
    
    
    // Name and address
    colIfFound = scheme.firstIndexOf("N");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'N' is not in the scheme");
    col = static_cast<size_t>(colIfFound);
    std::pair<size_t, std::string> nameQuery = std::make_pair(col, "Snoopy"); // σ N='Snoopy'
    
    colIfFound = scheme.firstIndexOf("P");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'P' is not in the scheme");
    col = static_cast<size_t>(colIfFound);
    std::pair<size_t, std::string> phoneQuery = std::make_pair(col, "555-1234"); // σ P='555-1234'
    
    result = relation.select({ nameQuery, phoneQuery });
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), 1,
                   "Select operation found %lu results, not 2.", result.getContents().size());
    
    // Out of range
    std::pair<size_t, std::string> bigQuery = std::make_pair(3, "Snoopy"); // σ ?='Snoopy'
    result = relation.select({ bigQuery });
    XCTAssert(result == relation, "Bad select made unexpected changes.");
    
    std::pair<size_t, std::string> veryBigQuery = std::make_pair(15, "Snoopy"); // σ ?='Snoopy'
    result = relation.select({ veryBigQuery });
    XCTAssert(result == relation, "Bad select made unexpected changes.");
}

- (void)testSelectColumnEquivalence {
    Relation relation = Relation("Loves", Tuple({ "A", "B" }));
    relation.addTuple(Tuple({ "Snoopy", "Snoopy" }));
    relation.addTuple(Tuple({ "Cranky Doodle", "Matilda" }));
    relation.addTuple(Tuple({ "Bright Mac", "Pear Butter" }));
    relation.addTuple(Tuple({ "Steven Magnet", "Steven Magnet" }));
    
    Tuple scheme = relation.getScheme();
    
    // Loves self
    int colIfFound = scheme.firstIndexOf("A");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'A' is not in the scheme");
    size_t col1 = static_cast<size_t>(colIfFound);
    
    colIfFound = scheme.firstIndexOf("B");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'B' is not in the scheme");
    size_t col2 = static_cast<size_t>(colIfFound);
    
    std::vector<size_t> matchingCols = { col1, col2 }; // σ A=B
    Relation result = relation.select({ matchingCols });
    
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), 2,
                   "Select operation found wrong number of results.");
    XCTAssertEqual(result.listContents().size(), 2,
                   "List returns wrong results.");
    
    // Reverse!
    std::vector<size_t> matchingColsReverse = { col2, col1 }; // σ B=A
    result = relation.select({ matchingColsReverse });
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), 2,
                   "Select operation found wrong number of results.");
    XCTAssertEqual(result.listContents().size(), 2,
                   "List returns wrong results.");
    
    // Same column
    std::vector<size_t> sameCol = { col1, col1 }; // σ A=A
    result = relation.select({ sameCol });
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), relation.getContents().size(),
                   "Select operation found wrong number of results.");
    XCTAssertEqual(result.listContents().size(), relation.listContents().size(),
                   "List returns wrong results.");
    
    // Out of range
    std::vector<size_t> firstlyBigQuery = { 2, 0 }; // σ ?=A
    result = relation.select({ firstlyBigQuery });
    XCTAssert(result == relation, "Bad select made unexpected changes.");
    
    std::vector<size_t> secondlyBigQuery = { 0, 2 }; // σ A=?
    result = relation.select({ secondlyBigQuery });
    XCTAssert(result == relation, "Bad select made unexpected changes.");
    
    std::vector<size_t> veryBigQuery = { 15, 30 }; // σ ?=?
    result = relation.select({ veryBigQuery });
    XCTAssert(result == relation, "Bad select made unexpected changes.");
    
    // From in30
    relation = Relation("SK", Tuple({ "A", "B" }));
    relation.addTuple(Tuple({ "a", "c" }));
    relation.addTuple(Tuple({ "b", "c" }));
    relation.addTuple(Tuple({ "b", "b" }));
    relation.addTuple(Tuple({ "b", "c" }));
    
    std::vector<size_t> matchQuery = { 0, 1 }; // σ A=B
    result = relation.select({ matchQuery });
    XCTAssertEqual(result.getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result.getContents().size(), 1,
                   "Select operation found wrong number of results.");
}

- (void)testSelectMultipleColumnEquivalence {
    Relation relation = Relation("Name", Tuple({ "A", "B", "C", "D" }));
    relation.addTuple(Tuple({ "1", "1", "1", "1" }));
    relation.addTuple(Tuple({ "2", "1", "1", "1" }));
    relation.addTuple(Tuple({ "2", "2", "1", "1" }));
    relation.addTuple(Tuple({ "2", "2", "2", "1" }));
    relation.addTuple(Tuple({ "2", "2", "3", "3" }));
    
    Tuple scheme = relation.getScheme();
    
    // Name(t,t,t,t)?
    std::vector<size_t> allColsMatch = { 0, 1, 2, 3 }; // σ A=B,B=C,C=D
    Relation result = relation.select({ allColsMatch });
    XCTAssertEqual(result.getContents().size(), 1, "Matched wrong number of rows.");
    
    // Name(s,s,s,'1')?
    std::vector<size_t> matchABC = { 0, 1, 2 }; // σ A=B,B=C
    std::pair<size_t, std::string> colVal1 = std::make_pair(3, "1"); // σ D='1'
    result = relation.select({ matchABC });
    result = result.select({ colVal1 });
    XCTAssertEqual(result.getContents().size(), 2, "Matched wrong number of rows.");
    
    // Name('2',t,s,'3')?
    colVal1 = std::make_pair(0, "2"); // σ A='2'
    std::pair<size_t, std::string> colVal2 = std::make_pair(3, "3"); // σ D='3'
    result = relation.select({ colVal1, colVal2 });
    XCTAssertEqual(result.getContents().size(), 1, "Matched wrong number of rows.");
    
    // Name(p,p,q,r)?
    std::vector<size_t> matchAB = { 0, 1 }; // σ A=B
    result = relation.select({ matchAB });
    XCTAssertEqual(result.getContents().size(), 4, "Matched wrong number of rows.");
    
    // Name(p,p,'1',q)?
    colVal1 = std::make_pair(2, "1"); // σ C='1'
    result = relation.select({ matchAB });
    result = result.select({ colVal1 });
    XCTAssertEqual(result.getContents().size(), 2, "Matched wrong number of rows.");
}

// MARK: - Project

- (void)testProject {
    // "The Beta Relation"
    Relation relation = Relation("beta", Tuple({ "cat", "fish", "bird", "bunny" }));
    relation.addTuple(Tuple({ "3", "4", "2", "4" }));
    relation.addTuple(Tuple({ "6", "4", "9", "2" }));
    relation.addTuple(Tuple({ "4", "3", "2", "7" }));
    relation.addTuple(Tuple({ "1", "5", "2", "4" }));
    relation.addTuple(Tuple({ "1", "5", "8", "3" }));
    
    Tuple testScheme = Tuple({ "bunny" });
    Relation projected = relation.project(testScheme); // π 'bunny'
    
    XCTAssertEqual(projected.getScheme(), testScheme, "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), 1, "Wrong number of columns projected.");
    // If adding correct tuples has no effect, then success!
    XCTAssertEqual(projected.getContents().size(), 4, "Wrong number of rows after projection.");
    XCTAssert(projected.addTuple(Tuple({ "4" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "2" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "7" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "3" })), "Wrong size tuple.");
    XCTAssertEqual(projected.getContents().size(), 4, "Wrong number of rows after projection.");
    
    testScheme = Tuple({ "cat", "bird", "bunny" });
    projected = relation.project(testScheme); // π 'cat','bird','bunny'
    
    XCTAssertEqual(projected.getScheme(), testScheme, "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), 3, "Wrong number of columns projected.");
    // Check contents
    XCTAssertEqual(projected.getContents().size(), 5, "Wrong number of rows after projection.");
    XCTAssert(projected.addTuple(Tuple({ "3", "2", "4" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "6", "9", "2" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "4", "2", "7" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "1", "2", "4" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "1", "8", "3" })), "Wrong size tuple.");
    XCTAssertEqual(projected.getContents().size(), 5, "Wrong number of rows after projection.");
    
    // "The Alpha Relation"
    
    relation = Relation("alpha", Tuple({ "cat", "dog", "fish" }));
    relation.addTuple(Tuple({ "1", "2", "5" }));
    relation.addTuple(Tuple({ "1", "4", "1" }));
    relation.addTuple(Tuple({ "2", "3", "2" }));
    relation.addTuple(Tuple({ "6", "7", "4" }));
    
    testScheme = Tuple({ "fish", "dog" });
    projected = relation.project(testScheme); // π 'fish','dog'
    
    XCTAssertEqual(projected.getScheme(), testScheme, "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), 2, "Wrong number of columns projected.");
    // Check contents
    XCTAssertEqual(projected.getContents().size(), 4, "Wrong number of rows after projection.");
    XCTAssert(projected.addTuple(Tuple({ "5", "2" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "1", "4" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "2", "3" })), "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "4", "7" })), "Wrong size tuple.");
    XCTAssertEqual(projected.getContents().size(), 4, "Wrong number of rows after projection.");
    
    // Other relations
    
    relation = Relation("R", Tuple({ "N", "A", "P" }));
    relation.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234" }));
    relation.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678" }));
    relation.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999" }));
    relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" }));
    
    projected = relation.project(Tuple({ "A" }));
    
    XCTAssertEqual(projected.getScheme(), Tuple({ "A" }), "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), 1, "Wrong number of column safter projection.");
    // There are only 3 unique addresses
    XCTAssertEqual(projected.getContents().size(), 3, "Wrong number of rows after projection.");
    
    for (auto t : projected.getContents()) {
        XCTAssertEqual(t.size(), 1, "Wrong column count in some rows.");
    }
    
    // Test reordering
    projected = relation.project(Tuple({ "P", "A", "N" }));
    XCTAssertEqual(projected.getScheme(), Tuple({ "P", "A", "N" }),
                   "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), relation.getColumnCount(),
                   "Wrong number of column safter projection.");
    XCTAssertEqual(projected.getContents().size(), relation.getContents().size(),
                   "Wrong number of rows after projection.");
    
    // Check that our tuples are ordered properly: if adding the right ones has no effect on
    //     row count, then we have no different columns!
    XCTAssert(projected.addTuple(Tuple({ "555-1234", "12 Apple St.", "C. Brown" })),
              "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "555-5678", "34 Pear Ave.", "L. Van Pelt" })),
              "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "555-9999", "56 Grape Blvd.", "P. Patty" })),
              "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "555-1234", "12 Apple St.", "Snoopy" })),
              "Wrong size tuple.");
    
    XCTAssertEqual(projected.getContents().size(), relation.getContents().size(),
                   "Wrong rows after projection.");
    
    // Test columns outside of domain
    projected = relation.project(Tuple({ "B", "C", "D" }));
    XCTAssert(projected.getScheme().empty(),
              "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), 0,
                   "Wrong number of columns after projection.");
    XCTAssert(projected.getContents().empty(),
                   "Wrong number of rows after projection.");
    
    projected = relation.project(Tuple());
    XCTAssert(projected.getScheme().empty(),
              "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), 0,
                   "Wrong number of columns after projection.");
    XCTAssert(projected.getContents().empty(),
                   "Wrong number of rows after projection.");
    
    Relation empty = Relation("Empty");
    projected = empty.project(Tuple({ "N", "A", "P" }));
    XCTAssert(projected.getScheme().empty(),
              "Wrong scheme after projection.");
    XCTAssertEqual(projected.getColumnCount(), 0,
                   "Wrong number of columns after projection.");
    XCTAssert(projected.getContents().empty(),
                   "Wrong number of rows after projection.");
    
    // Test duplicate columns
    projected = relation.project(Tuple({ "A", "P", "A", "A" }));
    XCTAssertEqual(projected.getColumnCount(), 2, "Wrong column count after projection.");
    XCTAssertEqual(projected.getContents().size(), 3, "Wrong row count after projection.");
    
    XCTAssert(projected.addTuple(Tuple({ "12 Apple St.", "555-1234" })),
              "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "34 Pear Ave.", "555-5678" })),
              "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "56 Grape Blvd.", "555-9999" })),
              "Wrong size tuple.");
    XCTAssert(projected.addTuple(Tuple({ "12 Apple St.", "555-1234" })),
              "Wrong size tuple.");
    
    XCTAssertEqual(projected.getContents().size(), 3,
                   "Wrong rows after projection.");
}

- (void)testColumnSwap {
    Relation relation = Relation("R", Tuple({ "N", "A", "P" }));
    relation.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234" }));
    relation.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678" }));
    relation.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999" }));
    relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" }));
    
    Relation* swapped = new Relation(relation);
    swapped->swapColumns(0, 2);
    XCTAssertEqual(swapped->getScheme(), Tuple({ "P", "A", "N" }), "Wrong scheme after swap.");
    
    swapped->addTuple(Tuple({ "555-1234", "12 Apple St.", "C. Brown" }));
    swapped->addTuple(Tuple({ "555-5678", "34 Pear Ave.", "L. Van Pelt" }));
    swapped->addTuple(Tuple({ "555-9999", "56 Grape Blvd.", "P. Patty" }));
    swapped->addTuple(Tuple({ "555-1234", "12 Apple St.", "Snoopy" }));
    
    XCTAssertEqual(swapped->getContents().size(), relation.getContents().size(),
                   "Wrong rows after swap.");
    
    delete swapped;
    
    // One out of range
    swapped = new Relation(relation);
    swapped->swapColumns(0, 3);
    XCTAssertEqual(swapped->getScheme(), Tuple({ "P", "A", "N" }), "Wrong scheme after swap.");
    
    swapped->addTuple(Tuple({ "555-1234", "12 Apple St.", "C. Brown" }));
    swapped->addTuple(Tuple({ "555-5678", "34 Pear Ave.", "L. Van Pelt" }));
    swapped->addTuple(Tuple({ "555-9999", "56 Grape Blvd.", "P. Patty" }));
    swapped->addTuple(Tuple({ "555-1234", "12 Apple St.", "Snoopy" }));
    
    XCTAssertEqual(swapped->getContents().size(), relation.getContents().size(),
                   "Wrong rows after swap.");
    
    delete swapped;
    
    // Both out of range
    swapped = new Relation(relation);
    swapped->swapColumns(4, 3);
    XCTAssertEqual(swapped->getScheme(), relation.getScheme(), "Wrong scheme after swap.");
    XCTAssertEqual(swapped->getContents().size(), relation.getContents().size(),
                   "Wrong rows after swap.");
    
    delete swapped;
}

// MARK: - Join

- (void)testJoinTuples {
    Tuple one = Tuple({ "A", "B", "C" });
    
    Tuple commonCols = Tuple({ "C", "D", "E" });
    Tuple joined = one.combinedWith(commonCols);
    XCTAssertEqual(joined, Tuple({ "A", "B", "C", "D", "E" }), "Failed to join properly.");
    
    Tuple uncommonCols = Tuple({ "D", "E", "F" });
    joined = one.combinedWith(uncommonCols);
    XCTAssertEqual(joined, Tuple({ "A", "B", "C", "D", "E", "F" }), "Failed to join properly.");
}

- (void)testJoinRelationsWithOneCommonColumn {
    Relation relation = Relation("R", Tuple({ "N", "A", "P" }));
    relation.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234" }));
    relation.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678" }));
    relation.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999" }));
    relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" }));
    
    Relation students = Relation("R", Tuple({ "S", "N" }));
    students.addTuple(Tuple({ "1111", "C. Brown" }));
    students.addTuple(Tuple({ "2222", "L. Van Pelt" }));
    students.addTuple(Tuple({ "3333", "P. Patty" }));
    students.addTuple(Tuple({ "4444", "Snoopy" }));
    
    Relation joined = relation.joinedWith(students);
    XCTAssertEqual(joined.getName(), students.getName(), "Name doesn't match.");
    XCTAssertEqual(joined.getColumnCount(), 4, "Wrong number of columns after join.");
    XCTAssertEqual(joined.getScheme(), Tuple({ "N", "A", "P", "S" }), "Wrong scheme after join.");
    
    joined.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234", "1111" }));
    joined.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678", "2222" }));
    joined.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999", "3333" }));
    joined.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234", "4444" }));
    
    XCTAssertEqual(joined.getContents().size(), relation.getContents().size(),
                   "Wrong rows after join.");
}

- (void)testJoinRelationsWithManyCommonColumns {
    Relation relation = Relation("R", Tuple({ "A", "B", "C", "D" }));
    relation.addTuple(Tuple({ "1", "2", "3", "4" }));
    relation.addTuple(Tuple({ "5", "6", "7", "8" }));
    relation.addTuple(Tuple({ "9", "10", "11", "12" }));
    
    Relation identical = Relation("S", Tuple({ "A", "B", "C", "D" }));
    identical.addTuple(Tuple({ "1", "2", "3", "4" }));
    identical.addTuple(Tuple({ "5", "6", "7", "8" }));
    identical.addTuple(Tuple({ "9", "10", "11", "12" }));
    
    XCTAssertEqual(relation.getContents(), identical.getContents(), "Test relations aren't the same.");
    Relation joined = relation.joinedWith(identical);
    XCTAssert(relation == joined, "Joined relations aren't identical.");
    
    Relation partial = Relation("P", Tuple({ "C", "D", "E", "F" }));
    partial.addTuple(Tuple({ "3", "4", "16", "24" }));
    partial.addTuple(Tuple({ "7", "8", "15", "25" }));
    partial.addTuple(Tuple({ "11", "12", "14", "26" }));
    
    joined = relation.joinedWith(partial);
    XCTAssertEqual(joined.getScheme(), Tuple({ "A", "B", "C", "D", "E", "F" }),
                   "Schemes don't match after join.");
    XCTAssertEqual(joined.getContents().size(), relation.getContents().size(),
                   "Contents don't match after join.");
    joined.addTuple(Tuple({ "1", "2", "3", "4", "16", "24" }));
    joined.addTuple(Tuple({ "5", "6", "7", "8", "15", "25" }));
    joined.addTuple(Tuple({ "9", "10", "11", "12", "14", "26" }));
    XCTAssertEqual(joined.getContents().size(), relation.getContents().size(),
                   "Contents differ after join.");
    
    Relation uncommonContents = Relation("P", Tuple({ "C", "D", "E", "F" }));
    uncommonContents.addTuple(Tuple({ "13", "28", "16", "24" }));
    uncommonContents.addTuple(Tuple({ "17", "18", "15", "25" }));
    uncommonContents.addTuple(Tuple({ "111", "112", "14", "26" }));
    
    joined = relation.joinedWith(uncommonContents);
    XCTAssertEqual(joined.getScheme(), Tuple({ "A", "B", "C", "D", "E", "F" }),
                   "Schemes don't match after join.");
    XCTAssertEqual(joined.getContents().size(), 0, "Retains contents after join.");
}

- (void)testJoinRelationsWithNoCommonColumns {
    Relation relation = Relation("R", Tuple({ "A", "B", "C", "D" }));
    relation.addTuple(Tuple({ "1", "2", "3", "4" }));
    relation.addTuple(Tuple({ "5", "6", "7", "8" }));
    relation.addTuple(Tuple({ "9", "10", "11", "12" }));
    
    Relation different = Relation("S", Tuple({ "E", "F", "G" }));
    different.addTuple(Tuple({ "15", "16", "24" }));
    different.addTuple(Tuple({ "17", "18", "28" }));
    different.addTuple(Tuple({ "21", "22", "32" }));
    
    Relation joined = relation.joinedWith(different);
    // Should do a Cartesian product
    XCTAssert(relation != joined, "No change after join.");
    XCTAssertEqual(joined.getScheme(), Tuple({ "A", "B", "C", "D", "E", "F", "G" }));
    XCTAssertEqual(joined.getContents().size(), 9, "Wrong number of tuples after join.");
    
    joined.addTuple(Tuple({ "1", "2", "3", "4", "15", "16", "24" }));
    joined.addTuple(Tuple({ "5", "6", "7", "8", "15", "16", "24" }));
    joined.addTuple(Tuple({ "9", "10", "11", "12", "15", "16", "24" }));
    joined.addTuple(Tuple({ "1", "2", "3", "4", "17", "18", "28" }));
    joined.addTuple(Tuple({ "5", "6", "7", "8", "17", "18", "28" }));
    joined.addTuple(Tuple({ "9", "10", "11", "12", "17", "18", "28" }));
    joined.addTuple(Tuple({ "1", "2", "3", "4", "21", "22", "32" }));
    joined.addTuple(Tuple({ "5", "6", "7", "8", "21", "22", "32" }));
    joined.addTuple(Tuple({ "9", "10", "11", "12", "21", "22", "32" }));
    
    XCTAssertEqual(joined.getContents().size(), 9, "Incorrect tuples after join.");
}

@end
