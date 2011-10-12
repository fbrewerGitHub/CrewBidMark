//
//  CSOpenBidWindowController.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 6/22/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSOpenBidWindowController.h"

#import "CSBidPeriod.h"
#import "CSCrewPositions.h"


@implementation CSOpenBidWindowController

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    if (self = [super initWithWindowNibName:windowNibName])
    {
        // Bid Periods
//        NSString *bidPeriodsDataFilePath = [[NSApp delegate] valueForKey:@"bidPeriodsDataFilePath"];
//        NSArray *bidPeriods = [NSKeyedUnarchiver unarchiveObjectWithFile:bidPeriodsDataFilePath];
//        bidPeriods = [bidPeriods arrayByAddingObjectsFromArray:[self bidPeriodValuesForOldDocuments]];
        NSArray *bidPeriods = [self bidPeriodValuesForOldDocuments];
        NSArray *sorts = [NSArray arrayWithObjects:
            [[[NSSortDescriptor alloc] initWithKey:@"month" ascending:NO] autorelease],
            [[[NSSortDescriptor alloc] initWithKey:@"base" ascending:YES] autorelease],
            [[[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES] autorelease],
            [[[NSSortDescriptor alloc] initWithKey:@"round" ascending:YES] autorelease], nil];
        bidPeriods = [bidPeriods sortedArrayUsingDescriptors:sorts];
        [self setBidPeriods:bidPeriods];
    }
    return self;
}

- (id)init
{
    if (self = [self initWithWindowNibName:@"OpenBid"])
    {
    }
    return self;
}

- (void) dealloc
{
    [self setBidPeriods:nil];
    [super dealloc];
}

#pragma mark
#pragma mark Actions
#pragma mark

- (void)okButtonAction:(id)sender
{
    CSBidPeriod *bidPeriod = [CSBidPeriod bidPeriodForObject:sender];
    NSString *bidDocPath = [bidPeriod bidDocumentPath];
    // old style document
    if (![[NSFileManager defaultManager] fileExistsAtPath:bidDocPath])
    {
        NSString *crewBidDirectoryPath = [[NSApp delegate] valueForKey:@"crewBidDirectoryPath"];
        NSString *bidDocName = [sender valueForKey:@"documentName"];
        bidDocPath = [crewBidDirectoryPath stringByAppendingPathComponent:bidDocName];
    }
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:bidDocPath display:YES];
    [[self window] orderOut:sender];
    [self autorelease];
}

- (IBAction)cancelButtonAction:(id)sender
{
    [[self window] orderOut:nil];
    [self autorelease];
}

#pragma mark
#pragma mark Open Old Files
#pragma mark

- (NSArray *)bidPeriodValuesForOldDocuments
{
    NSMutableArray *bidPeriodValuessForOldDocuments = [NSMutableArray array];
    NSString *crewBidDirectoryPath = [[NSApp delegate] valueForKey:@"crewBidDirectoryPath"];
    NSArray *crewBidDirectoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:crewBidDirectoryPath];
    NSEnumerator *crewBidDirectoryEnumerator = [crewBidDirectoryContents objectEnumerator];
    NSString *fileName = nil;
    while (fileName = [crewBidDirectoryEnumerator nextObject])
    {
        if ([[fileName pathExtension] isEqualToString:@"crewbid"])
        {
            [bidPeriodValuessForOldDocuments addObject:[self bidPeriodValuesForOldDocumentName:fileName]];
        }
    }
    return bidPeriodValuessForOldDocuments;
}

- (NSDictionary *)bidPeriodValuesForOldDocumentName:(NSString *)documentName
{
    // filename format Feb 06 MCO FO Rnd 1
    //                 0123456789012345678
    NSRange dateRange = NSMakeRange(0, 6);
    NSRange baseRange = NSMakeRange(7, 3);
    NSRange posAbbrevRange = NSMakeRange(11, 2);
    NSRange roundRange = NSMakeRange(18, 1);
    NSString *dateString = [NSString stringWithFormat:@"1 %@", [documentName substringWithRange:dateRange]];
    NSCalendarDate *month = [NSCalendarDate dateWithString:dateString calendarFormat:@"%e %b %y"];
    NSString *base = [documentName substringWithRange:baseRange];
    NSString *posAbbrev = [documentName substringWithRange:posAbbrevRange];
    NSString *position = nil;
    if ([posAbbrev isEqualToString:CSCaptainAbbreviation] || [posAbbrev isEqualToString:@"CA"])
    {
        position = CSCaptain;
    }
    else if ([posAbbrev isEqualToString:CSFirstOfficerAbbreviation])
    {
        position = CSFirstOfficer;
    }
    else
    {
        position = CSFlightAttendant;
    }
    NSNumber *round = [NSNumber numberWithInt:[[documentName substringWithRange:roundRange] intValue]];
    NSDictionary *bidPeriodValues = [NSDictionary dictionaryWithObjectsAndKeys:
        month, @"month",
        base, @"base",
        position, @"position",
        round, @"round", 
        documentName, @"documentName", nil];
    return bidPeriodValues;
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSArray *)bidPeriods {
    return [[_bidPeriods retain] autorelease];
}

- (void)setBidPeriods:(NSArray *)value {
    if (_bidPeriods != value) {
        [_bidPeriods release];
        _bidPeriods = [value copy];
    }
}

- (NSIndexSet *)selectedBidPeriodIndexes {
    return [[_selectedBidPeriodIndexes retain] autorelease];
}

- (void)setSelectedBidPeriodIndexes:(NSIndexSet *)value {
    if (_selectedBidPeriodIndexes != value) {
        [_selectedBidPeriodIndexes release];
        _selectedBidPeriodIndexes = [value copy];
        
        // enable ok button if there is one and only one selected index
        if (1 == [_selectedBidPeriodIndexes count])
        {
            [self setEnableOkButton:YES];
        }
        else
        {
            [self setEnableOkButton:NO];
        }
    }
}

- (BOOL)enableOkButton {
    return _enableOkButton;
}

- (void)setEnableOkButton:(BOOL)value {
    if (_enableOkButton != value) {
        _enableOkButton = value;
    }
}

@end
