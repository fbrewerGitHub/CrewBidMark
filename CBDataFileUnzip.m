//
//  CBDataFileUnzip.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 30 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataFileUnzip.h"

@implementation CBDataFileUnzip

#pragma mark INITIALIZATION
- (id)initWithDataFile:(NSString *)path
{
   if (self = [super init]) {
      [self setDataFilePath:path];
   }
   return self;
}

#pragma mark FILE METHODS

- (BOOL)unzipDataFile
{
   BOOL bogusFilesExist = NO;
   BOOL dataFileExists = NO;
   BOOL dataFileUnzipped = NO;
   // check for PS and TRIPS files in dataFilePath
   NSString * unzipDirectory = [[self dataFilePath] stringByDeletingLastPathComponent];
   NSFileManager * fileManager = [NSFileManager defaultManager];
   
// FOR TESTING
//   if ([fileManager fileExistsAtPath:[unzipDirectory stringByAppendingPathComponent:@"PS"]] ||
//       [fileManager fileExistsAtPath:[unzipDirectory stringByAppendingPathComponent:@"TRIPS"]]) {
//      bogusFilesExist = YES;
//   }
   // if no PS or TRIPS file in unzip directory, check for data file in unzip directory
   if (!bogusFilesExist && [fileManager fileExistsAtPath:[self dataFilePath]]) {
      dataFileExists = YES;
   }
   // if data file exists, unzip
   if (!bogusFilesExist && dataFileExists) {
      // check that unzip utility is available
      NSString * unzipPath = [NSBundle pathForResource:@"unzip" ofType:nil inDirectory:[[NSBundle mainBundle] bundlePath]];
      if ([fileManager isExecutableFileAtPath:unzipPath]) {
         NSTask * task = [[NSTask alloc] init];
         [task setCurrentDirectoryPath:unzipDirectory];
         NSArray * args = [NSArray arrayWithObjects:@"-q", @"-o", [self dataFilePath], nil];
         [task setArguments:args];
         [task setLaunchPath:unzipPath];
         [task launch];
         [task waitUntilExit];
         [task release];
      }
   }
   // now check that PS and TRIPS files were created
   if (!bogusFilesExist &&
       [fileManager fileExistsAtPath:[unzipDirectory stringByAppendingPathComponent:@"PS"]] &&
       [fileManager fileExistsAtPath:[unzipDirectory stringByAppendingPathComponent:@"TRIPS"]]) {
      dataFileUnzipped = YES;
      
      // remove compressed data file
       [fileManager removeItemAtPath:[self dataFilePath] error:NULL];
   }
   return dataFileUnzipped;
}

#pragma mark ACCESORS
- (NSString *)dataFilePath { return dataFilePath; }
- (void)setDataFilePath:(NSString *)inValue
{
   if (dataFilePath != inValue) {
      [dataFilePath release];
      dataFilePath = [inValue copy];
   }
}

@end
