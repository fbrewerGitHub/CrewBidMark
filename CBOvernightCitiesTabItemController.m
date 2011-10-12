//
//  CBOvernightCitiesTabItemController.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/11/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBDataModel.h"

@implementation CBMainWindowController (CBOvernightCitiesTabItemController)

NSString *CBSelectsKey = @"selects";
NSString *CBCityKey = @"city";
NSString *CBPointsKey = @"points";
void *CBSelectsChangedContext = (void *)2091;
void *CBPointsChangedContex = (void *)2093;


#pragma mark Intitialization

- (void)initializeOvernightCitiesTabItem
{
    NSArray *overnightCities = [[self dataModel] overnightCities];
    NSMutableArray *ovntCitiesValues = [NSMutableArray arrayWithCapacity:[overnightCities count]];
    NSSet *selOvntCities = [[self dataModel] overnightCitiesSelectValues];
    NSDictionary *ptsOvntCities = [[self dataModel] overnightCitiesPointsValues];
    NSEnumerator *cityEnumerator = [overnightCities objectEnumerator];
    NSString *city = nil;
    while (city = [cityEnumerator nextObject])
    {
        NSNumber *selects = [NSNumber numberWithBool:[selOvntCities containsObject:city] ? YES : NO];
        NSNumber *points = [ptsOvntCities objectForKey:city];
        if (nil == points)
        {
            points = [NSNumber numberWithFloat:0.0];
        }
        [ovntCitiesValues addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
            city, CBCityKey,
            selects, CBSelectsKey,
            points, CBPointsKey, nil]];
    }

    [self setOvernightCitiesValues:ovntCitiesValues];
}

#pragma mark Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSString *city = [object valueForKey:CBCityKey];
    if (CBSelectsChangedContext == context)
    {
        NSMutableSet *selCities = [[[self dataModel] overnightCitiesSelectValues] mutableCopy];
        BOOL selects = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (selects)
        {
            [selCities addObject:city];
        }
        else
        {
            [selCities removeObject:city];
        }
        [[self dataModel] setOvernightCitiesSelectValues:selCities];
        [selCities release];
    }
    else if (CBPointsChangedContex == context)
    {
        NSMutableDictionary *ptsCities = [[[self dataModel] overnightCitiesPointsValues] mutableCopy];
        float newPts = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        if (0.0 == newPts)
        {
            [ptsCities removeObjectForKey:city];
        }
        else
        {
            [ptsCities setObject:[NSNumber numberWithFloat:newPts] forKey:city];
        }
        [[self dataModel] setOvernightCitiesPointsValues:ptsCities];
        [ptsCities release];
    }
}

- (void)startObservingOvernightCitiesValues
{
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self overnightCitiesValues] count])];

    [[self overnightCitiesValues] 
        addObserver:self 
        toObjectsAtIndexes:allIndexes 
        forKeyPath:CBSelectsKey 
        options:NSKeyValueObservingOptionNew 
        context:CBSelectsChangedContext];

    [[self overnightCitiesValues] 
        addObserver:self 
        toObjectsAtIndexes:allIndexes 
        forKeyPath:CBPointsKey 
        options:NSKeyValueObservingOptionNew 
        context:CBPointsChangedContex];
}

- (void)stopObservingOvernightCitiesValues
{
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self overnightCitiesValues] count])];

    [[self overnightCitiesValues] 
        removeObserver:self 
        fromObjectsAtIndexes:allIndexes 
        forKeyPath:CBSelectsKey];

    [[self overnightCitiesValues] 
        removeObserver:self 
        fromObjectsAtIndexes:allIndexes 
        forKeyPath:CBPointsKey];
}

#pragma mark Accessors

- (NSArray *)overnightCitiesValues {
    return overnightCitiesValues;
}

- (void)setOvernightCitiesValues:(NSArray *)value {
    if (overnightCitiesValues != value) {
        [self stopObservingOvernightCitiesValues];
        [overnightCitiesValues release];
        overnightCitiesValues = [value copy];
        [self startObservingOvernightCitiesValues];
    }
}

@end
