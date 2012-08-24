//
//  CBInterfaceItemController.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun Apr 11 2004.
//  Copyright © Mark Ackerman. All rights reserved.
//

#import "CBInterfaceItemController.h"
#import "CBDataModel.h"

@implementation CBInterfaceItemController

- (id)init
{
	if (self = [super init]) {
		// no initialization required
		// owner must set identifier in its awakeFromNib method
	}
	return self;
}

- (void)dealloc
{
   [identifier release];
   [notificationName release];
   [keyPath release];
   [undoActionName release];
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [super dealloc];
}

#pragma mark ACTION

- (IBAction)interfaceItemAction:(id)sender
{
   // force end editing for all text fields so that values are entered
   [[[self interfaceItem] window] endEditingFor:nil];
   // set undo manager action name
//   [[[self owner] undoManager] setActionName:[self undoActionName]];
   // set data model
    [[[self owner] dataModel] setValue:[self interfaceItemValue] forKey:[self identifier]];
//   [[[self owner] dataModel] takeValue:[self interfaceItemValue] forKey:[self identifier]];
   //
//	[[self owner] setValue:[self interfaceItemValue] forKeyPath:[self keyPath]];
}

- (id)interfaceItemValue
{
	// subclasses must override and return value for the object represented
	// by the interface item
	return [interfaceItem objectValue];
}

#pragma mark INTERFACE UPDATING

- (void)updateInterfaceItem:(NSNotification *)notification
{
	// update interface item with notification user info, if it exists;
	// otherwise update interface item with value from data model
	NSDictionary * userInfo = nil;
	id dataValue = nil;
//	NSNumber * dataValue = nil;
	if ((userInfo = [notification userInfo]) && (dataValue = [userInfo objectForKey:[self notificationName]])) {
	} else {
		dataValue = [[[self owner] dataModel] valueForKey:[self identifier]];
//		dataValue = [[self owner] valueForKeyPath:[self keyPath]];
	}
	if (dataValue) {
		[self updateInterfaceItemWithValue:dataValue];
	}
}

- (void)updateInterfaceItemWithValue:(id)dataValue
{
	// sublcasses must override and update interface item with data value
	[interfaceItem setObjectValue:dataValue];
}

#pragma mark ACCESSORS

- (id <CBInterfaceItemOwner>)owner { return owner; }

- (NSControl *)interfaceItem { return interfaceItem; }

- (NSString *)identifier { return identifier; }
- (void)setIdentifier:(NSString *)inValue
{
	if (inValue != identifier) {
		// set identifier variable
		[identifier release];
		identifier = [inValue copy];
		// set notification name variable
		NSString * name = [[owner dataModel] notificationNameForIdentifier:[self identifier]];
		[self setNotificationName:name];
		// set key path variable
		NSString * path = [NSString stringWithFormat:@"dataModel.%@", [self identifier]];
		[self setKeyPath:path];
		// register as notificiation observer
		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(updateInterfaceItem:)
			name:[self notificationName]
			object:[[self owner] document]];
		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(updateInterfaceItem:)
			name:CBDataModelUnarchivedNotification
			object:[[self owner] document]];
	}
}

- (NSString *)notificationName { return notificationName; }
- (void)setNotificationName:(NSString *)inValue
{
	if (inValue != notificationName) {
		[notificationName release];
		notificationName = [inValue copy];
	}
}

- (NSString *)keyPath {	return keyPath; }
- (void)setKeyPath:(NSString *)inValue
{
	if (inValue != keyPath) {
		[keyPath release];
		keyPath = [inValue copy];
	}
}

- (NSString *)undoActionName
{
   return undoActionName;
}
- (void)setUndoActionName:(NSString *)inValue
{
   if (undoActionName != inValue) {
      [undoActionName release];
      undoActionName = [inValue copy];
   }
}

@end
