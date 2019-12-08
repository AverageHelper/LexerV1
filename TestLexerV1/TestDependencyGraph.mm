//
//  TestDependencyGraph.mm
//  TestLexerV1
//
//  Created by James Robinson on 12/5/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "LexerV1.h"

@interface TestDependencyGraph : XCTestCase

@property (nullable) NSURL *workingURL;
@property (nullable) DatalogProgram *program;

@end

@implementation TestDependencyGraph

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
    return [TestUtils testFilesPathWithFolder:@"Dependency Graph Test Files" inDomain:testDomain];
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
    return [self datalogFromInputFileNamed:testID
                               withPrefix:prefix
                                 inDomain:fileDomain
                            expectSuccess:expectSuccess];
}

- (nullable DatalogProgram *)datalogFromInputFileNamed:(nonnull NSString *)testID
                                           withPrefix:(nonnull NSString *)prefix
                                             inDomain:(nonnull NSString *)fileDomain {
    return [self datalogFromInputFileNamed:testID
                               withPrefix:prefix
                                 inDomain:fileDomain
                            expectSuccess:true];
}

- (nullable DatalogProgram *)datalogFromInputFileNamed:(nonnull NSString *)testID
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
    
    return result;
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

// MARK: - Sructures

- (void)testNode {
    DependencyGraph::Node node = DependencyGraph::Node();
    XCTAssert(node.getName() == "nullptr", "Wrong name on empty node.");
    
    Tuple identityTuple = Tuple({ "1", "2", "3" });
    Relation* r1 = new Relation("R1", identityTuple);
    
    node = DependencyGraph::Node(r1);
    XCTAssert(node.getName() == r1->getName(), "Wrong name on node.");
    
    XCTAssertEqual(node.getAdjacencies().size(), 0, "Node erroneously reported adjacencies.");
    node.addAdjacency(0);
    XCTAssertEqual(node.getAdjacencies().size(), 1, "Failed to add adjacency.");
    
    DependencyGraph::Node copy = node;
    XCTAssert(copy.getName() == node.getName(), "Failed to copy name.");
    XCTAssertEqual(copy.getAdjacencies(), node.getAdjacencies(), "Failed to copy adjacencies.");
    
    node = DependencyGraph::Node();
    copy = node;
    XCTAssert(copy.getName() == node.getName(), "Failed to copy empty name.");
    XCTAssertEqual(copy.getAdjacencies(), node.getAdjacencies(), "Failed to copy empty adjacencies.");
    
    delete r1;
}

- (void)testDependencyGraphOperations {
    DependencyGraph graph = DependencyGraph();
    
    Tuple identityTuple = Tuple({ "1", "2", "3" });
    Relation* r1 = new Relation("R1", identityTuple);
    
    XCTAssert(graph.addDependency(r1, nullptr), "Graph failed to add dependency, or reported incorrectly.");
    XCTAssert(graph.toString() == "R0:\n", "Graph does not contain dependency, or reported incorrectly.");
    
    Relation* r2 = new Relation("R2", identityTuple);
    XCTAssert(graph.addDependency(r2, nullptr), "Failed to add dependency.");
    XCTAssert(graph.toString() == "R0:\nR1:\n", "Graph does not contain dependency.");
    
    graph = DependencyGraph();
    XCTAssert(graph.addDependency(r1, r1), "Failed to add dependency.");
    XCTAssertEqual(graph.getGraph().at(0).getAdjacencies().size(), 1, "Graph does not contain dependency.");
    XCTAssertEqual(*graph.getGraph().at(0).getAdjacencies().begin(), 0,
                   "Graph does not contain dependency.");
    XCTAssert(graph.toString() == "R0:R0\n", "Graph reported incorrectly.");
    
    graph = DependencyGraph();
    XCTAssert(graph.addDependency(r1, r2), "Failed to add dependency.");
    XCTAssert(graph.toString() == "R0:R1\nR1:\n", "Graph reported incorrectly.");
    
    graph = DependencyGraph();
    XCTAssert(graph.addDependency(r1, nullptr), "Failed to add dependency.");
    XCTAssert(graph.addDependency(r1, r2), "Failed to add dependency.");
    XCTAssert(graph.addDependency(r2, r2), "Failed to add dependency.");
    XCTAssert(graph.addDependency(r2, r1), "Failed to add dependency.");
    XCTAssert(graph.toString() == "R0:R1\nR1:R0,R1\n", "Graph reported incorrectly.");
    
    delete r1;
}

