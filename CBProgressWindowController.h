//
//  CBProgressWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 29 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface CBProgressWindowController : NSWindowController
{
   IBOutlet NSTextField *         progressTextField;
   IBOutlet NSProgressIndicator * progressIndicator;
   IBOutlet NSButton *            cancelButton;
}

#pragma mark INTERFACE MANAGEMENT
- (void)setTitle:(NSString *)title;
- (void)setProgressText:(NSString *)progressText;
- (void)enableCancelButton;
- (void)disableCancelButton;

#pragma mark ACCESSORS
- (NSTextField *)progressTextField;
- (NSProgressIndicator *)progressIndicator;
- (NSButton *)cancelButton;

@end
