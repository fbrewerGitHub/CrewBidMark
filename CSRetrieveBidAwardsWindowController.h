//
//  CSRetrieveBidAwardsWindowController.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 7/22/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSBidFileDownloadWindowController.h"


@interface CSRetrieveBidAwardsWindowController : CSBidFileDownloadWindowController
{

}

#pragma mark Initialization
- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;

@end
