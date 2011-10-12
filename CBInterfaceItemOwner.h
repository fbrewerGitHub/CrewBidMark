//
//  CBInterfaceItemOwner.h
//  CrewBid
//
//  Created by Mark Ackerman on Sat May 22 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//
//  The purpose of this protocol is to define a class that is able to
//  access the data model.

#import <Cocoa/Cocoa.h>

@class CBDocument;
@class CBDataModel;

@protocol CBInterfaceItemOwner

- (CBDocument *)document;
- (CBDataModel *)dataModel;
- (NSUndoManager *)undoManager;

@end
