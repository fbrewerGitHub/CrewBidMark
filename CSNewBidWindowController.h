//
//  CSNewBidWindowController.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 6/21/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSBidFileDownloadWindowController.h"

@class CSBidFileDownload;
@class CSBidPeriod;


@interface CSNewBidWindowController : CSBidFileDownloadWindowController
{
    // This is required for System 10.3 because contentObjects binding for bid
    // period object requires System 10.4
    NSDictionary *_selectedMonth;
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;

#pragma mark
#pragma mark New Bid Selection
#pragma mark

- (NSArray *)monthPopupButtonItems;
- (NSArray *)crewBasePopupButtonMenuItems;
- (NSArray *)crewPositionPopupButtonMenuItems;
- (NSArray *)bidRoundPopupButtonMenuItems;
- (NSDictionary *)selectedMonth;
- (void)setSelectedMonth:(NSDictionary *)value;

#pragma mark
#pragma mark Second Round Missing Trips
#pragma mark

-(void)showAlertForMissingTrips:(NSArray *)missingTrips;

@end

// defined in CBNewBidWindowController.m
extern NSString *CBMostRecentOpenedBidFileKey;
