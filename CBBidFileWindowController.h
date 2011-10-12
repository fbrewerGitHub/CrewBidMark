//
//  CBBidFileWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Sat Jul 24 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBBidFileDownload;


@interface CBBidFileWindowController : NSWindowController
{
   CBBidFileDownload * bidFileDownload;
}

#pragma mark BID FILE HANDLING
- (void)handleDownloadedBidFile:(NSString *)path;
- (void)cancelBidFileDownload;
- (void)handleDownloadError;

#pragma mark ACCESSORS
- (CBBidFileDownload * )bidFileDownload;
- (void)setBidFileDownload:(CBBidFileDownload *)inValue;

@end
