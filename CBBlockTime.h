//
//  CBBlockTime.h
//  CrewBid
//
//  Created by Mark Ackerman on 8/7/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBBlockTime : NSObject <NSCopying, NSCoding>
{
   unsigned hours;
   unsigned minutes;
}

#pragma mark INITIALIZATION
- (id)initWithHours:(unsigned)inHours minutes:(unsigned)inMinutes;
+ (id)blockTimeWithMinutes:(unsigned)inMinutes;
+ (id)blockTimeWithString:(NSString *)string;
+ (id)zeroBlockTime;

#pragma mark COPYING
- (id)copyWithZone:(NSZone *)zone;

#pragma mark ARITHMETIC METHODS
- (CBBlockTime *)addBlockTime:(CBBlockTime *)addedBlockTime;
- (CBBlockTime *)subtractBlockTime:(CBBlockTime *)subtractedBlockTime;

#pragma mark COMPARISON METHODS
- (BOOL)isEqualToBlockTime:(CBBlockTime *)compareValue;
- (BOOL)isZero;

#pragma mark DERIVED VALUES
- (unsigned)totalMinutes;

#pragma mark ACCESSORS
- (unsigned)hours;
- (unsigned)minutes;

@end
