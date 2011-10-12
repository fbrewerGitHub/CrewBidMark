//
//  CBCheckboxController.m
//  CrewBid
//
//  Created by Mark on Sun Apr 04 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBCheckboxController.h"

@implementation CBCheckboxController

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
   BOOL checked = (NSOnState == [(NSButton *)interfaceItem state]);
   return [NSNumber numberWithBool:checked];
//	return [NSNumber numberWithInt:[interfaceItem state]];
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
//   NSLog(@"updating %@ with: %@", [self identifier], dataValue);

	// sublcasses must override and return selector that will update value
	// for object represented by the interface item
   BOOL checked = [(NSNumber *)dataValue boolValue];
   if (YES == checked) {
      [(NSButton *)interfaceItem setState:NSOnState];
   } else {
      [(NSButton *)interfaceItem setState:NSOffState];
   }
//	[interfaceItem setState:[(NSNumber *)dataValue intValue]];
}

@end
