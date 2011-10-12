//
//  CBBidFileWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Sat Jul 24 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBBidFileWindowController.h"
#import "CBBidFileDownload.h"

@implementation CBBidFileWindowController

#pragma mark INITIALIZATION

- (void)dealloc
{
   [bidFileDownload release];
   [super dealloc];
}

#pragma mark BID FILE METHODS

- (void)handleDownloadedBidFile:(NSString *)path
{
   // should be overridden by subclasses to handle downloaded
   // bid data file or bid receipt
}

- (void)cancelBidFileDownload
{
   [self setBidFileDownload:nil];
}

- (void)handleDownloadError
{
   [self setBidFileDownload:nil];
}

#pragma mark ACCESSORS

- (CBBidFileDownload * )bidFileDownload { return bidFileDownload; }
- (void)setBidFileDownload:(CBBidFileDownload *)inValue
{
   if (bidFileDownload != inValue) {
      [bidFileDownload release];
      bidFileDownload = [inValue retain];
   }
}

@end
