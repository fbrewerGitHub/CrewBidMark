//
//  CBFormMatrixController.m
//  CrewBid
//
//  Created by Mark Ackerman on Sat May 29 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBFormMatrixController.h"


@implementation CBFormMatrixController

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
   
   // set of represented objects for cells that are selected
   NSMutableDictionary * nonZeroCellValues = [NSMutableDictionary dictionary];
   NSEnumerator * cellsEnumerator = [[(NSMatrix *)interfaceItem cells] objectEnumerator];
   NSFormCell * cell = nil;
   id cellValue = nil;
   
   while (cell = [cellsEnumerator nextObject]) {
   
      cellValue = [cell objectValue];
      
      if (cellValue && ![self cellObjectValue:cellValue IsEqualToZeroValue:[self zeroCellValue]]) {

         [nonZeroCellValues setObject:cellValue forKey:[cell title]];
      }
/*      if (0.0 != [cell floatValue]) {
         cellTitle = [cell title];
         [nonZeroCellValues setObject:[NSNumber numberWithFloat:[cell floatValue]] forKey:cellTitle];
      }
*/
   }
	return [NSDictionary dictionaryWithDictionary:nonZeroCellValues];
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
	// sublcasses must override and update interface item with data value
   
   NSDictionary * nonZeroCellValues = (NSDictionary *)dataValue;
   NSEnumerator * cellEnumerator = [[(NSMatrix *)interfaceItem cells] objectEnumerator];
   NSFormCell * cell = nil;
//   NSNumber * cellValue = nil;
   id cellValue = nil;

   while (cell = [cellEnumerator nextObject]) {
   
      cellValue = [nonZeroCellValues objectForKey:[cell title]];
      
//      if (cellValue == nil) {
//         cellValue = [NSDecimalNumber zero];
//      }
      
      if (cellValue && ![self cellObjectValue:cellValue IsEqualToZeroValue:[self zeroCellValue]]) {

         [cell setObjectValue:[nonZeroCellValues objectForKey:[cell title]]];
//         [cell setFloatValue:[cellValue floatValue]];
      } else {

         [cell setObjectValue:[self zeroCellValue]];
//         [cell setFloatValue:0.0];
      }
   }
}

- (id)zeroCellValue
{
   // subclasses can override to return different cell object value that
   // represents zero for the object value type
   
   // this works for float or integer text fields
   return [NSDecimalNumber zero];
}

- (BOOL)cellObjectValue:(id)cellValue IsEqualToZeroValue:(id)zeroValue
{
   return [(NSDecimalNumber *)cellValue isEqualToNumber:(NSDecimalNumber *) zeroValue];
}

@end
