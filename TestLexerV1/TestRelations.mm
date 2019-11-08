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
    
    XCTAssert(relation.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234" })), "Failed to add tuple.");
    XCTAssert(relation.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678" })), "Failed to add tuple.");
    XCTAssert(relation.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999" })), "Failed to add tuple.");
    XCTAssert(relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" })), "Failed to add tuple.");
    // Intentional duplicate
    XCTAssert(relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" })), "Failed to add tuple.");
    
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

- (void)testRename {
    Relation relation = Relation("R", Tuple({ "A", "B", "C" }));
    
    XCTAssert(relation == *relation.rename("D", "X"),
              "Failed to escape rename gracefully.");
    
    Relation* renamed = relation.rename("A", "X");
    XCTAssertNotEqual(renamed, nullptr);
    XCTAssertEqual(relation.getScheme().at(0), "A");
    XCTAssertEqual(renamed->getScheme().at(0), "X");
    
    delete renamed;
    
    renamed = relation.rename("B", "A");
    XCTAssert(relation == *renamed, "Inadvertently duplicated scheme column.");
    XCTAssertEqual(renamed->getScheme(), Tuple({ "A", "B", "C" }),
                   "Inadvertently duplicated scheme column.");
    
    delete renamed;
    
    renamed = relation.rename("B", "C");
    XCTAssert(relation == *renamed, "Inadvertently duplicated scheme column.");
    XCTAssertEqual(renamed->getScheme(), Tuple({ "A", "B", "C" }),
                   "Inadvertently duplicated scheme column.");
    
    delete renamed;
}

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
    Relation* result = relation.select({ query });
    XCTAssertNotEqual(result, nullptr, "Select operation failed.");
    
    XCTAssertEqual(result->getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result->getContents().size(), 1,
                   "Select operation found %lu results, not 1.", result->getContents().size());
    
    delete result;
    
    
    // One address
    colIfFound = scheme.firstIndexOf("A");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'A' is not in the scheme");
    
    col = static_cast<size_t>(colIfFound);
    query = std::make_pair(col, "12 Apple St."); // σ A='12 Apple St.'
    result = relation.select({ query });
    XCTAssertNotEqual(result, nullptr, "Select operation failed.");
    
    XCTAssertEqual(result->getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result->getContents().size(), 2,
                   "Select operation found %lu results, not 2.", result->getContents().size());
    
    delete result;
    
    
    // Nonexistent address
    query = std::make_pair(col, "42 Wallaby Way"); // σ A='42 Wallaby Way'
    result = relation.select({ query });
    XCTAssertNotEqual(result, nullptr, "Select operation failed.");
    
    XCTAssertEqual(result->getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result->getContents().size(), 0,
                   "Select operation found %lu results, not 0.", result->getContents().size());
    
    delete result;
    
    
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
    XCTAssertNotEqual(result, nullptr, "Select operation failed.");
    
    XCTAssertEqual(result->getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result->getContents().size(), 1,
                   "Select operation found %lu results, not 2.", result->getContents().size());
    
    delete result;
}

- (void)testSelectColumnEquivalence {
    Relation relation = Relation("Loves", Tuple({ "A", "B" }));
    relation.addTuple(Tuple({ "Snoopy", "Snoopy" }));
    relation.addTuple(Tuple({ "Lyra", "Bon Bon" }));
    relation.addTuple(Tuple({ "Bright Mac", "Pear Butter" }));
    relation.addTuple(Tuple({ "Steven Magnet", "Steven Magnet" }));
    
    Tuple scheme = relation.getScheme();
    
    // Name and address
    int colIfFound = scheme.firstIndexOf("A");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'A' is not in the scheme");
    size_t col1 = static_cast<size_t>(colIfFound);
    
    colIfFound = scheme.firstIndexOf("B");
    XCTAssertGreaterThanOrEqual(colIfFound, 0, "'B' is not in the scheme");
    size_t col2 = static_cast<size_t>(colIfFound);
    std::pair<size_t, size_t> colsMatch = std::make_pair(col1, col2); // σ A=B
    
    Relation* result = relation.select({ colsMatch });
    XCTAssertNotEqual(result, nullptr, "Select operation failed.");
    
    XCTAssertEqual(result->getColumnCount(), relation.getColumnCount(),
                   "Schemes do not match.");
    XCTAssertEqual(result->getContents().size(), 2,
                   "Select operation found %lu results, not 2.", result->getContents().size());
    XCTAssertEqual(result->listContents().size(), 2,
                   "List returns wrong results.");
    
    delete result;
}

- (void)testProject {
    Relation relation = Relation("R", Tuple({ "N", "A", "P" }));
    relation.addTuple(Tuple({ "C. Brown", "12 Apple St.", "555-1234" }));
    relation.addTuple(Tuple({ "L. Van Pelt", "34 Pear Ave.", "555-5678" }));
    relation.addTuple(Tuple({ "P. Patty", "56 Grape Blvd.", "555-9999" }));
    relation.addTuple(Tuple({ "Snoopy", "12 Apple St.", "555-1234" }));
    
    Relation* projected = relation.project(Tuple({ "A" }));
    XCTAssertNotEqual(projected, nullptr, "Project operation failed.");
    
    XCTAssertEqual(projected->getScheme(), Tuple({ "A" }), "Wrong scheme after projection.");
    XCTAssertEqual(projected->getColumnCount(), 1, "Wrong number of column safter projection.");
    // There are only 3 unique addresses
    XCTAssertEqual(projected->getContents().size(), 3, "Wrong number of rows after projection.");
    
    for (auto t : projected->getContents()) {
        XCTAssertEqual(t.size(), 1, "Wrong column count in some rows.");
    }
    
    delete projected;
    
    // Test reordering
    projected = relation.project(Tuple({ "P", "A", "N" }));
    XCTAssertEqual(projected->getScheme(), Tuple({ "P", "A", "N" }),
                   "Wrong scheme after projection.");
    XCTAssertEqual(projected->getColumnCount(), relation.getColumnCount(),
                   "Wrong number of column safter projection.");
    XCTAssertEqual(projected->getContents().size(), relation.getContents().size(),
                   "Wrong number of rows after projection.");
    
    // Check that our tuples are ordered properly: if adding the right ones has no effect on
    //     row count, then we have no different columns!
    projected->addTuple(Tuple({ "555-1234", "12 Apple St.", "C. Brown" }));
    projected->addTuple(Tuple({ "555-5678", "34 Pear Ave.", "L. Van Pelt" }));
    projected->addTuple(Tuple({ "555-9999", "56 Grape Blvd.", "P. Patty" }));
    projected->addTuple(Tuple({ "555-1234", "12 Apple St.", "Snoopy" }));
    
    XCTAssertEqual(projected->getContents().size(), relation.getContents().size(),
                   "Wrong rows after projection.");
    
    delete projected;
    
    // Test columns outside of domain
    projected = relation.project(Tuple({ "B", "C", "D" }));
    XCTAssert(projected->getScheme().empty(),
              "Wrong scheme after projection.");
    XCTAssertEqual(projected->getColumnCount(), 0,
                   "Wrong number of columns after projection.");
    XCTAssert(projected->getContents().empty(),
                   "Wrong number of rows after projection.");
    
    delete projected;
    
    projected = relation.project(Tuple());
    XCTAssert(projected->getScheme().empty(),
              "Wrong scheme after projection.");
    XCTAssertEqual(projected->getColumnCount(), 0,
                   "Wrong number of columns after projection.");
    XCTAssert(projected->getContents().empty(),
                   "Wrong number of rows after projection.");
    
    delete projected;
    
    Relation empty = Relation("Empty");
    projected = empty.project(Tuple({ "N", "A", "P" }));
    XCTAssert(projected->getScheme().empty(),
              "Wrong scheme after projection.");
    XCTAssertEqual(projected->getColumnCount(), 0,
                   "Wrong number of columns after projection.");
    XCTAssert(projected->getContents().empty(),
                   "Wrong number of rows after projection.");
    
    delete projected;
    
    // Test duplicate columns
    projected = relation.project(Tuple({ "A", "P", "A", "A" }));
    XCTAssertEqual(projected->getColumnCount(), 2, "Wrong column count after projection.");
    XCTAssertEqual(projected->getContents().size(), 3, "Wrong row count after projection.");
    
    relation.addTuple(Tuple({ "12 Apple St.", "555-1234" }));
    relation.addTuple(Tuple({ "34 Pear Ave.", "555-5678" }));
    relation.addTuple(Tuple({ "56 Grape Blvd.", "555-9999" }));
    relation.addTuple(Tuple({ "12 Apple St.", "555-1234" }));
    
    XCTAssertEqual(projected->getContents().size(), 3,
                   "Wrong rows after projection.");
    
    delete projected;
}

@end
