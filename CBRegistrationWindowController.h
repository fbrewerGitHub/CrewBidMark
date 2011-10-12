//
//  CBRegistrationWindowController.h
//  CrewBid
//
//  Created by Mark on 3/2/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import "CBMainPreferencesWindowController.h"


@interface CBRegistrationWindowController : CBMainPreferencesWindowController
{
   IBOutlet NSButton *okButton;
}

- (NSButton *)okButton;

extern NSString *CBRegistrationWindowControllerDidFinish;

@end
