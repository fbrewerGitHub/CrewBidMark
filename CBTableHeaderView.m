//
//  CBTableHeaderView.m
//  CrewBid
//
//  Created by Mark on 11/11/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import "CBTableHeaderView.h"

// drag and drop pasteboard type
NSString * CBTableHeaderViewDragPboardType = @"CBTableHeaderView Drag Pasteboard Type";


@implementation CBTableHeaderView

- (id)initWithFrame:(NSRect)frame
{
   if (self = [super initWithFrame:frame])
   {
      [self registerForDraggedTypes:[NSArray arrayWithObject:CBTableHeaderViewDragPboardType]];
   }
   return self;
}

/*
- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}
*/

#pragma mark DRAGGING SOURCE METHODS

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
   return NSDragOperationMove;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
   return YES;
}

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)point operation:(NSDragOperation)operation
{
/*   if (NSDragOperationMove == operation)
   {
      [[self tableView] removeTableColumn:draggedTableColumn];
   }
   else */if (NSDragOperationNone == operation)
   {
      [[self tableView] addTableColumn:draggedTableColumn];
      [[self tableView] moveColumn:[[[self tableView] tableColumns] count] - 1 toColumn:draggedColumn];
   }
}

#pragma mark DRAGGING DESTINATION METHODS

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
   NSLog(@"draggingEntered:");

   NSPasteboard * pboard = nil;;
   NSDragOperation dragOperation = NSDragOperationNone;
   NSPoint columnPoint = NSMakePoint(0, 0);
   int columnEntered = 0;

   dragOperation = [sender draggingSourceOperationMask];
   pboard = [sender draggingPasteboard];

   if ([[pboard types] containsObject:CBTableHeaderViewDragPboardType])
   {
      if (dragOperation & NSDragOperationMove)
      {
         dragOperation =  NSDragOperationMove;
         
         columnPoint = [self convertPoint:[sender draggingLocation] fromView:nil];
         columnEntered = [self columnAtPoint:columnPoint];
         draggedTableColumn = [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:CBTableHeaderViewDragPboardType]];
         [[self tableView] addTableColumn:draggedTableColumn];
         if (columnEntered > 0)
         {
            [[self tableView] moveColumn:[[[self tableView] tableColumns] count] - 1 toColumn:columnEntered];
         }
      }
   }
   return dragOperation;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
   NSLog(@"draggingUpdated:");
   return NSDragOperationMove;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
   NSLog(@"draggingExited:");
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
   NSLog(@"prepareForDragOperation:");
   return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
   NSLog(@"performDragOperation:");
   return YES;
}

#pragma mark EVENT HANDLING

- (void)mouseDown:(NSEvent *)event
{
   NSImage * dragImage = nil;
   NSPoint columnPoint = NSMakePoint(0, 0);
   NSRect columnHeaderRect = NSMakeRect(0,0,0,0);
   NSAttributedString * headerCellString = nil;
   NSRect dragImageBounds = NSMakeRect(0,0,0,0);
   NSPasteboard * pboard = nil;
   float defaultLineWidth = 0.0;
   NSData * dragColumnData = nil;

   // if option key is down, start column drag between table views
   // else drag column within table view
   if (NSAlternateKeyMask == ([event modifierFlags] & NSAlternateKeyMask))
   {
      // create drag image
      columnPoint = [self convertPoint:[event locationInWindow] fromView:nil];
      draggedColumn = [self columnAtPoint:columnPoint];
      draggedTableColumn = [[[self tableView] tableColumns] objectAtIndex:draggedColumn];
      headerCellString = [[draggedTableColumn headerCell] attributedStringValue];
      columnHeaderRect = [self headerRectOfColumn:draggedColumn];
      dragImage = [[NSImage alloc] initWithSize:columnHeaderRect.size];
      dragImageBounds.origin = NSMakePoint(0, 0);
      dragImageBounds.size = columnHeaderRect.size;
      [dragImage lockFocus];
      [[NSColor redColor] set];
      defaultLineWidth = [NSBezierPath defaultLineWidth];
      [headerCellString drawInRect:dragImageBounds];
      [NSBezierPath setDefaultLineWidth:1.0];
      [NSBezierPath strokeRect:dragImageBounds];
      [dragImage unlockFocus];
      [NSBezierPath setDefaultLineWidth:defaultLineWidth];
      [dragImage dissolveToPoint:NSZeroPoint fraction:0.5];
      
      // copy column to pasteboard
      pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
      [pboard declareTypes:[NSArray arrayWithObject:CBTableHeaderViewDragPboardType] owner:self];
      dragColumnData = [NSArchiver archivedDataWithRootObject:draggedTableColumn];
      [pboard setData:dragColumnData forType:CBTableHeaderViewDragPboardType];
      
      // remove dragged table column
      [[self tableView] removeTableColumn:draggedTableColumn];
      
      // start drag
      [self dragImage:dragImage 
         at:NSMakePoint(columnHeaderRect.origin.x, columnHeaderRect.origin.y + columnHeaderRect.size.height)  
         offset:NSMakeSize(0, 0) 
         event:event 
         pasteboard:[NSPasteboard pasteboardWithName:NSDragPboard] 
         source:self 
         slideBack:YES];
      
      [dragImage release];
   }
   else
   {
      [super mouseDown:event];
   }
}

@end
