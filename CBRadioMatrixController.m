//
//  CBRadioMatrixController.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 17 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBRadioMatrixController.h"


@implementation CBRadioMatrixController

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
   NSMatrix * matrix = (NSMatrix *)[self interfaceItem];
   int row = 0;
   int col = 0;
   [matrix getRow:&row column:&col ofCell:[matrix selectedCell]];
   int cellIndex = row * [matrix numberOfColumns] + col;
	return [NSNumber numberWithInt:cellIndex];
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
	// sublcasses must override and update interface item with data value
   NSMatrix * matrix = (NSMatrix *)[self interfaceItem];
   int cellIndex = [(NSNumber *)dataValue intValue];
   int columns = [matrix numberOfColumns];
   int row = cellIndex / columns;
   int col = cellIndex % columns;
   [matrix selectCellAtRow:row column:col];
}

@end
