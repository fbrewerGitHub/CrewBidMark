//
//  CBFileReader.m
//  CrewBid
//
//  Created by Mark on 2/22/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import "CBFileReader.h"


@implementation CBFileReader

#pragma mark INITIALIZATION

- (id)initWithPath:(NSString *)inFilePath end:(NSString *)inFileEnd
{
   if (self = [super init])
   {
      [self setFilePath:inFilePath];
      [self setFileEnd:inFileEnd];
      [self setFileContents:[[NSString alloc] initWithContentsOfFile:[self filePath]]];
      fileLength = [[self fileContents] length];
      fileLine = [[NSMutableString alloc] init];
   }
   return self;
}

#pragma mark FILE READING

- (BOOL)nextLine
{
   BOOL moreLines = YES;
   
   [fileContents getLineStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:lineRange];
   lineRange.location = lineStart;
   lineRange.length = contentsEnd - lineStart;
   
   if (lineRange.location < fileLength)
   {
      [fileLine setString:[fileContents substringWithRange:lineRange]];
      lineRange.location = lineEnd;
      lineRange.length = 0;
   }
   
   else
   {
      moreLines = NO;
   }
   
   if (NSNotFound != [fileLine rangeOfString:[self fileEnd]].location)
   {
      moreLines = NO;
   }
   
   // TESTING
   if (moreLines)
   {
//      NSLog(@"\n%@", fileLine);
   }
   
   return moreLines;
}

#pragma mark ACCESSORS

- (NSString *)filePath { return filePath; }
- (void)setFilePath:(NSString *)inValue
{
   if (filePath != inValue)
   {
      [filePath release];
      filePath = [inValue retain];
   }
}

- (NSString *)fileEnd { return fileEnd; }
- (void)setFileEnd:(NSString *)inValue
{
   if (fileEnd != inValue)
   {
      [fileEnd release];
      fileEnd = [inValue retain];
   }
}

- (NSString *)fileContents { return fileContents; }
- (void)setFileContents:(NSString *)inValue{
   if (fileContents != inValue)
   {
      [fileContents release];
      fileContents = [inValue retain];
   }
}


@end
