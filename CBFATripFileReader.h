//
//  CBFATripFileReader.h
//  CrewBid
//
//  Created by Mark on 2/10/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CBTripDayLeg;

@interface CBFATripFileReader : NSObject
{
   NSString *tripsDataPath;
   NSString *tripsTextPath;
}

#pragma mark INITIALIZATION
- (id)initWithTripsDataFile:(NSString *)dataPath tripsTextFile:(NSString *)textPath;

#pragma mark FILE READING
- (NSDictionary *)tripsDictionary;
- (CBTripDayLeg *)legWithFileString:(NSString *)fileString;
- (void)setTripDaysCreditWithFile:(NSString *)path trips:(NSMutableDictionary *)trips;

#pragma mark ACCESSORS
- (NSString *)tripsDataPath;
- (void)setTripsDataPath:(NSString *)inValue;
- (NSString *)tripsTextPath;
- (void)setTripsTextPath:(NSString *)inValue;

@end

// keys for preferences that determine whether trips are AM or PM
// required for FA trips only, since pilot bid data contains AM/PM information
// and FA bid data does not
// keys are defined in CBMainPreferencesWindowController.h
extern NSString * CBAmDepartTimePreferencesKey;
extern NSString * CBAmArrivalTimePreferencesKey;
