//
//  CBTableView.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 16 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBTableView.h"
#import "CBMainWindowController.h"
#import "CBDataModel.h"

@implementation CBTableView

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
   return NSDragOperationEvery;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
   return YES;
}

- (void)keyDown:(NSEvent *)event
{
   char key = [[event charactersIgnoringModifiers] characterAtIndex:0u];
   if ('t' == key || 'T' == key) {
      tKeyDown = YES;
   } else if ('b' == key || 'B' == key) {
      bKeyDown = YES;
   } else {
      [super keyDown:event];
   }
}

- (void)keyUp:(NSEvent *)event
{
   char key = [[event charactersIgnoringModifiers] characterAtIndex:0u];
   if ('t' == key || 'T' == key) {
      tKeyDown = NO;
   } else if ('b' == key || 'B' == key) {
      bKeyDown = NO;
   } else {
      [super keyUp:event];
   }
}

- (void)mouseDown:(NSEvent *)event
{
   if (tKeyDown) {
      NSPoint clickedPoint = [self convertPoint:[event locationInWindow] fromView:nil];
      int clickedRow = [self rowAtPoint:clickedPoint];
      if (clickedRow > -1) {
         CBDataModel * dataModel = [(CBMainWindowController *)[[self window] windowController] dataModel];
         // remove top freeze if alt key down and click on largest top frozen line
         if (NSAlternateKeyMask == ([event modifierFlags] & NSAlternateKeyMask)) {
            if (clickedRow == [dataModel topFreezeIndex]) {
               [dataModel setTopFreezeIndex:-1];
            }
         // set top freeze index
         } else if (clickedRow < [dataModel bottomFreezeIndex]) {
            [dataModel setTopFreezeIndex:clickedRow];
         }
      }
   } else if (bKeyDown) {
      NSPoint clickedPoint = [self convertPoint:[event locationInWindow] fromView:nil];
      int clickedRow = [self rowAtPoint:clickedPoint];
      if (clickedRow > -1) {
         CBDataModel * dataModel = [(CBMainWindowController *)[[self window] windowController] dataModel];
         if (NSAlternateKeyMask == ([event modifierFlags] & NSAlternateKeyMask)) {
            if (clickedRow == [dataModel bottomFreezeIndex]) {
               [dataModel setBottomFreezeIndex:[[dataModel lines] count]];
            }
         } else if (clickedRow > [dataModel topFreezeIndex]) {
            [dataModel setBottomFreezeIndex:clickedRow];
         }
      }
   } else {
      [super mouseDown:event];
   }
}

@end
