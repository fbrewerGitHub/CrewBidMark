//
//  CBFileSelectWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jan 27 2005.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBFileSelectWindowController.h"
// for crewBidDirectoryPath method
#import "CBAppController.h"

@implementation CBFileSelectWindowController

#pragma mark INITIALIZATION

- (id)initWithDirectory:(NSString *)directoryPath file:(NSString *)filename types:(NSArray *)filetypes
{
   if (self = [super initWithWindowNibName:@"CBFileSelect"])
   {
      // set variables
      if (directoryPath)
      {
         [self setDirectory:directoryPath];
      }
      else
      {
         [self setDirectory:[[NSApp delegate] crewBidDirectoryPath]];
      }
      [self setFileName:filename];
      [self setFileTypes:filetypes];
   }
   return self;
}

- (void)awakeFromNib
{
   NSFileManager *fileManager = nil;
   NSMutableArray *filesToDisplay = nil;
   NSEnumerator *filesEnumerator = nil;
   NSString *file = nil;
   NSString *fileType = nil;
   int fileIndex = 0;

   // get files and select flle
   fileManager = [NSFileManager defaultManager];
    filesToDisplay = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtPath:[self directory] error:NULL]];
    if ([self fileTypes])
   {
      filesEnumerator = [filesToDisplay objectEnumerator];
      while (file = [filesEnumerator nextObject])
      {
         fileType = [file pathExtension];
         if (![[self fileTypes] containsObject:fileType])
         {
            [filesToDisplay removeObject:file];
         }
         else
         {
            fileIndex = [filesToDisplay indexOfObject:file];
            [filesToDisplay replaceObjectAtIndex:fileIndex withObject:[file stringByDeletingPathExtension]];
         }
      }
   }
   [self setFiles:[NSArray arrayWithArray:filesToDisplay]];
   [[self fileSelectTableView] reloadData];
   if ([self fileName])
   {
      fileIndex = [[self files] indexOfObject:[[self fileName] stringByDeletingPathExtension]];
       [[self fileSelectTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:fileIndex] byExtendingSelection:NO];
   }
}

- (void)dealloc
{
   [directory release];
   [fileName release];
   [fileTypes release];
   [files release];
   [super dealloc];
}

#pragma mark ACTIONS

- (IBAction)cancelButtonAction:(id)sender
{
}

- (IBAction)defaultButtonAction:(id)sender
{
}

#pragma mark TABLE VIEW METHODS

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
   NSInteger rows = 0;
   if (tableView == [self fileSelectTableView])
   {
      rows = [[self files] count];
   }
   return rows;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
   NSString *file = nil;
   
   if (tableView == [self fileSelectTableView])
   {
      file = [[self files] objectAtIndex:rowIndex];
   }
   return file;
}

#pragma mark ACCESSORS

- (NSButton *)defaultButton { return defaultButton; }

- (NSButton *)cancelButton { return cancelButton; }

- (NSTableView *)fileSelectTableView { return fileSelectTableView; }

- (NSString *)directory { return directory; }
- (void)setDirectory:(NSString *)inValue
{
   if (directory != inValue)
   {
      [directory release];
      directory = [inValue copy];
   }
}

- (NSString *)fileName { return fileName; }
- (void)setFileName:(NSString *)inValue
{
   if (fileName != inValue)
   {
      [fileName release];
      fileName = [inValue copy];
   }
}

- (NSArray *)fileTypes { return fileTypes; }
- (void)setFileTypes:(NSArray *)inValue
{
   if (fileTypes != inValue)
   {
      [fileTypes release];
      fileTypes = [inValue copy];
   }
}

- (NSArray *)files { return files; }
- (void)setFiles:(NSArray *)inValue
{
   if (files != inValue)
   {
      [files release];
      files = [inValue copy];
   }
}

@end
