//
//  CBLineFileReader.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBLine;

@interface CBLineFileReader : NSObject
{
	NSString * linesFilePath;
	NSDictionary *_trips;
}

#pragma mark INITIALIZATION
- (id)initWithLinesFile:(NSString *)path trips:(NSDictionary *)trips;

#pragma mark FILE READING
- (NSArray *)linesArray;
- (CBLine *)lineWithData:(NSArray *)lineData;
- (float)lineCreditWithString:(NSString *)creditData;
- (float)lineBlockWithString:(NSString *)blockData;
- (NSArray *)lineTripsWithString:(NSString *)tripData;

#pragma mark ACCESSORS
- (NSString *)linesFilePath;
- (void)setLinesFilePath:(NSString *)inValue;
- (NSDictionary *)trips;
- (void)setTrips:(NSDictionary *)value;

@end
