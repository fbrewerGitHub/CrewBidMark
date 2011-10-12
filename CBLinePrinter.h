//
//  CBLinePrinter.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 30 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBLine;

@interface CBLinePrinter : NSObject
{
   IBOutlet NSView *      calendarView;
   IBOutlet NSTextField * title;
   IBOutlet NSMatrix *    dates;
   IBOutlet NSMatrix *    entries;
}

#pragma mark INITIALIZATION
- (id)initWithLine:(CBLine *)line dateStrings:(NSArray *)dateStrings trips:(NSDictionary *)trips month:(NSCalendarDate *)month base:(NSString *)base seat:(NSString *)position;

- (NSString *)calendarTitleWithLine:(CBLine *)line month:(NSCalendarDate *)month base:(NSString *)base seat:(NSString *)position;

#pragma mark PRINTING
- (void)printWithLine:(CBLine *)line trips:(NSDictionary *)trips month:(NSCalendarDate *)month;

@end
