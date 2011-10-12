//
//  CBLineCalendarTripTextView.m
//  CrewBid
//
//  Created by Mark on Fri Dec 05 2003.
//  Copyright © 2003 Mark Ackerman. All rights reserved.
//

#import "CBLineCalendarTripTextView.h"


@implementation CBLineCalendarTripTextView

#pragma mark INITIALIZATION

- (id)initWithFrame:(NSRect)frame
{
   self = [super initWithFrame:frame];
   return self;
}

- (id)initWithString:(NSString *)text font:(NSFont *)font;
{
   // size of string
   NSDictionary * stringAttributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
   NSSize stringSize = [text sizeWithAttributes:stringAttributes];
  // create view using size of string
   NSRect lineTripTextViewRect = NSMakeRect(0.0, 0.0, stringSize.width + 4.0, stringSize.height + 2.0);
   if (self = [super initWithFrame:lineTripTextViewRect]) {
      [self setLineTripTextString:text];
      [self setLineTripTextFont:font];
   }
   return self;
}

- (void)dealloc
{
   [[self lineTripTextString] release];
   [super dealloc];
}

#pragma mark DRAWING
- (void)drawRect:(NSRect)rect
{
   NSDictionary * stringAttributes = [NSDictionary dictionaryWithObject:[self lineTripTextFont] forKey:NSFontAttributeName];
   [[NSColor blackColor] set];
   [NSBezierPath strokeRect:[self bounds]];
   [[self lineTripTextString] drawInRect:NSInsetRect( [self bounds], 2.0, 1.0 ) withAttributes:stringAttributes];
}

#pragma mark ACCESSORS

- (NSString *)lineTripTextString
{
   return [[lineTripTextString retain] autorelease];
}
- (void)setLineTripTextString:(NSString *)inValue
{
   if(lineTripTextString != inValue)
   {
      [lineTripTextString release];
      lineTripTextString = [inValue retain];
   }
}

- (NSFont *)lineTripTextFont
{
   return [[lineTripTextFont retain] autorelease];
}
- (void)setLineTripTextFont:(NSFont *)inValue
{
   if(lineTripTextFont != inValue)
   {
      [lineTripTextFont release];
      lineTripTextFont = [inValue retain];
   }
}

@end
