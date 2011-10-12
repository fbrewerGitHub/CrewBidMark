//
//  CSBidReceipt.m
//  CrewBid
//
//  Created by Mark Ackerman on 1/15/08.
//  Copyright 2008 Mark Ackerman. All rights reserved.
//

#import "CSBidReceipt.h"

NSString *CSBidReceiptName = @"Bid Receipt";
NSString *CSBidReciptExtension = @"txt";


@implementation CSBidReceipt

#pragma mark Initialization

- (id)initWithPath:(NSString *)path
{
	if (self = [super init]) {
		[self setPath:path];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			NSString *pathContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
			NSScanner *scanner = [NSScanner scannerWithString:pathContents];
			[scanner scanString:@"SUBMITTED BY:" intoString:NULL];
			if (![scanner isAtEnd]) {
				// scan past open bracket
				NSCharacterSet *openBracket = [NSCharacterSet characterSetWithCharactersInString:@"["];
				[scanner scanUpToCharactersFromSet:openBracket intoString:NULL];
				[scanner scanCharactersFromSet:openBracket intoString:NULL];
				// scan submitted by
				NSCharacterSet *closeBracket = [NSCharacterSet characterSetWithCharactersInString:@"]"];
				NSString *submittedBy = nil;
				[scanner scanUpToCharactersFromSet:closeBracket intoString:&submittedBy];
				// scan past close bracket
				[scanner scanCharactersFromSet:closeBracket intoString:NULL];
				// scan employee number for which bid was submitted
				NSString *submittedFor = nil;
				[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&submittedFor];
				// scan date and time
				NSString *date = nil;
				[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&date];
				NSString *time = nil;
				[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&time];
				// create bid date/time from date and tim
				NSString *dateTime = [NSString stringWithFormat:@"%@ %@", date, time];
				NSDateFormatter *df = [[NSDateFormatter alloc] initWithDateFormat:@"%m/%d/%y %H:%M:%S" allowNaturalLanguage:NO];
				NSDate *bidDateTime = [df dateFromString:dateTime];
				// set data members
				[self setSubmittedBy:submittedBy];
				[self setSubmittedFor:submittedFor];
				[self setBidDateTime:bidDateTime];
			}
		}
	}
	return self;
}

- (void) dealloc
{
	[self setPath:nil];
	[self setSubmittedBy:nil];
	[self setBidDateTime:nil];
	[super dealloc];
}

#pragma mark Derived Accessors

- (NSString *)filename
{
	NSString *filename = [[self path] lastPathComponent];
	return filename;
}

#pragma mark Accessors

- (NSString *)path
{
    return _path;
}

- (void)setPath:(NSString *)value
{
    if (_path != value) {
        [_path release];
        _path = [value copy];
    }
}

- (NSString *)submittedBy {
    return _submittedBy;
}

- (void)setSubmittedBy:(NSString *)value {
    if (_submittedBy != value) {
        [_submittedBy release];
        _submittedBy = [value copy];
    }
}

- (NSString *)submittedFor {
    return _submittedFor;
}

- (void)setSubmittedFor:(NSString *)value {
    if (_submittedFor != value) {
        [_submittedFor release];
        _submittedFor = [value copy];
    }
}

- (NSDate *)bidDateTime {
    return _bidDateTime;
}

- (void)setBidDateTime:(NSDate *)value {
    if (_bidDateTime != value) {
        [_bidDateTime release];
        _bidDateTime = [value copy];
    }
}

@end
