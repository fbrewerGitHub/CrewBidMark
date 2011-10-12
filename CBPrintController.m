//
//  CBPrintController.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 30 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBLinePrinter.h"
#import "CBDataModel.h"

@implementation CBMainWindowController ( CBPrintController )

#pragma mark PRINTING

- (IBAction)printLine:(id)sender
{
   CBDataModel * dataModel = [self dataModel];
   int selectedLine = [[self linesTableView] selectedRow];
   if (selectedLine > -1) {
      CBLine * line = [[dataModel lines] objectAtIndex:selectedLine];
      CBLinePrinter * linePrinter = [[CBLinePrinter alloc] initWithLine:line dateStrings:[self calendarDateStringsWithMonth:[dataModel month]] trips:[dataModel trips] month:[dataModel month] base:[dataModel crewBase] seat:[dataModel crewPosition]];
      [linePrinter release];
   }
}


@end
