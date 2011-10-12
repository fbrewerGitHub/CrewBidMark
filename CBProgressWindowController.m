//
//  CBProgressWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 29 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBProgressWindowController.h"


@implementation CBProgressWindowController

#pragma mark INITIALIZATION

- (id)init
{
	if (self = [super initWithWindowNibName:@"CBProgress"]) {
      [self window];
   }
	return self;
   
}

- (void)awakeFromNib
{
   [progressIndicator setUsesThreadedAnimation:YES];   
   [progressIndicator startAnimation:nil];
   [[self window] center];
}

#pragma mark INTERFACE MANAGEMENT

- (void)setTitle:(NSString *)title
{
   [[self window] setTitle:title];
}

- (void)setProgressText:(NSString *)progressText
{
   [progressTextField setStringValue:progressText];
   [progressTextField sizeToFit];
}

- (void)enableCancelButton
{
   [[self cancelButton] setEnabled:YES];
}
- (void)disableCancelButton
{
   [[self cancelButton] setEnabled:NO];
}

#pragma mark ACCESSORS

- (NSTextField *)progressTextField { return progressTextField; }
- (NSProgressIndicator *)progressIndicator { return progressIndicator; }
- (NSButton *)cancelButton { return cancelButton; }

@end
