//
//  CBBidFileOpener.h
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 29 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBProgressWindowController;

@interface CBBidFileOpener : NSObject
{
   NSString * filePath;
   NSWindow * modalWindow;
   CBProgressWindowController * progressController;
   BOOL progressControllerCreated;
}

#pragma mark INITIALIZATION
- (id)initWithFile:(NSString *)path modalWindow:(NSWindow *)window progressController:(CBProgressWindowController *)controller;

#pragma mark FILE METHODS
- (BOOL)openFile;

#pragma mark ACCESSORS
- (NSString *)filePath;
- (void)setFilePath:(NSString *)inValue;
- (NSWindow *)modalWindow;
- (CBProgressWindowController *)progressController;
- (BOOL)progressControllerCreated;
- (void)setProgressControllerCreated:(BOOL)inValue;
@end
