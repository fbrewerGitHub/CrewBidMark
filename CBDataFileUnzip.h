//
//  CBDataFileUnzip.h
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 30 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CBDataFileUnzip : NSObject
{
   NSString * dataFilePath;
}

#pragma mark INITIALIZATION
- (id)initWithDataFile:(NSString *)path;

#pragma mark FILE METHODS
- (BOOL)unzipDataFile;

#pragma mark ACCESORS
- (NSString *)dataFilePath;
- (void)setDataFilePath:(NSString *)inValue;

@end
