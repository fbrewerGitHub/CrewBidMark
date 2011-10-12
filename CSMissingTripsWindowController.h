//
//  CSMissingTripsWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on 8/19/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSMissingTripsWindowController : NSWindowController
{
	NSArray *_missingTrips;
    BOOL _enableOKButton;
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithMissingTrips:(NSArray *)missingTrips;

#pragma mark
#pragma mark Actions
#pragma mark

- (IBAction)okButtonAction:(id)sender;

#pragma mark
#pragma mark Key-Value Observing
#pragma mark

- (void)startObservingMissingTrips;
- (void)stopObservingMissingTrips;

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSArray *)missingTrips;
- (void)setMissingTrips:(NSArray *)value;

- (BOOL)enableOKButton;
- (void)setEnableOKButton:(BOOL)value;

@end
