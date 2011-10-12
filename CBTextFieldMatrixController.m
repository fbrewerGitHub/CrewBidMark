//
//  CBTextFieldMatrixController.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri May 28 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBTextFieldMatrixController.h"


@implementation CBTextFieldMatrixController

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
   
   // set of represented objects for cells that are selected
   NSMutableDictionary *nonZeroCellValues = [NSMutableDictionary dictionary];
   NSEnumerator *cellEnumerator = [[(NSMatrix *)interfaceItem cells] objectEnumerator];
   NSTextFieldCell *cell = nil;
   id cellRepresentedObject = nil;
   while (cell = [cellEnumerator nextObject]) {
      if (0.0 != [cell floatValue]) {
         cellRepresentedObject = [cell representedObject];
         if (cellRepresentedObject) {
            [nonZeroCellValues setObject:[NSNumber numberWithFloat:[cell floatValue]] forKey:cellRepresentedObject];
         }
      }
   }
	return [NSDictionary dictionaryWithDictionary:nonZeroCellValues];
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
	// sublcasses must override and update interface item with data value
   
   NSDictionary *nonZeroCellValues = (NSDictionary *)dataValue;
   NSEnumerator *cellEnumerator = [[(NSMatrix *)interfaceItem cells] objectEnumerator];
   NSTextFieldCell *cell = nil;
   id cellRepresentedObject = nil;
   NSNumber *cellValue = nil;
   while (cell = [cellEnumerator nextObject]) {
      cellRepresentedObject = [cell representedObject];
      if (cellRepresentedObject && (cellValue = [nonZeroCellValues objectForKey:cellRepresentedObject])) {
         [cell setFloatValue:[cellValue floatValue]];
      } else {
         [cell setFloatValue:0.0];
      }
   }
}

@end
