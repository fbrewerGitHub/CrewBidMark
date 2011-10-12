//
//  CBFALineFileReader.h
//  CrewBid
//
//  Created by Mark on 2/22/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBFileReader.h"

@interface CBFALineFileReader : CBFileReader
{
	NSCalendarDate *bidMonth;
}

#pragma mark INITIALIZATION
//- (id)initWithFile:(NSString *)inFilePath trips:(NSDictionary *);

- (NSArray *)readLines;

#pragma mark Accessors
- (NSCalendarDate *)bidMonth;
- (void)setBidMonth:(NSCalendarDate *)value;

@end
