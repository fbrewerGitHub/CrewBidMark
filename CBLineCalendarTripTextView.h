//
//  CBLineCalendarTripTextView.h
//  CrewBid
//
//  Created by Mark on Fri Dec 05 2003.
//  Copyright © 2003 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBLineCalendarTripTextView : NSView
{
   NSString * lineTripTextString;
   NSFont * lineTripTextFont;
}

#pragma mark INITIALIZATION
- (id)initWithString:(NSString *)bidText font:(NSFont *)font;

#pragma mark ACCESSORS
- (NSString *)lineTripTextString;
- (void)setLineTripTextString:(NSString *)inValue;
- (NSFont *)lineTripTextFont;
- (void)setLineTripTextFont:(NSFont *)inValue;

@end
