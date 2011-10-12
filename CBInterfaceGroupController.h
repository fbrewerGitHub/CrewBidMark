//
//  CBInterfaceGroupController.h
//  CrewBid
//
//  Created by Mark on Sat May 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBInterfaceItemController.h"

@interface CBInterfaceGroupController : CBInterfaceItemController
{
   IBOutlet NSButton * checkbox;
   IBOutlet NSTextField * textField;
}

@end
