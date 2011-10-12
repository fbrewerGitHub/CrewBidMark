//
//  CSBidReceipt.h
//  CrewBid
//
//  Created by Mark Ackerman on 1/15/08.
//  Copyright 2008 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSBidReceipt : NSObject
{
	NSString *_path;
	NSString *_submittedBy;
	NSString *_submittedFor;
	NSDate *_bidDateTime;
}

#pragma mark Initialization
- (id)initWithPath:(NSString *)path;

#pragma mark Derived Accessors
// last path component of path
- (NSString *)filename;

#pragma mark Accessors
// Complete path to file
- (NSString *)path;
- (void)setPath:(NSString *)value;
- (NSString *)submittedBy;
- (void)setSubmittedBy:(NSString *)value;
- (NSString *)submittedFor;
- (void)setSubmittedFor:(NSString *)value;
- (NSDate *)bidDateTime;
- (void)setBidDateTime:(NSDate *)value;

@end

extern NSString *CSBidReceiptName;
extern NSString *CSBidReciptExtension;
