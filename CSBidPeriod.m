//
//  CSBidPeriod.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/14/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSBidPeriod.h"

#import "CSPreferenceKeys.h"
#import "CSCrewPositions.h"
#import "CSBidReceipt.h"


@implementation CSBidPeriod

#pragma mark
#pragma mark Class Methods
#pragma mark

+ (CSBidPeriod *)defaultBidPeriod
{
    // Month
    NSCalendarDate *today = [NSCalendarDate calendarDate];
    NSCalendarDate *nextMonth = [NSCalendarDate 
        dateWithYear:[today yearOfCommonEra] 
        month:[today monthOfYear] + 1 
        day:1 
        hour:0 
        minute:0 
        second:0 
        timeZone:[NSTimeZone defaultTimeZone]];

    int round = [today dayOfMonth] < 12 ? 1 : 2;

    NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:
        nextMonth, @"month",
        [[NSUserDefaults standardUserDefaults] objectForKey:CSPreferencesCrewBaseKey], @"base",
        [[NSUserDefaults standardUserDefaults] objectForKey:CSPreferencesCrewPositionKey], @"position",
        [NSNumber numberWithInt:round], @"round", nil];
    
    CSBidPeriod *defaultBidPeriod = [CSBidPeriod bidPeriodForObject:values];
    return defaultBidPeriod;
}

+ (CSBidPeriod *)bidPeriodForObject:(id)object
{
    CSBidPeriod *bidPeriod = [[CSBidPeriod alloc] init];
    NSDictionary *values = [object dictionaryWithValuesForKeys:[NSArray arrayWithObjects:
        @"month",
        @"base",
        @"position",
        @"round", nil]];
    [bidPeriod setValuesForKeysWithDictionary:values];
    return [bidPeriod autorelease];
}

#pragma mark Initialization

- (void) dealloc
{
    [self setMonth:nil];
    [self setBase:nil];
    [self setPosition:nil];
    [self setRound:nil];
	[self setBidLines:nil];
    [super dealloc];
}


#pragma mark File Path
#pragma mark

- (NSString *)bidDataDirectoryPath
{
    NSString *crewBidDir = [[NSApp delegate] valueForKey:@"crewBidDirectoryPath"];
    NSString *bidDataDirectoryPath = [crewBidDir stringByAppendingPathComponent:[self bidDataDirectoryName]];
    return bidDataDirectoryPath;
}

- (NSString *)textDataFilePath
{
    NSString *textDataFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:[self textDataFileName]];
    return textDataFilePath;
}

- (NSString *)linesDataFilePath
{
    NSString *linesDataFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:@"PS"];
    return linesDataFilePath;
}

- (NSString *)linesTextFilePath
{
    /* L for first round, N for second round */
    char bidRoundChar = [self isSecondRoundBid] ? 'N' : 'L';
    
    NSString *linesTextFileName = [NSString stringWithFormat:@"%@%c.TXT",
        [self textFileBase],
        bidRoundChar];
    NSString *linesTextFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:linesTextFileName];
    
    return linesTextFilePath;
}

- (NSString *)tripsDataFilePath
{
    NSString *tripsDataFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:@"TRIPS"];
    return tripsDataFilePath;
}

- (NSString *)tripsTextFilePath
{
    /* P for first round, T for flight attendant second round. There is no
    trips text file for pilot second round. */
    char bidRoundChar = 'P';
    if ([self isSecondRoundBid])
    {
        bidRoundChar = 'P';
        
//        if (![[self crewPosition] isFlightAttendant])
//        {
//            return nil;
//        }
    }
    
    NSString *tripsTextFileName = [NSString stringWithFormat:@"%@%c.TXT",
        [self textFileBase],
        bidRoundChar];
    NSString *tripsTextFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:tripsTextFileName];
    
    return tripsTextFilePath;
}

- (NSString *)tripsPayFilePath
{
    NSString *tripsPayFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:@"TripPay.txt"];
    return tripsPayFilePath;
}

