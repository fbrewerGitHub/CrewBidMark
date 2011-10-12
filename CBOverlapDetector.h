//
//  CBOverlapDetector.h
//  CrewBid
//
//  Created by Mark Ackerman on 8/10/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBLine;
@class CBDataModel;

@interface CBOverlapDetector : NSObject
{
   CBDataModel * dataModel;
}

#pragma mark INITIALIZATION
- (id)initWithDataModel:(CBDataModel *)inDataModel;

#pragma mark OVERLAP DETECTION
- (void)detectOverlaps;
- (NSCalendarDate *)previousMonthReleaseTimeWithOverlapEntries:(NSArray *)entries;
- (void)getBlockTimes:(NSArray **)blockTimes reportTime:(NSCalendarDate **)reportTime reportTimeIndex:(unsigned *)reportTimeIndex forLine:(CBLine *)line;

#pragma mark ACCESSORS
- (CBDataModel *)dataModel;

@end

extern unsigned NUM_OVERLAP_ARRAY_ENTRIES;
extern unsigned NUM_OVERLAPPING_ENTRIES;

