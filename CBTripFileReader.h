//
//  CBTripFileReader.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBTrip;

@interface CBTripFileReader : NSObject
{
   NSString * tripsFilePath;
}

#pragma mark INITIALIZATION
- (id)initWithTripsFile:(NSString *)path;

#pragma mark FILE READING
- (NSDictionary *)tripsDictionary;
- (NSArray *)tripDaysWithPay:(NSArray *)payArray flightData:(NSString *)flightData times:(NSString *)times isReserve:(BOOL)isReserve;
- (float)creditWithString:(NSString *)creditData;
- (float)blockWithString:(NSString *)blockData;

#pragma mark ACCESSORS
- (NSString *)tripsFilePath;
- (void)setTripsFilePath:(NSString *)inValue;

@end