- (NSString *)coverFilePath
{
    NSString *coverFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:[self coverFileName]];
    
    return coverFilePath;
}

- (NSString *)seniorityFilePath
{
    NSString *seniorityFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:[self seniorityFileName]];
    
    return seniorityFilePath;
}

- (NSString *)bidAwardFilePath
{
    NSString *bidAwardFilePath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:[self bidAwardFileName]];
    return bidAwardFilePath;
}

- (NSString *)bidDocumentPath
{
    NSString *bidDocumentPath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:[self bidDocumentName]];
    return bidDocumentPath;
}

- (NSString *)nextBidReceiptPath
{
    NSString *nextBidReceiptPath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:[self nextBidReceiptName]];
    return nextBidReceiptPath;
}

- (NSString *)bidReceiptDirectoryPathForEmployeeNumber:(NSString *)employeeNumber
{
	NSString *empNum = [self employeeNumberByRemovingLeadingZerosFromEmployeeNumber:employeeNumber];
	NSString *bidReceiptDir = [[self bidDataDirectoryPath] stringByAppendingPathComponent:empNum];
	return bidReceiptDir;
}

- (NSString *)mostRecentBidReceiptPath
{
    NSString *mostRecentBidReceiptPath = nil;
    NSString *mostRecentBidReceiptName = [self mostRecentBidReceiptName];
    if (mostRecentBidReceiptName != nil)
    {
        mostRecentBidReceiptPath = [[self bidDataDirectoryPath] stringByAppendingPathComponent:mostRecentBidReceiptName];
    }
    return mostRecentBidReceiptPath;
}

- (BOOL)bidDataExists
{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL bidDataExists = [fm fileExistsAtPath:[self bidDataDirectoryPath] isDirectory:&isDir] && isDir;
    if (bidDataExists)
    {
        bidDataExists = [fm fileExistsAtPath:[self linesDataFilePath]];
    }
    if (bidDataExists)
    {
        bidDataExists = [fm fileExistsAtPath:[self tripsDataFilePath]];
    }
    if (bidDataExists)
    {
        bidDataExists = [fm fileExistsAtPath:[self linesTextFilePath]];
    }
    if (bidDataExists)
    {
        bidDataExists = [fm fileExistsAtPath:[self tripsTextFilePath]];
    }
    return bidDataExists;
}

#pragma mark File Name

- (NSString *)bidDataDirectoryName
{
    NSString *bidDataDirectoryName = [NSString stringWithFormat:@"%@%@%@%@",
        [[self month] descriptionWithCalendarFormat:@"%Y%m"], // e.g. 082006 
        [self base], 
        [self positionAbbreviation], 
        [self round]];
    
    return bidDataDirectoryName;
}

- (NSString *)bidDataFileName
{
    // C for captain, F for first officer, A for flight attendant
    char bidPosChar = [self positionCharacter];
    
    // D for first round bid, B for second round bid
    char bidRoundChar = [self isSecondRoundBid] ? 'B' : 'D';
    
    // bid month: hex value of month integer
    NSString *bidDataFileName =  [NSString stringWithFormat:@"%c%c%@%lx.737", 
        bidPosChar,
        bidRoundChar, 
        [self base], 
        (long)[[self month] monthOfYear]];
    
    return bidDataFileName;
}

- (NSString *)textDataFileName
{
    /* A for first round, B for second round */
    char bidRoundChar = [self isSecondRoundBid] ? 'B' : 'A';
    
    NSString *textDataFileName = [NSString stringWithFormat:@"%@%c.ZIP", 
        [self textFileBase], 
        bidRoundChar];
    
    return textDataFileName;
}

- (NSString *)coverFileName
{
    /* C for first round, R for pilot second round, CR for flight attendant 
    second round. For pilot second round, cover letter and seniority list
    are the same file. */
    NSString *bidRoundString = @"C";
    if ([self isSecondRoundBid])
    {
        if ([self isFlightAttendantBid])
        {
            bidRoundString = @"CR";
        }
        else
        {
            bidRoundString = @"R";
        }
    }
    
    NSString *coverFileName = [NSString stringWithFormat:@"%@%@.TXT",
        [self textFileBase],
        bidRoundString];
    return coverFileName;
}

