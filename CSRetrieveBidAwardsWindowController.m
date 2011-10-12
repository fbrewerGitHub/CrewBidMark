//
//  CSRetrieveBidAwardsWindowController.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 7/22/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSRetrieveBidAwardsWindowController.h"

#import "CSBidFileDownload.h"


@implementation CSRetrieveBidAwardsWindowController

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;
{
    if (self = [super initWithWindowNibName:@"RetrieveBidAwards" bidPeriod:bidPeriod])
    {
        [[self bidFileDownload] setType:CSBidFileDownloadBidAwardsType];
    }
    return self;
}

#pragma mark
#pragma mark Actions
#pragma mark

- (void)bidFileDownloadDidFinish
{
    [NSApp endSheet:[self window]];
    [[self window] orderOut:nil];
    [[self document] performSelector:@selector(showBidAwards:)];
    [self autorelease];
}

@end
