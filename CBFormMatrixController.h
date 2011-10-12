//
//  CBFormMatrixController.h
//  CrewBid
//
//  Created by Mark Ackerman on Sat May 29 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBInterfaceItemController.h"


@interface CBFormMatrixController : CBInterfaceItemController
{

}

- (id)zeroCellValue;
- (BOOL)cellObjectValue:(id)cellValue IsEqualToZeroValue:(id)zeroValue;

@end
