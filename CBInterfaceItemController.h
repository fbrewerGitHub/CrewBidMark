//
//  CBInterfaceItemController.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun Apr 11 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//
//  "owner" must implement a "dataModel" method that will return an object
//  that has an instance variable of "identifier".  The dataModel object
//  should implement a set accessor that posts a notification that contains
//  the "identifier" instance variable as the object for the key of the
//  notification name.  The dataModel object must also implement a method
//  that returns the notification name (notificationForIdentifier:).
//

#import <Cocoa/Cocoa.h>
#import "CBInterfaceItemOwner.h"

@interface CBInterfaceItemController : NSObject
{
	IBOutlet id <CBInterfaceItemOwner> owner;
   IBOutlet NSControl * interfaceItem;
   NSString * identifier;
	NSString * notificationName;
	NSString * keyPath;
   NSString *undoActionName;
}

#pragma mark ACTIONS
- (IBAction)interfaceItemAction:(id)sender;
- (id)interfaceItemValue;

#pragma mark INTERFACE UPDATING
- (void)updateInterfaceItem:(NSNotification *)notification;
- (void)updateInterfaceItemWithValue:(id)dataValue;

#pragma mark ACCESSORS
- (id <CBInterfaceItemOwner>)owner;
- (NSControl *)interfaceItem;
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)inValue;
- (NSString *)notificationName;
- (void)setNotificationName:(NSString *)inValue;
- (NSString *)keyPath;
- (void)setKeyPath:(NSString *)inValue;
- (NSString *)undoActionName;
- (void)setUndoActionName:(NSString *)inValue;

@end
