//
//  TestUtils.h
//  TestLexerV1
//
//  Created by James Robinson on 10/30/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestUtils : NSObject

+ (nonnull NSString *)getDiffBetweenFileAtPath:(nonnull NSString *)path1
                                       andPath:(nonnull NSString *)path2;

+ (nullable NSURL *)workingOutputFileURLForTestFileNamed:(nonnull NSString *)fileName;
+ (bool)destroyFileAt:(nonnull NSURL *)fileURL;
+ (nullable NSString *)contentsOfFileAtPath:(nonnull NSString *)path;

+ (nonnull NSString *)testFilesPathWithFolder:(nonnull NSString *)folderName
                                     inDomain:(nullable NSString *)testDomain;

@end

NS_ASSUME_NONNULL_END