- (NSString *)seniorityFileName
{
    /* S for first round, R for pilot second round, SR for flight attendant 
    second round. For pilot second round, cover letter and seniority list
    are the same file. */
    NSString *bidRoundString = @"S";
    if ([self isSecondRoundBid])
    {
        if ([self isFlightAttendantBid])
        {
            bidRoundString = @"SR";
        }
        else
        {
            bidRoundString = @"R";
        }
    }
    
    NSString *seniorityFileName = [NSString stringWithFormat:@"%@%@.TXT",
        [self textFileBase],
        bidRoundString];
    return seniorityFileName;
}

- (NSString *)bidAwardDataFileName
{
    /* M for first round, W for second round */
    char bidRoundChar = 'M';
    if ([self isSecondRoundBid])
    {
        bidRoundChar = 'W';
    }
    
    NSString *bidAwardDataFileName = [NSString stringWithFormat:@"%@%c.ZIP", 
        [self textFileBase], 
        bidRoundChar];
    
    return bidAwardDataFileName;
}

- (NSString *)bidAwardFileName
{
    /* M for first round, W for second round */
    char bidRoundChar = 'M';
    if ([self isSecondRoundBid])
    {
        bidRoundChar = 'W';
    }
    
    NSString *bidAwardFileName = [NSString stringWithFormat:@"%@%c.TXT", 
        [self textFileBase], 
        bidRoundChar];
    
    return bidAwardFileName;
}

- (NSString *)textFileBase
{
    NSString *textFileBaseString = [NSString stringWithFormat:@"%@%@", 
        [self base], 
        [self positionAbbreviation]];
    return textFileBaseString;
}

- (NSString *)displayName
{
    NSString *displayName = [NSString stringWithFormat:@"%@ %@ %@ Round %@",
        [[self month] descriptionWithCalendarFormat:@"%B %Y"],
        [self base],
        [self position],
        [self round]];
    return displayName;
}

- (NSString *)bidDocumentName
{
    NSString *bidDocumentName = [[self displayName] stringByAppendingPathExtension:@"crewbid"];
    return bidDocumentName;
}

/*  With version 1.5.0, bid receipts are prefixed with the employee number for which the bid was submitted. For backwards compatibility with previous bid receipts, we need to check for bid receipts that begin with or without the employee number. Also, we need to provide a method for determining if there have more than one employee number for which bids have been submitted, as well as the employee numbers for which bids have been submitted.
*/
- (NSString *)nextBidReceiptName
{
    NSString *nextBidReceiptName = @"Bid Receipt-1.txt";
    NSString *mostRecentBidReceiptName = [self mostRecentBidReceiptName];
    if (mostRecentBidReceiptName)
    {
        NSScanner *scanner = [NSScanner scannerWithString:mostRecentBidReceiptName];
        [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        int bidNum = 0;
        [scanner scanInt:&bidNum];
        nextBidReceiptName = [NSString stringWithFormat:@"Bid Receipt-%d.txt", bidNum + 1];
    }
    return nextBidReceiptName;
}

- (NSString *)mostRecentBidReceiptName
{
    NSString *mostRecentBidReceiptName = nil;
    NSArray *bidReceipts = [self bidReceipts];
    if ([bidReceipts count])
    {
        mostRecentBidReceiptName = [bidReceipts lastObject];
    }
    return mostRecentBidReceiptName;
}

- (NSArray *)bidReceipts
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *bidDataDirContents = [fm contentsOfDirectoryAtPath:[self bidDataDirectoryPath] error:NULL];
    NSMutableArray *bidReceipts = [NSMutableArray arrayWithCapacity:8];
    NSEnumerator *contentsEnum = [bidDataDirContents objectEnumerator];
    NSString *name = nil;
    while (name = [contentsEnum nextObject])
    {
        if ([name hasPrefix:@"Bid Receipt"])
        {
            [bidReceipts addObject:name];
        }
    }
    return [bidReceipts sortedArrayUsingSelector:@selector(compare:)];
}

