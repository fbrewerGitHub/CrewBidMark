//
//  CBSelectTabViewController.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 17 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBDataModel.h"
#import "CSBidPeriod.h"
#import "CSCrewPositions.h"
#import "CBInterfaceItemController.h"
#import "CBCheckboxController.h"
#import "CBRadioMatrixController.h"

#pragma mark SELECT TAB LINE ATTRIBUTE KEYS
NSString * CBSelectTabLineAttributeTitleKey = @"CBSelectTab Line Attribute Title";
NSString * CBSelectTabLineAttributeTabNumberKey = @"CBSelectTab Line Attribute Tab Number";


@implementation CBMainWindowController ( CBSelectTabViewController )

#pragma mark INITIALIZATION

- (void)initializeSelectTabView
{
   [self registerNotificationsForSelectTabView];
   [self setSelectTabItems:[self selectTabItemsArray]];
   [[self selectTabTableView] reloadData];
}

- (void)registerNotificationsForSelectTabView
{
   // for now, do nothing; everything should be updated by the individual
   // interface item controllers
}

- (NSArray *)selectTabItemsArray;
{
   NSMutableArray * selectTabItemsArray = [NSMutableArray array];
   
   BOOL isPilot2ndRoundBid = [[[self dataModel] bidPeriod] isSecondRoundBid] && ![[[[self dataModel] bidPeriod] position] isEqualToString:CSFlightAttendant];
   
	// add aircraft changes if not a flight attendant bid or not a pilot
	// second round bid
    if (![self isFlightAttendantBid] && !isPilot2ndRoundBid)
    {
        [selectTabItemsArray addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"Aircraft Changes", @"label",
                @"aircraftChanges", @"identifier", nil]];
    }
    [selectTabItemsArray addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"AM/PM", @"label",
            @"amPM", @"identifier", nil]];
    [selectTabItemsArray addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Block of Days Off", @"label",
            @"blockOfDaysOff", @"identifier", nil]];
    [selectTabItemsArray addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Commuting", @"label",
            @"commuting", @"identifier", nil]];
    [selectTabItemsArray addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Days of Month", @"label",
            @"daysOfMonth", @"identifier", nil]];
    // pilot second round bids should not be selectable by deadheads, overlap,
	// or max legs per day
	if (!isPilot2ndRoundBid)
	{
		[selectTabItemsArray addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"Deadheads", @"label",
                @"deadheads", @"identifier", nil]];
        
        // Temp fix to remove overlap from pilot fist round bids.
        /*
		[selectTabItemsArray addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"Overlap", @"label",
                @"overlap", @"identifier", nil]];
         */
        
        
		[selectTabItemsArray addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                @"Max Legs per Day", @"label",
                @"legsPerDay", @"identifier", nil]];
    }
    [selectTabItemsArray addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Overnights", @"label",
            @"overnights", @"identifier", nil]];	
    [selectTabItemsArray addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Trip Length", @"label",
            @"tripLength", @"identifier", nil]];

        // TEMP CODE UNTIL VACATION DATA MODEL IS SET UP
//    [selectTabItemsArray addObject:
//        [NSDictionary dictionaryWithObjectsAndKeys:
//            @"Vacation", @"label",
//            @"vacation", @"identifier", nil]];

   return [NSArray arrayWithArray:selectTabItemsArray];
}

#pragma mark ACCESSORS

- (NSTableView *)selectTabTableView { return selectTabTableView; }

- (NSTabView *)selectTabView { return selectTabView; }

- (NSArray *)selectTabItems { return selectTabItems; }
- (void)setSelectTabItems:(NSArray *)inValue
{
   if (selectTabItems != inValue) {
      [selectTabItems release];
      selectTabItems = [inValue retain];
   }
}


@end
