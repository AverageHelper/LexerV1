//
//  TestUtils.m
//  TestLexerV1
//
//  Created by James Robinson on 10/30/19.
//  Copyright © 2019 James Robinson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestUtils.h"

@implementation TestUtils

+ (nonnull NSString *)getDiffBetweenFileAtPath:(nonnull NSString *)path1
                                       andPath:(nonnull NSString *)path2 {
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

+ (nullable NSURL *)workingOutputFileURLForTestFileNamed:(nonnull NSString *)fileName {
    NSUUID *operationID = [NSUUID UUID];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *tmp = [fileManager temporaryDirectory];
    
    // ...tmp/TestGrammar
    fileName = [fileName stringByDeletingPathExtension];
    tmp = [tmp URLByAppendingPathComponent:fileName isDirectory:YES];
    
    NSError *folderCreateError;
    [fileManager createDirectoryAtURL:tmp withIntermediateDirectories:YES attributes:nil error:&folderCreateError];
    if (folderCreateError != nil) {
        NSLog(@"Failed to create output directory at path %@", tmp.path);
        return nil;
    }
    // ...tmp/TestGrammar/<UUID>
    tmp = [tmp URLByAppendingPathComponent:operationID.UUIDString isDirectory:false];
    tmp = [tmp URLByAppendingPathExtension:@"txt"];
    
    bool result = [fileManager createFileAtPath:tmp.path contents:nil attributes:nil];
    if (!result) {
        NSLog(@"Failed to create file at path %@", tmp.path);
        return nil;
    }
    
    return tmp;
}

+ (bool)destroyFileAt:(nonnull NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *deleteError;
    bool success = [fileManager removeItemAtURL:fileURL error:&deleteError];
    
    if (!success || deleteError != nil) {
        NSLog(@"Failed to remove directory at path %@", fileURL.path);
        return false;
    }
    
    return true;
}

+ (nullable NSString *)contentsOfFileAtPath:(nonnull NSString *)path {
    NSError *error;
    
    NSString* answerKey =
        [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if (error != nil) {
        NSLog(@"\n\n**File read error**\nFile path: %@", path);
        NSLog(@"Error %@", error);
    }
    
    return answerKey;
}

/// Ex: .../TextLexerV1/<folder name>/<test domain?>
+ (nonnull NSString *)testFilesPathWithFolder:(nonnull NSString *)folderName
                                     inDomain:(nullable NSString *)testDomain {
    NSString *path = [NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding];
    path = [path stringByDeletingLastPathComponent];
    path = [path stringByAppendingPathComponent:folderName];
    
    if (testDomain != nil) {
        path = [path stringByAppendingPathComponent:testDomain];
    }
    
    return path;
}

@end
