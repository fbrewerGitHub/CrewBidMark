//
//  CBFileSelectWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jan 27 2005.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface CBFileSelectWindowController : NSWindowController
{
   // interface items
   IBOutlet NSButton *cancelButton;
   IBOutlet NSButton *defaultButton;
   IBOutlet NSTableView *fileSelectTableView;
   // file items
   NSString *directory;
   NSString *fileName;
   NSArray *fileTypes;
   NSArray *files;
}
#pragma mark INITIALIZATION
- (id)initWithDirectory:(NSString *)directoryPath file:(NSString *)filename types:(NSArray *)filetypes;

#pragma mark ACTIONS
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)defaultButtonAction:(id)sender;

#pragma mark ACCESSORS
- (NSButton *)defaultButton;
- (NSButton *)cancelButton;
- (NSTableView *)fileSelectTableView;
- (NSString *)directory;
- (void)setDirectory:(NSString *)inValue;
- (NSString *)fileName;
- (void)setFileName:(NSString *)inValue;
- (NSArray *)fileTypes;
- (void)setFileTypes:(NSArray *)inValue;
- (NSArray *)files;
- (void)setFiles:(NSArray *)inValue;

@end
