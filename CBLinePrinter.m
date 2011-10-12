//
//  CBLinePrinter.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 30 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBLinePrinter.h"
#import "CBLine.h"
#import "CBTrip.h"
#import "CBMatrixController.h"
#import "CBLineCalendarTripTextView.h"

@implementation CBLinePrinter

#pragma mark INITIALIZATION
- (id)initWithLine:(CBLine *)line dateStrings:(NSArray *)dateStrings trips:(NSDictionary *)trips month:(NSCalendarDate *)month base:(NSString *)base seat:(NSString *)position
{
   if (self = [super init]) {
      // load nib that contains calendar view
      [NSBundle loadNibNamed:@"CBLinePrintCalendar" owner:self];
      // set title
      [title setStringValue:[self calendarTitleWithLine:line month:month base:base seat:position]];
      // set dates
      CBMatrixController * datesController = [[CBMatrixController alloc] initWithMatrix:dates data:dateStrings];
      [datesController reloadData];
      [datesController release];
      // set trips entries
      CBMatrixController * tripsController = [[CBMatrixController alloc] initWithMatrix:entries data:[line printCalendarEntries]];
      [tripsController reloadData];
      [tripsController release];
      // print
      [self printWithLine:line trips:trips month:month];
   }
   return self;
}

- (void)dealloc
{
   [calendarView release];
   [super dealloc];
}

- (NSString *)calendarTitleWithLine:(CBLine *)line month:(NSCalendarDate *)month base:(NSString *)base seat:(NSString *)position
{
   NSString * calendarTitle = [NSString stringWithFormat:@"%@ %@ %@ - Line %d", [month descriptionWithCalendarFormat:@"%B %Y"], base, position, [line number]];
   return calendarTitle;
}

#pragma mark PRINTING

- (void)printWithLine:(CBLine *)line trips:(NSDictionary *)trips month:(NSCalendarDate *)month
{
   // page size is 540 by 720 with 1/2 in margins
   const float PAGE_WIDTH = 540.0;
   const float PAGE_HEIGHT = 720.0;
   NSRect pageRect = NSMakeRect(0.0, 0.0, PAGE_WIDTH, PAGE_HEIGHT);
   // create view that will be printed
   NSView * pageView = [[NSView alloc] initWithFrame:pageRect];
   // point to insert views in page view
   float insertX = 0.0;
   float insertY = PAGE_HEIGHT;
   // place calendar view at top left corner of page view
   float calendarViewHeight = NSHeight([calendarView frame]);
   float calendarBottom = PAGE_HEIGHT - calendarViewHeight;
   insertY -= calendarViewHeight;
   [calendarView setFrameOrigin:NSMakePoint(0.0, calendarBottom)];
   [pageView addSubview:calendarView];
//   [printCalendarView release]; // released in dealloc
   // create trip data and add to page view, adding only one instance of each trip number
   NSMutableSet * tripSet = [NSMutableSet set];
   NSEnumerator * tripsEnumerator = [[line trips] objectEnumerator];
   NSDictionary * tripDictionary = nil;
   BOOL nextColumn = NO;
   while (tripDictionary = [tripsEnumerator nextObject]) {
      // if the trip hasn't already been added to page view, add it
      NSString * tripNumber = [tripDictionary objectForKey:CBLineTripNumberKey];
      if (![tripSet containsObject:tripNumber]) {
         // add trip number to trip set
         [tripSet addObject:tripNumber];
         // make view of trip text
         CBTrip * trip = [trips objectForKey:tripNumber];
         if (trip) {
            // create view with text for trip
            int tripDay = [(NSNumber *)[tripDictionary objectForKey:CBLineTripDateKey] intValue];
            NSCalendarDate *date = [month dateByAddingYears:0 months:0 days:(tripDay - 1) hours:0 minutes:0 seconds:0];
            NSString *faPos = [tripDictionary objectForKey:CBLineTripPositionKey];
            NSString * tripText = nil;
            if (faPos) {
               tripText = [trip descriptionWithDate:date generic:YES faPosition:faPos];
            } else {
               tripText = [trip descriptionWithDate:date generic:YES];
            }
            CBLineCalendarTripTextView * tripTextView = [[CBLineCalendarTripTextView alloc] initWithString:tripText font:[NSFont fontWithName:@"Courier" size:7]];
            // determine location for trip view in page view
            float tripViewHeight = NSHeight([tripTextView frame]);
            insertY = insertY - tripViewHeight - 4;
            // go to right column if left column is full
            if( insertY < 0 )
            {
               nextColumn = YES;
               insertX = NSWidth( [tripTextView frame] ) + 4;
               insertY = calendarBottom - NSHeight( [tripTextView frame] ) - 4;
            }
            // set trip view's origin and add to page view
            [tripTextView setFrameOrigin:NSMakePoint( insertX, insertY )];
            [pageView addSubview:tripTextView];
            [tripTextView release];
         }
      }
   }
   // create and set up print operation for page view
   NSPrintOperation * printOperation = [NSPrintOperation printOperationWithView:pageView];
   // set margins (1/2 inch or 36.0 points) and view location in page
   NSPrintInfo * printInfo = [printOperation printInfo];
   [printInfo setTopMargin:36.0];
   [printInfo setBottomMargin:36.0];
   [printInfo setLeftMargin:36.0];
   [printInfo setRightMargin:36.0];
   [printInfo setVerticallyCentered:NO];
   [printInfo setHorizontallyCentered:NO];
   // print page and release page view
   [printOperation runOperation];
   [pageView release];
}

@end
