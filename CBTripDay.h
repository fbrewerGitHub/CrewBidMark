//
//  CBTripDay.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CBTripDay : NSObject <NSCoding>
{
    float credit;
    NSArray * legs;
    BOOL isFirstDay;
    int reportTime;
    int releaseTime;
    int block;
}

#pragma mark INITIALIZATION
- (id)initWithCredit:(float)inCredit legs:(NSArray *)inLegs;
- (void)initializeDerivedValues;

#pragma mark ACCESSORS
- (float)credit;
- (void)setCredit:(float)inValue;
- (NSArray *)legs;
- (void)setLegs:(NSArray *)inValue;
- (BOOL)isFirstDay;
- (void)setIsFirstDay:(BOOL)inValue;
- (int)reportTime;
- (void)setReportTime:(int)inValue;
- (int)releaseTime;
- (void)setReleaseTime:(int)inValue;
- (int)block;
- (void)setBlock:(int)inValue;

#pragma mark DESCRIPTION
- (NSString *)shortCalendarText;
- (NSString *)printCalendarText;
- (NSString *)descriptionWithDate:(NSCalendarDate *)date tripDay:(int)day generic:(BOOL)generic;
- (NSString *)clipboardTextWithDate:(NSCalendarDate *)date;
- (NSString *)reportTimeWithDate:(NSCalendarDate *)date;
- (NSString *)releaseTimeWithDate:(NSCalendarDate *)date;
- (NSString *)layoverString;
- (NSString *)blockString;
- (NSString *)dutyString;
- (NSString *)payString;

@end
