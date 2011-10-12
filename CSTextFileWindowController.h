//
//  CSTextFileWindowController.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 3/2/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSTextFileWindowController : NSWindowController
{
    IBOutlet NSTextView *_textView;
    NSString *_textFilePath;
    NSString *_title;
    NSString *_text;
}

#pragma mark
#pragma mark Class Methods
#pragma mark

+ (void)showTextFile:(NSString *)path title:(NSString *)title;

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithTextFilePath:(NSString *)textFilePath title:(NSString *)title;
- (id)initWithText:(NSString *)text;

#pragma mark
#pragma mark Printing
#pragma mark

- (void)printTextFile:(id)sender;

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSTextView *)textView;

- (NSString *)textFilePath;
- (void)setTextFilePath:(NSString *)value;

- (NSString *)title;
- (void)setTitle:(NSString *)value;

- (NSString *)text;
- (void)setText:(NSString *)value;

@end
