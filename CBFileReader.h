//
//  CBFileReader.h
//  CrewBid
//
//  Created by Mark on 2/22/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBFileReader : NSObject
{
   NSString *filePath;
   NSString *fileEnd;
   NSString *fileContents;
   NSUInteger fileLength;
   NSRange  lineRange;
   NSUInteger lineStart;
   NSUInteger lineEnd;
   NSUInteger contentsEnd;
   NSMutableString *fileLine;
}

#pragma mark INITIALIZATION
- (id)initWithPath:(NSString *)inFilePath end:(NSString *)inFileEnd;

#pragma mark FILE READING
- (BOOL)nextLine;

#pragma mark ACCESSORS
- (NSString *)filePath;
- (void)setFilePath:(NSString *)inValue;
- (NSString *)fileEnd;
- (void)setFileEnd:(NSString *)inValue;
- (NSString *)fileContents;
- (void)setFileContents:(NSString *)inValue;

@end
