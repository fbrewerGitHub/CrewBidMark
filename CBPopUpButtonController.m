//
//  CBPopUpButtonController.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu May 13 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBPopUpButtonController.h"


@implementation CBPopUpButtonController

#pragma mark BASE CLASS METHOD OVERRIDES

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
	return [NSNumber numberWithInt:[(NSPopUpButton *)[self interfaceItem] indexOfSelectedItem]];
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
	// sublcasses must override and update interface item with data value
	[(NSPopUpButton *)[self interfaceItem] selectItemAtIndex:[(NSNumber *)dataValue intValue]];
}

@end
