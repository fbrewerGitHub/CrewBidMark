//
//  CBTableHeaderView.h
//  CrewBid
//
//  Created by Mark on 11/11/04.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBTableHeaderView : NSTableHeaderView
{
   NSTrackingRectTag we;
   NSTrackingRectTag they;
   
   int draggedColumn;
   NSTableColumn * draggedTableColumn;
}

extern NSString * CBTableHeaderViewDragPboardType;

@end