- (NSString *)nextBidReceiptNameForEmployeeNumber:(NSString *)employeeNumber
{
	NSString *empNum = [self employeeNumberByRemovingLeadingZerosFromEmployeeNumber:employeeNumber];
	NSString *nextBidReceiptName = [NSString stringWithFormat:@"%@ Bid Receipt-1.txt", empNum];
    NSString *mostRecentBidReceiptName = [self mostRecentBidReceiptNameForEmployeeNumber:employeeNumber];
    if (mostRecentBidReceiptName)
    {
        NSScanner *scanner = [NSScanner scannerWithString:mostRecentBidReceiptName];
		[scanner scanString:empNum intoString:NULL];
        [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        int bidNum = 0;
        [scanner scanInt:&bidNum];
        nextBidReceiptName = [NSString stringWithFormat:@"%@ Bid Receipt-%d.txt", employeeNumber, bidNum + 1];
    }
    return nextBidReceiptName;
}

- (NSString *)mostRecentBidReceiptNameForEmployeeNumber:(NSString *)employeeNumber
{
    NSString *mostRecentBidReceiptName = nil;
    NSArray *bidReceipts = [self bidReceiptsForEmployeeNumber:employeeNumber];
    if ([bidReceipts count])
    {
        mostRecentBidReceiptName = [bidReceipts lastObject];
    }
    return mostRecentBidReceiptName;
}

- (NSArray *)bidReceiptsForEmployeeNumber:(NSString *)employeeNumber
{
	NSString *bidReceiptDir = [self bidReceiptDirectoryPathForEmployeeNumber:employeeNumber];
	NSString *empNum = [self employeeNumberByRemovingLeadingZerosFromEmployeeNumber:employeeNumber];
	NSString *empNumBidReceiptFormat = [NSString stringWithFormat:@"%@ Bid Receipt", empNum];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *bidReceiptDirContents = [fm contentsOfDirectoryAtPath:bidReceiptDir error:NULL];
    NSMutableArray *bidReceipts = [NSMutableArray arrayWithCapacity:8];
    NSEnumerator *contentsEnum = [bidReceiptDirContents objectEnumerator];
    NSString *filename = nil;
    while (filename = [contentsEnum nextObject])
    {
        if (NSNotFound != [filename rangeOfString:empNumBidReceiptFormat].location)
        {
            [bidReceipts addObject:filename];
        }
    }
    return [bidReceipts sortedArrayUsingSelector:@selector(compare:)];
}

- (NSString *)employeeNumberByRemovingLeadingZerosFromEmployeeNumber:(NSString *)employeeNumber
{
	NSString *employeeNumberByRemovingLeadingZeros = nil;
	int empNum = [employeeNumber intValue];
	if (empNum) {
		employeeNumberByRemovingLeadingZeros = [NSString stringWithFormat:@"%d", empNum];
	}
	return employeeNumberByRemovingLeadingZeros;
}

#pragma mark Derived Accessors

- (NSString *)positionAbbreviation
{
    NSString *pos = [self position];
    NSString *posAbb = nil;
	if ([pos isEqualToString:CSCaptain])
	{
		posAbb = CSCaptainAbbreviation;
	}
	else if ([pos isEqualToString:CSFirstOfficer])
	{
		posAbb = CSFirstOfficerAbbreviation;
	}
	else
	{
		posAbb = CSFlightAttendantAbbreviation;
	}
	return posAbb;
}

- (char)positionCharacter
{
    NSString *pos = [self position];
    char posChar = '\0';
	if ([pos isEqualToString:CSCaptain])
	{
		posChar = CSCaptainCharacter;
	}
	else if ([pos isEqualToString:CSFirstOfficer])
	{
		posChar = CSFirstOfficerCharacter;
	}
	else
	{
		posChar = CSFlightAttendantCharacter;
	}
	return posChar;
}

- (NSString *)packetID
{
    int round = [[self round] intValue];
    int packetIDRound = 0;
    // flight attendant bid
    if ([self isFlightAttendantBid])
    {
        // 1 for flight attendant first round bid, 2 for second round
        packetIDRound = 1 == round ? 1 : 2;
    }
    // pilot bid
    else
    {
        // 4 for pilot first round bid, 5 for second round
        packetIDRound = 1 == round ? 4 : 5;
    }
    
    NSString *packetID = [NSString stringWithFormat:@"%@%@%d",
        [self base],
        [[self month] descriptionWithCalendarFormat:@"%Y%m"],
        packetIDRound];
    
    return packetID;
}

- (BOOL)isSecondRoundBid
{
    BOOL isSecondRoundBid = (2 == [[self round] intValue]);
    return isSecondRoundBid;
}

- (BOOL)isFlightAttendantBid
{
    BOOL isFlightAttendantBid = [[self position] isEqualToString:CSFlightAttendant];
    return isFlightAttendantBid; 
}

#pragma mark COPYING

- (id)copyWithZone:(NSZone *)zone
{
   CSBidPeriod * copy = [[CSBidPeriod allocWithZone:zone] init];
   [copy setMonth:[self month]];
   [copy setBase:[self base]];
   [copy setPosition:[self position]];
   [copy setRound:[self round]];
   [copy setBidLines:[self bidLines]];
   return copy;
}

#pragma mark STORAGE

static NSString *CSBidPeriodMonthKey = @"month";
static NSString *CSBidPeriodBaseKey = @"base";
static NSString *CSBidPeriodPositionKey = @"position";
static NSString *CSBidPeriodRoundKey = @"round";

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding])
    {
        [encoder encodeObject:[self month] forKey:CSBidPeriodMonthKey];
        [encoder encodeObject:[self base] forKey:CSBidPeriodBaseKey];
        [encoder encodeObject:[self position] forKey:CSBidPeriodPositionKey];
        [encoder encodeObject:[self round] forKey:CSBidPeriodRoundKey];
    }
    else
    {
        [encoder encodeObject:[self month]];
        [encoder encodeObject:[self base]];
        [encoder encodeObject:[self position]];
        [encoder encodeObject:[self round]];
    }
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if ([decoder allowsKeyedCoding])
    {
        [self setMonth:[decoder decodeObjectForKey:CSBidPeriodMonthKey]];
        [self setBase:[decoder decodeObjectForKey:CSBidPeriodBaseKey]];
        [self setPosition:[decoder decodeObjectForKey:CSBidPeriodPositionKey]];
        [self setRound:[decoder decodeObjectForKey:CSBidPeriodRoundKey]];
    }
    else
    {
        [self setMonth:[decoder decodeObject]];
        [self setBase:[decoder decodeObject]];
        [self setPosition:[decoder decodeObject]];
        [self setRound:[decoder decodeObject]];
    }
    return self;
}

#pragma mark Accessors

- (NSCalendarDate *)month {
    return _month;
}

- (void)setMonth:(NSCalendarDate *)value {
    if (_month != value) {
        [_month release];
        _month = [value copy];
    }
}

- (NSString *)base {
    return _base;
}

- (void)setBase:(NSString *)value {
    if (_base != value) {
        [_base release];
        _base = [value copy];
    }
}

- (NSString *)position {
    return _position;
}

- (void)setPosition:(NSString *)value {
    if (_position != value) {
        [_position release];
        _position = [value copy];
    }
}

- (NSNumber *)round {
    return _round;
}

- (void)setRound:(NSNumber *)value {
    if (_round != value) {
        [_round release];
        _round = [value copy];
    }
}

- (NSArray *)bidLines {
    return [[_bidLines retain] autorelease];
}

- (void)setBidLines:(NSArray *)value {
    if (_bidLines != value) {
        [_bidLines release];
        _bidLines = [value copy];
    }
}

@end