- (void)testBuildDependencyGraph {
    /*
     A(X,Y) :- B(X,Y), C(X,Y). # R0
     B(X,Y) :- A(X,Y), D(X,Y). # R1
     B(X,Y) :- B(Y,X).         # R2
     E(X,Y) :- F(X,Y), G(X,Y). # R3
     E(X,Y) :- E(X,Y), F(X,Y). # R4
     */
    Predicate* a = new Predicate(RULES, "A"); a->copyItemsIn({ "X", "Y" }); // A(X,Y)
    XCTAssert(a->toString() == "A(X,Y)", "Wrong string for predicate.");
    Predicate* b1 = new Predicate(RULES, "B"); b1->copyItemsIn({ "X", "Y" }); // B(X,Y)
    XCTAssert(b1->toString() == "B(X,Y)", "Wrong string for predicate.");
    Predicate* b2 = new Predicate(RULES, "B"); b2->copyItemsIn({ "Y", "X" }); // B(Y,X)
    XCTAssert(b2->toString() == "B(Y,X)", "Wrong string for predicate.");
    Predicate* c = new Predicate(RULES, "C"); c->copyItemsIn({ "X", "Y" }); // C(X,Y)
    XCTAssert(c->toString() == "C(X,Y)", "Wrong string for predicate.");
    Predicate* d = new Predicate(RULES, "D"); d->copyItemsIn({ "X", "Y" }); // D(X,Y)
    XCTAssert(d->toString() == "D(X,Y)", "Wrong string for predicate.");
    Predicate* e = new Predicate(RULES, "E"); e->copyItemsIn({ "X", "Y" }); // E(X,Y)
    XCTAssert(e->toString() == "E(X,Y)", "Wrong string for predicate.");
    Predicate* f = new Predicate(RULES, "F"); f->copyItemsIn({ "X", "Y" }); // F(X,Y)
    XCTAssert(f->toString() == "F(X,Y)", "Wrong string for predicate.");
    Predicate* g = new Predicate(RULES, "G"); g->copyItemsIn({ "X", "Y" }); // G(X,Y)
    XCTAssert(g->toString() == "G(X,Y)", "Wrong string for predicate.");
    
    Rule r0 = Rule(); r0.setHeadPredicate(a); r0.setPredicates({ b1, c }); // A(X,Y) :- B(X,Y),C(X,Y).
    XCTAssert(r0.toString() == "A(X,Y) :- B(X,Y),C(X,Y).", "Wrong string for rule.");
    Rule r1 = Rule(); r1.setHeadPredicate(b1); r1.setPredicates({ a, d }); // B(X,Y) :- A(X,Y),D(X,Y).
    XCTAssert(r1.toString() == "B(X,Y) :- A(X,Y),D(X,Y).", "Wrong string for rule.");
    Rule r2 = Rule(); r2.setHeadPredicate(b1); r2.setPredicates({ b2 }); // B(X,Y) :- B(Y,X).
    XCTAssert(r2.toString() == "B(X,Y) :- B(Y,X).", "Wrong string for rule.");
    Rule r3 = Rule(); r3.setHeadPredicate(e); r3.setPredicates({ f, g }); // E(X,Y) :- F(X,Y),G(X,Y).
    XCTAssert(r3.toString() == "E(X,Y) :- F(X,Y),G(X,Y).", "Wrong string for rule.");
    Rule r4 = Rule(); r4.setHeadPredicate(e); r4.setPredicates({ e, f }); // E(X,Y) :- E(X,Y),F(X,Y).
    XCTAssert(r4.toString() == "E(X,Y) :- E(X,Y),F(X,Y).", "Wrong string for rule.");
    
    /*
     R0: R1 R2
     R1: R0
     R2: R1 R2
     R3:
     R4: R3 R4
     */
}

@end
