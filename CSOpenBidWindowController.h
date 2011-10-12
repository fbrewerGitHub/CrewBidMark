//
//  CSOpenBidWindowController.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 6/22/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CSBidPeriod;


@interface CSOpenBidWindowController : NSWindowController
{
    NSArray *_bidPeriods;
    NSIndexSet *_selectedBidPeriodIndexes;
    BOOL _enableOkButton;
}

#pragma mark
#pragma mark Actions
#pragma mark

- (void)okButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

#pragma mark
#pragma mark Open Old Files
#pragma mark

- (NSArray *)bidPeriodValuesForOldDocuments;
- (NSDictionary *)bidPeriodValuesForOldDocumentName:(NSString *)documentName;

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSArray *)bidPeriods;
- (void)setBidPeriods:(NSArray *)value;

- (NSIndexSet *)selectedBidPeriodIndexes;
- (void)setSelectedBidPeriodIndexes:(NSIndexSet *)value;

- (BOOL)enableOkButton;
- (void)setEnableOkButton:(BOOL)value;

@end
