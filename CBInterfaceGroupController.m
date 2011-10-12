//
//  CBInterfaceGroupController.m
//  CrewBid
//
//  Created by Mark on Sat May 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBInterfaceGroupController.h"


@implementation CBInterfaceGroupController

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
	return [interfaceItem objectValue];
}

@end
