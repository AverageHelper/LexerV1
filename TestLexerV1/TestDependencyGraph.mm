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

+ (nonnull NSString *)testFilesPathInDomain:(nullable NSString *)testDomain {
    return [TestUtils testFilesPathWithFolder:@"Dependency Graph Test Files" inDomain:testDomain];
}


/// Returns the path of a test file with the given @c name from the given @c domain.
- (nonnull NSString *)filePathForTestFileNamed:(nonnull NSString *)testName
                                      inDomain:(nonnull NSString *)testDomain {
    NSString *path = [TestDependencyGraph testFilesPathInDomain:testDomain];    // ex: "100 Bucket"
    path = [path stringByAppendingPathComponent:testName];  // ex: "answer1"
    path = [path stringByAppendingPathExtension:@"txt"];
    
    return path;
}

- (std::ifstream)openInputStreamForTestNamed:(nonnull NSString *)testName
                                    inDomain:(nonnull NSString *)domain {
    NSString *path = [TestDependencyGraph testFilesPathInDomain:domain];
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

// MARK: - Evaluating Datalog

- (void)runFactsFromInputFile:(int)fileNum
                   withPrefix:(nonnull NSString *)prefix
                     inDomain:(nonnull NSString *)fileDomain {
    // Translate integer to string
    NSString *testID = [[NSNumber numberWithInt:fileNum] stringValue];
    return [self runFactsFromInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
}

- (void)runFactsFromInputFileNamed:(nonnull NSString *)testID
                        withPrefix:(nonnull NSString *)prefix
                          inDomain:(nonnull NSString *)fileDomain {
    DatalogProgram* program = [self datalogFromInputFileNamed:testID withPrefix:prefix inDomain:fileDomain];
    XCTAssertNotEqual(program, nullptr, "No valid program from in30.txt");
    if (program == nullptr) {
        return;
    }
    
    Database* database = new Database();
    
    evaluateSchemes(database, program);
    evaluateFacts(database, program);
    std::string output = "";
    output += evaluateRules(database, program, true);
    output += evaluateQueries(database, program, true);
    
    // Write output
    NSString *resultString = [NSString stringWithCString:output.c_str() encoding:NSUTF8StringEncoding];
    resultString = [resultString stringByAppendingString:@"\n"];
    NSURL *testResult = [self writeStringToWorkingDirectory:resultString];
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

// MARK: - Efficient Evaluations

- (void)testBasicTests {
    NSString *domain = @"Basic Tests";
    NSString *prefix = @"in";
    
    [self runFactsFromInputFile:50 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:54 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:55 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:56 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:58 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:59 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:61 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:62 withPrefix:prefix inDomain:domain];
    [self runFactsFromInputFile:64 withPrefix:prefix inDomain:domain];
}

- (void)testExtraTests {
    NSString *domain = @"Extra Tests";
    NSString *prefix = @"in";
    
    [self runFactsFromInputFile:20 withPrefix:prefix inDomain:domain]; // This takes a while
}

- (void)testBetterPerformance {
    NSString *domain = @"Basic Tests";
    NSString *prefix = @"in";
    
    [self measureBlock:^{
        [self runFactsFromInputFile:64 withPrefix:prefix inDomain:domain];
    }];
}

- (void)testLongRunningPerformance {
    NSString *domain = @"Extra Tests";
    NSString *prefix = @"in";
    
    [self measureBlock:^{
        [self runFactsFromInputFile:20 withPrefix:prefix inDomain:domain];
    }];
}

// MARK: - Sructures

- (void)testNode {
    std::vector<std::string> identity = { "1", "2", "3" };
    Rule* r1 = new Rule();
    r1->setHeadPredicate(new Predicate(RULES, "R1")); r1->getHeadPredicate()->setItems(identity);
    
    DependencyGraph::Node node = DependencyGraph::Node(r1);
    XCTAssert(node.getName() == r1->getHeadPredicate()->getIdentifier(), "Wrong name on node.");
    
    XCTAssertEqual(node.getAdjacencies().size(), 0, "Node erroneously reported adjacencies.");
    node.addAdjacency(0, nullptr);
    XCTAssertEqual(node.getAdjacencies().size(), 1, "Failed to add adjacency.");
    
    DependencyGraph::Node copy = node;
    XCTAssert(copy.getName() == node.getName(), "Failed to copy name.");
    XCTAssertEqual(copy.getAdjacencies(), node.getAdjacencies(), "Failed to copy adjacencies.");
    
    node = DependencyGraph::Node(r1);
    copy = node;
    XCTAssert(copy.getName() == node.getName(), "Failed to copy empty name.");
    XCTAssertEqual(copy.getAdjacencies(), node.getAdjacencies(), "Failed to copy empty adjacencies.");
    
    delete r1;
}

- (void)testDependencyGraphOperations {
    DependencyGraph graph = DependencyGraph();
    
    Rule* r1 = new Rule();
    r1->setHeadPredicate(new Predicate(RULES, "R1"));
    std::vector<std::string> identity = { "1", "2", "3" };
    r1->getHeadPredicate()->copyItemsIn(identity);
    
    XCTAssert(graph.addDependency(r1, nullptr), "Graph failed to add dependency, or reported incorrectly.");
    XCTAssert(graph.toString() == "R0:\n", "Graph does not contain dependency, or reported incorrectly.");
    
    Rule* r2 = new Rule();
    r2->setHeadPredicate(new Predicate(RULES, "R2")); r2->getHeadPredicate()->setItems(identity);
    XCTAssert(graph.addDependency(r2, nullptr), "Failed to add dependency.");
    XCTAssert(graph.toString() == "R0:\nR1:\n", "Graph does not contain dependency.");
    
    graph = DependencyGraph();
    XCTAssert(graph.addDependency(r1, r1), "Failed to add dependency.");
    XCTAssertEqual(graph.getNodes().at(0).getAdjacencies().size(), 1, "Graph does not contain dependency.");
    XCTAssertEqual(graph.getNodes().at(0).getAdjacencies().find(0), graph.getNodes().at(0).getAdjacencies().begin(),
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
    
    Rule* r0 = new Rule(); r0->setHeadPredicate(a); r0->setPredicates({ b1, c }); // A(X,Y) :- B(X,Y),C(X,Y).
    XCTAssert(r0->toString() == "A(X,Y) :- B(X,Y),C(X,Y).", "Wrong string for rule.");
    Rule* r1 = new Rule(); r1->setHeadPredicate(b1); r1->setPredicates({ a, d }); // B(X,Y) :- A(X,Y),D(X,Y).
    XCTAssert(r1->toString() == "B(X,Y) :- A(X,Y),D(X,Y).", "Wrong string for rule.");
    Rule* r2 = new Rule(); r2->setHeadPredicate(b1); r2->setPredicates({ b2 }); // B(X,Y) :- B(Y,X).
    XCTAssert(r2->toString() == "B(X,Y) :- B(Y,X).", "Wrong string for rule.");
    Rule* r3 = new Rule(); r3->setHeadPredicate(e); r3->setPredicates({ f, g }); // E(X,Y) :- F(X,Y),G(X,Y).
    XCTAssert(r3->toString() == "E(X,Y) :- F(X,Y),G(X,Y).", "Wrong string for rule.");
    Rule* r4 = new Rule(); r4->setHeadPredicate(e); r4->setPredicates({ e, f }); // E(X,Y) :- E(X,Y),F(X,Y).
    XCTAssert(r4->toString() == "E(X,Y) :- E(X,Y),F(X,Y).", "Wrong string for rule.");
    
    DatalogProgram* program = new DatalogProgram("Prog");
    std::vector<Rule*> rules = { r0, r1, r2, r3, r4 };
    program->setRules(rules);
    
    /* Graph:
     R0: R1 R2
     R1: R0
     R2: R1 R2
     R3:
     R4: R3 R4
     */
    
    DependencyGraph* graph = buildDependencyGraph(program);
    std::string result = graph->toString();
    std::string graphStr = "R0:R1,R2\nR1:R0\nR2:R1,R2\nR3:\nR4:R3,R4\n";
    XCTAssert(result == graphStr, "Built dependencies incorrectly.");
    
    DependencyGraph* reversed = new DependencyGraph(*graph);
    invert(*reversed);
    result = reversed->toString();
    XCTAssert(result != graphStr, "No change after graph invert.");
    
    /* Inverted:
     R0: R1
     R1: R0 R2
     R2: R0 R2
     R3: R4
     R4: R4
     */
    
    graphStr = "R0:R1\nR1:R0,R2\nR2:R0,R2\nR3:R4\nR4:R4\n";
    XCTAssert(result == graphStr, "Inverted graph incorrectly.");
    
    /* Post-order numbers
     R0: 3
     R1: 2
     R2: 1
     R3: 5
     R4: 4
     */
    
    result = reversed->postOrderNumbers();
    graphStr = "R0: 3\nR1: 2\nR2: 1\nR3: 5\nR4: 4\n";
    XCTAssert(result == graphStr, "Incorrect post-order numbers of inverted graph.");
    
    std::vector<std::pair<int, DependencyGraph::Node>> postOrdering = reversed->postOrdering();
    std::vector<std::string> postOrderingStrings = std::vector<std::string>();
    for (auto pair : postOrdering) {
        postOrderingStrings.push_back("R" + std::to_string(pair.first));
    }
    std::vector<std::string> expectedPostOrderingStrings = { "R2", "R1", "R0", "R4", "R3" };
    XCTAssert(postOrderingStrings == expectedPostOrderingStrings, "Wrong post-order ordering returned.");
    
    delete program;
    delete graph;
}

- (void)testStronglyConnectedComponents {
    /*
     A(X,Y) :- B(X,Y), C(X,Y). # R0
     B(X,Y) :- A(X,Y), D(X,Y). # R1
     B(X,Y) :- B(Y,X).         # R2
     E(X,Y) :- F(X,Y), G(X,Y). # R3
     E(X,Y) :- E(X,Y), F(X,Y). # R4
     */
    Predicate* a = new Predicate(RULES, "A"); a->copyItemsIn({ "X", "Y" }); // A(X,Y)
    Predicate* b1 = new Predicate(RULES, "B"); b1->copyItemsIn({ "X", "Y" }); // B(X,Y)
    Predicate* b2 = new Predicate(RULES, "B"); b2->copyItemsIn({ "Y", "X" }); // B(Y,X)
    Predicate* c = new Predicate(RULES, "C"); c->copyItemsIn({ "X", "Y" }); // C(X,Y)
    Predicate* d = new Predicate(RULES, "D"); d->copyItemsIn({ "X", "Y" }); // D(X,Y)
    Predicate* e = new Predicate(RULES, "E"); e->copyItemsIn({ "X", "Y" }); // E(X,Y)
    Predicate* f = new Predicate(RULES, "F"); f->copyItemsIn({ "X", "Y" }); // F(X,Y)
    Predicate* g = new Predicate(RULES, "G"); g->copyItemsIn({ "X", "Y" }); // G(X,Y)
    
    Rule* r0 = new Rule(); r0->setHeadPredicate(a); r0->setPredicates({ b1, c }); // A(X,Y) :- B(X,Y),C(X,Y).
    Rule* r1 = new Rule(); r1->setHeadPredicate(b1); r1->setPredicates({ a, d }); // B(X,Y) :- A(X,Y),D(X,Y).
    Rule* r2 = new Rule(); r2->setHeadPredicate(b1); r2->setPredicates({ b2 }); // B(X,Y) :- B(Y,X).
    Rule* r3 = new Rule(); r3->setHeadPredicate(e); r3->setPredicates({ f, g }); // E(X,Y) :- F(X,Y),G(X,Y).
    Rule* r4 = new Rule(); r4->setHeadPredicate(e); r4->setPredicates({ e, f }); // E(X,Y) :- E(X,Y),F(X,Y).
    
    DatalogProgram* program = new DatalogProgram("Prog");
    std::vector<Rule*> rules = { r0, r1, r2, r3, r4 };
    program->setRules(rules);
    
    /* Graph:
     R0: R1 R2
     R1: R0
     R2: R1 R2
     R3:
     R4: R3 R4
     */
    
    DependencyGraph graph = *buildDependencyGraph(program);
    std::string result = graph.toString();
    std::string graphStr = "R0:R1,R2\nR1:R0\nR2:R1,R2\nR3:\nR4:R3,R4\n";
    XCTAssert(result == graphStr, "Built dependencies incorrectly.");
    
    std::vector<DependencyGraph> components = stronglyConnectedComponentsFromGraph(graph);
    /*
     The first SCC contains only node R3.
     The second SCC contains only node R4.
     The next SCC contains nodes R0, R1, and R2.
     */
    XCTAssertEqual(components.size(), 3, "Wrong number of components returned.");
    if (components.size() == 3) {
        // First SCC
        XCTAssert(components.at(0).getNodes().at(3) == graph.getNodes().at(3),
                  "Wrong component at SCC 1. Expected R3.");
        // Second SCC
        XCTAssert(components.at(1).getNodes().at(4) == graph.getNodes().at(4),
                  "Wrong component at SCC 2. Expected R4.");

        // Third SCC
        XCTAssert(components.at(2).getNodes().at(0) == graph.getNodes().at(0),
                  "Wrong first component at SCC 2. Expected R0.");
        XCTAssert(components.at(2).getNodes().at(1) == graph.getNodes().at(1),
                  "Wrong first component at SCC 2. Expected R1.");
        XCTAssert(components.at(2).getNodes().at(2) == graph.getNodes().at(2),
                  "Wrong first component at SCC 2. Expected R2.");
    }
    
    delete program;
}

- (void)testStronglyConnectedComponentFromMultipleDependentRules {
    /*
     bob(x) :- bob(x). # R0
     bob(x) :- jim(x). # R1
     jim(x) :- bob(x). # R2
     */
    Predicate* bob = new Predicate(RULES, "bob"); bob->copyItemsIn({ "x" }); // bob(x)
    Predicate* jim = new Predicate(RULES, "jim"); jim->copyItemsIn({ "x" }); // jim(x)
    
    Rule* r0 = new Rule(); r0->setHeadPredicate(bob); r0->setPredicates({ bob }); // bob(x) :- bob(x).
    Rule* r1 = new Rule(); r1->setHeadPredicate(bob); r1->setPredicates({ jim }); // bob(x) :- jim(x).
    Rule* r2 = new Rule(); r2->setHeadPredicate(jim); r2->setPredicates({ bob }); // jim(x) :- bob(x).
    
    DatalogProgram* program = new DatalogProgram("Prog");
    std::vector<Rule*> rules = { r0, r1, r2 };
    program->setRules(rules);
    
    /* Graph:
     R0:R0,R1
     R1:R2
     R2:R0,R1
     */
    
    DependencyGraph graph = *buildDependencyGraph(program);
    std::string result = graph.toString();
    std::string graphStr = "R0:R0,R1\nR1:R2\nR2:R0,R1\n";
    XCTAssert(result == graphStr, "Built dependencies incorrectly.");
    
    std::vector<DependencyGraph> components = stronglyConnectedComponentsFromGraph(graph);
    XCTAssertEqual(components.size(), 1, "Wrong number of components returned.");
    if (components.size() == 1) {
        // R0:R0,R1
        XCTAssert(components.at(0).getNodes().at(0) == graph.getNodes().at(0),
                  "Wrong component at SCC. Expected R0.");
        
        bool hasR0R0 = components.at(0).getNodes().at(0).getAdjacencies().find(0) != components.at(0).getNodes().at(0).getAdjacencies().end();
        XCTAssert(hasR0R0, "Expected R0:R0.");
        if (hasR0R0) {
            XCTAssert(components.at(0).getNodes().at(0).getAdjacencies().at(0) == r0,
                      "Expected R0:R0. Got different rule.");
        }
        
        bool hasR0R1 = components.at(0).getNodes().at(0).getAdjacencies().find(1) != components.at(0).getNodes().at(0).getAdjacencies().end();
        XCTAssert(hasR0R1, "Expected R0:R1");
        if (hasR0R1) {
            XCTAssert(components.at(0).getNodes().at(0).getAdjacencies().at(1) == r1,
                      "Expected R0:R1. Got different rule.");
        }
        
        XCTAssert(components.at(0).getNodes().at(1) == graph.getNodes().at(1),
                  "Wrong component at SCC. Expected R1.");
        XCTAssertEqual(components.at(0).getNodes().at(1).getAdjacencies().size(), 1,
                       "Wrong adjacency count for R1.");
        
        XCTAssert(components.at(0).getNodes().at(2) == graph.getNodes().at(2),
                  "Wrong component at SCC. Expected R2.");
        XCTAssertEqual(components.at(0).getNodes().at(2).getAdjacencies().size(), 2,
                       "Wrong adjacency count for R2.");
    }
    
    delete program;
}

@end
