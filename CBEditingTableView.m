//
//  CBEditingTableView.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/11/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CBEditingTableView.h"


@implementation CBEditingTableView

- (void)mouseDown:(NSEvent *)event
{
    NSPoint windowPoint = [event locationInWindow];
    NSPoint clickedPoint = [self convertPoint:windowPoint fromView:nil];
    int clickedRow = [self rowAtPoint:clickedPoint];
    int clickedColumn = [self columnAtPoint:clickedPoint];
    NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:clickedColumn];
    id dataCell = [tableColumn dataCell];
    if ([tableColumn isEditable] && [dataCell isKindOfClass:[NSTextFieldCell class]])
    {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
        [self editColumn:clickedColumn row:clickedRow withEvent:event select:YES];
    }
    else
    {
        [super mouseDown:event];
    }
}

- (void)textDidEndEditing:(NSNotification *) notification
{
    NSDictionary *userInfo = [notification userInfo];


    int textMovement = [[userInfo valueForKey:@"NSTextMovement"] intValue];

    if (textMovement == NSReturnTextMovement
        || textMovement == NSTabTextMovement
        || textMovement == NSBacktabTextMovement) {

        NSMutableDictionary *newInfo;
        newInfo = [NSMutableDictionary dictionaryWithDictionary: userInfo];

        [newInfo setObject: [NSNumber numberWithInt: NSCancelTextMovement /*NSIllegalTextMovement*/]
                 forKey: @"NSTextMovement"];

        notification =
            [NSNotification notificationWithName: [notification name]
                                       object: [notification object]
                                       userInfo: newInfo];

    }

    [super textDidEndEditing: notification];

    NSTextView *textView = [notification object];
    NSRect rect = [textView frame];
    int row = [self rowAtPoint:rect.origin];
    int col = [self columnAtPoint:rect.origin];
    [self editColumn:col row:row withEvent:[NSApp currentEvent] select:YES];
}

@end
