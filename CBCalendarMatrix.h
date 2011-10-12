//
//  CBCalendarMatrix.h
//  CrewBid
//
//  Created by Mark on Tue Dec 02 2003.
//  Copyright © 2003 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CBCalendarMatrix : NSMatrix
{
    IBOutlet NSMatrix *dateMatrix;
    IBOutlet NSTextView *tripTextView;
    NSTextFieldCell *selectedCell;
}

#pragma mark TEXT VIEW METHODS
- (void)setTripText:(NSString *)text;

#pragma mark ACCESSORS
- (NSMatrix *)dateMatrix;
- (NSTextView *)tripTextView;
- (NSTextFieldCell *)selectedCell;
- (void)setSelectedCell:(NSTextFieldCell *)inValue;

@end
