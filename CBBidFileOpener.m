//
//  CBBidFileOpener.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 29 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBBidFileOpener.h"
#import "CBProgressWindowController.h"

@implementation CBBidFileOpener

#pragma mark INITIALIZATION

- (id)initWithFile:(NSString *)path modalWindow:(NSWindow *)window progressController:(CBProgressWindowController *)controller
{
   if (self = [super init]) {

      [self setFilePath:path];

      modalWindow = window;

      if (nil == controller) {
         progressController = [[CBProgressWindowController alloc] init];
         [self setProgressControllerCreated:YES];

      } else {
         progressController = controller;
         [self setProgressControllerCreated:NO];
      }
   }
   return self;
}

- (void)dealloc
{
   [filePath release];
   if ([self progressControllerCreated]) {
      [progressController release];
   }
   [super dealloc];
}

#pragma mark FILE METHODS

- (void)incrementProgressIndicator:(NSNotification *)notification
{
   NSProgressIndicator * pi = [[self progressController] progressIndicator];
   int number = [[[notification userInfo] objectForKey:@"number"] intValue];
   [pi setMaxValue:(double)number];
   [pi incrementBy:1.0];
   [pi displayIfNeeded];
}

- (BOOL)openFile
{
   BOOL fileOpened = NO;

   NSString * filename = [[[self filePath] lastPathComponent] stringByDeletingPathExtension];

   [[self progressController] setProgressText:[NSString stringWithFormat:@"Opening file %@...", filename]];
   [[self progressController] disableCancelButton];

   if (nil == modalWindow) {

      [[self progressController] setTitle:@"Open file..."];
      [[[self progressController] window] center];
      [[[self progressController] window] makeKeyAndOrderFront:self];

   } else if ([self progressControllerCreated]) {
   
      [NSApp beginSheet:[[self progressController] window] modalForWindow:modalWindow modalDelegate:self didEndSelector:NULL contextInfo:nil];
   }
   
    NSDocument *doc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[self filePath] display:NO];
    if (doc)
    {
        if ([[[self progressController] window] isSheet])
        {
            [NSApp endSheet:[[self progressController] window]];
        }

        [[[self progressController] window] orderOut:self];
        
        [doc showWindows];
        fileOpened = YES;
        [[NSUserDefaults standardUserDefaults] setObject:[[self filePath] lastPathComponent] forKey:@"Most Recent Opened Bid File"];
    }

//   if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[self filePath] display:YES]){
//   
//      fileOpened = YES;
//
//      [[NSUserDefaults standardUserDefaults] setObject:[[self filePath] lastPathComponent] forKey:@"Most Recent Opened Bid File"];
//   }
   
   
   return fileOpened;
}

#pragma mark ACCESSORS

- (NSString *)filePath { return filePath; }
- (void)setFilePath:(NSString *)inValue
{
   if (filePath != inValue) {
      [filePath release];
      filePath = [inValue retain];
   }
}

- (NSWindow *)modalWindow { return modalWindow; }

- (CBProgressWindowController *)progressController { return progressController; }

- (BOOL)progressControllerCreated { return progressControllerCreated; }
- (void)setProgressControllerCreated:(BOOL)inValue { progressControllerCreated = inValue; }

@end
