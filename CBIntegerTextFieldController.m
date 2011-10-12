//
//  CBIntegerTextFieldController.m
//  CrewBid
//
//  Created by Mark Ackerman on Sat May 22 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBIntegerTextFieldController.h"


@implementation CBIntegerTextFieldController

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
	return [NSNumber numberWithInt:[interfaceItem intValue]];
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
	// sublcasses must override and return selector that will update value
	// for object represented by the interface item
	[interfaceItem setIntValue:[dataValue intValue]];
}

@end
