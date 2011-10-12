//
//  CSBidPeriod.h
//  CrewBid
//
//  Created by Mark Ackerman on 8/14/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSBidPeriod : NSObject <NSCopying, NSCoding>
{
    NSCalendarDate *_month;
    NSString *_base;
    NSString *_position;
    NSNumber *_round;
	NSArray *_bidLines;
}

#pragma mark
#pragma mark Class Methods
#pragma mark

+ (CSBidPeriod *)defaultBidPeriod;
+ (CSBidPeriod *)bidPeriodForObject:(id)object;

#pragma mark File Path
- (NSString *)bidDataDirectoryPath;
- (NSString *)textDataFilePath;
- (NSString *)linesDataFilePath;
- (NSString *)linesTextFilePath;
- (NSString *)tripsDataFilePath;
- (NSString *)tripsTextFilePath;
- (NSString *)tripsPayFilePath;
- (NSString *)coverFilePath;
- (NSString *)seniorityFilePath;
- (NSString *)bidAwardFilePath;
- (NSString *)bidDocumentPath;
- (NSString *)nextBidReceiptPath;
- (NSString *)mostRecentBidReceiptPath;
- (NSString *)bidReceiptDirectoryPathForEmployeeNumber:(NSString *)employeeNumber;
- (BOOL)bidDataExists;

#pragma mark File Name
- (NSString *)bidDataFileName;
- (NSString *)textDataFileName;
- (NSString *)bidDataDirectoryName;
- (NSString *)bidAwardDataFileName;
- (NSString *)bidAwardFileName;
- (NSString *)coverFileName;
- (NSString *)seniorityFileName;
- (NSString *)textFileBase;
- (NSString *)displayName;
- (NSString *)bidDocumentName;
- (NSString *)nextBidReceiptName;
- (NSString *)mostRecentBidReceiptName;
- (NSArray *)bidReceipts;
- (NSString *)nextBidReceiptNameForEmployeeNumber:(NSString *)employeeNumber;
- (NSString *)mostRecentBidReceiptNameForEmployeeNumber:(NSString *)employeeNumber;
- (NSArray *)bidReceiptsForEmployeeNumber:(NSString *)employeeNumber;
- (NSString *)employeeNumberByRemovingLeadingZerosFromEmployeeNumber:(NSString *)employeeNumber;

#pragma mark Derived Accessors
- (NSString *)positionAbbreviation;
- (char)positionCharacter;
- (NSString *)packetID;
- (BOOL)isSecondRoundBid;
- (BOOL)isFlightAttendantBid;

#pragma mark Accessors
- (NSCalendarDate *)month;
- (void)setMonth:(NSCalendarDate *)value;
- (NSString *)base;
- (void)setBase:(NSString *)value;
- (NSString *)position;
- (void)setPosition:(NSString *)value;
- (NSNumber *)round;
- (void)setRound:(NSNumber *)value;
- (NSArray *)bidLines;
- (void)setBidLines:(NSArray *)value;

@end
