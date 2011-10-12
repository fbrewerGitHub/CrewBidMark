//
//  CBButtonMatrixController.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu May 27 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBButtonMatrixController.h"


@implementation CBButtonMatrixController

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
   
   // set of represented objects for cells that are selected
   NSMutableSet * selectedCellObjects = [NSMutableSet set];
   NSEnumerator * cellEnumerator = [[(NSMatrix *)interfaceItem cells] objectEnumerator];
   NSButtonCell * cell = nil;
   while (cell = [cellEnumerator nextObject]) {
      if (NSOnState == [cell state]) {
         // add represented object, if cell has one, otherwise add cell title
         id cellRepresentedObject = [cell representedObject];
         if (cellRepresentedObject) {
            [selectedCellObjects addObject:cellRepresentedObject];
         } else {
            [selectedCellObjects addObject:[cell title]];
         }
      }
   }
	return [NSSet setWithSet:selectedCellObjects];
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
	// sublcasses must override and update interface item with data value
   
   NSSet * selectedCellObjects = (NSSet *)dataValue;
   NSEnumerator * cellEnumerator = [[(NSMatrix *)interfaceItem cells] objectEnumerator];
   NSButtonCell * cell = nil;
   while (cell = [cellEnumerator nextObject]) {
      // cell object is either cell represented object or cell title
      id cellObject = [cell representedObject];
      if (!cellObject) {
         cellObject = [cell title];
      }
      if (cellObject && [selectedCellObjects containsObject:cellObject]) {
         [cell setState:NSOnState];
      } else {
         [cell setState:NSOffState];
      }
   }
}

@end
