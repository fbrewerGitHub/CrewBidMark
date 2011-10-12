//
//  CSPrintView.m
//  CrewBid
//
//  Created by Mark Ackerman on 10/23/07.
//  Copyright 2007 Mark Ackerman. All rights reserved.
//

#import "CSPrintView.h"


@implementation CSPrintView

- (id)initWithFrame:(NSRect)frame
{
	// 8 1/2 by 11 is 612 by 792 points
	// page size is 540 by 720 with 1/2 in margins
//	const float PAGE_WIDTH = 540.0;
//	const float PAGE_HEIGHT = 720.0;
	// create and set up print operation for page view
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:self];
	// set margins (1/2 inch or 36.0 points) and view location in page
	NSPrintInfo * printInfo = [printOperation printInfo];
	[printInfo setTopMargin:36.0];
	[printInfo setBottomMargin:36.0];
	[printInfo setLeftMargin:36.0];
	[printInfo setRightMargin:36.0];
	[printInfo setVerticallyCentered:NO];
	[printInfo setHorizontallyCentered:NO];

    if (self = [super initWithFrame:frame]) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

@end
