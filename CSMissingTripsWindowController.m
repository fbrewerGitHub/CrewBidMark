//
//  CSMissingTripsWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/19/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSMissingTripsWindowController.h"

void *CSMissingTripValueChangedContext = (void *)3091;


@implementation CSMissingTripsWindowController

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithMissingTrips:(NSArray *)missingTrips
{
	if (self = [super initWithWindowNibName:@"MissingTrips"])
	{
		[self setMissingTrips:missingTrips];
	}
	return self;
}

- (void) dealloc
{
    [self setMissingTrips:nil];
    [super dealloc];
}


#pragma mark
#pragma mark Actions
#pragma mark

- (IBAction)okButtonAction:(id)sender
{
    [NSApp stopModalWithCode:NSOKButton];
}

#pragma mark
#pragma mark Key-Value Observing
#pragma mark

- (void)startObservingMissingTrips
{
    if (nil == [self missingTrips] || 0 == [[self missingTrips] count])
    {
        return;
    }

//    NSEnumerator *missingTripsEnum = [[[self missingTrips] valueForKey:@"trip"] objectEnumerator];
//    id trip = nil;
//    while (trip = [missingTripsEnum nextObject])
//    {
//        [trip 
//            addObserver:self 
//            forKeyPath:@"departureTime" 
//            options:0 
//            context:CSMissingTripValueChangedContext];
//        [trip 
//            addObserver:self 
//            forKeyPath:@"returnTime" 
//            options:0 
//            context:CSMissingTripValueChangedContext];
//        [trip 
//            addObserver:self 
//            forKeyPath:@"credit" 
//            options:0 
//            context:CSMissingTripValueChangedContext];
//    }
    
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self missingTrips] count])];
    // observe departure time, return time, and credit for each missing trip
    // to update OK button when all missing values for trips have been entered
    [[[self missingTrips] valueForKey:@"trip"]
        addObserver:self 
        toObjectsAtIndexes:allIndexes 
        forKeyPath:@"departureTime" 
        options:0 
        context:CSMissingTripValueChangedContext];
    [[[self missingTrips] valueForKey:@"trip"]
        addObserver:self 
        toObjectsAtIndexes:allIndexes 
        forKeyPath:@"returnTime" 
        options:0 
        context:CSMissingTripValueChangedContext];
    [[[self missingTrips] valueForKey:@"trip"]
        addObserver:self 
        toObjectsAtIndexes:allIndexes 
        forKeyPath:@"credit" 
        options:0 
        context:CSMissingTripValueChangedContext];
}

- (void)stopObservingMissingTrips
{
    if (nil == [self missingTrips] || 0 == [[self missingTrips] count])
    {
        return;
    }
    
//    NSEnumerator *missingTripsEnum = [[[self missingTrips] valueForKey:@"trip"] objectEnumerator];
//    id trip = nil;
//    while (trip = [missingTripsEnum nextObject])
//    {
//        [trip removeObserver:self forKeyPath:@"departureTime"];
//        [trip removeObserver:self forKeyPath:@"returnTime"];
//        [trip removeObserver:self forKeyPath:@"credit"];
//    }

    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self missingTrips] count])];
    [[[self missingTrips] valueForKey:@"trip"]
        removeObserver:self 
        fromObjectsAtIndexes:allIndexes 
        forKeyPath:@"departureTime"];
    [[[self missingTrips] valueForKey:@"trip"]
        removeObserver:self 
        fromObjectsAtIndexes:allIndexes 
        forKeyPath:@"returnTime"];
    [[[self missingTrips] valueForKey:@"trip"]
        removeObserver:self 
        fromObjectsAtIndexes:allIndexes 
        forKeyPath:@"credit"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (CSMissingTripValueChangedContext == context)
    {
        BOOL shouldEnableOKButton = YES;
        NSNumber *zero = [NSNumber numberWithInt:0];
        NSEnumerator *missingTripsEnum = [[self missingTrips] objectEnumerator];
        id trip = nil;
        while (trip = [missingTripsEnum nextObject])
        {
            if (NSOrderedSame == [[trip valueForKeyPath:@"trip.departureTime"] compare:zero] ||
                NSOrderedSame == [[trip valueForKeyPath:@"trip.returnTime"] compare:zero] ||
                NSOrderedSame == [[trip valueForKeyPath:@"trip.credit"] compare:zero])
            {
                shouldEnableOKButton = NO;
            }
        }
        [self setEnableOKButton:shouldEnableOKButton];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSArray *)missingTrips {
    return [[_missingTrips retain] autorelease];
}

- (void)setMissingTrips:(NSArray *)value {
    if (_missingTrips != value) {
    
        [self stopObservingMissingTrips];

        [_missingTrips release];
        _missingTrips = [value copy];

        [self startObservingMissingTrips];
    }
}

- (BOOL)enableOKButton {
    return _enableOKButton;
}

- (void)setEnableOKButton:(BOOL)value {
    if (_enableOKButton != value) {
        _enableOKButton = value;
    }
}

@end
