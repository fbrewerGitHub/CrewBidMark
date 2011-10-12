//
//  CSTextFileWindowController.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 3/2/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSTextFileWindowController.h"
#import "CSPrintView.h"


@implementation CSTextFileWindowController

#pragma mark
#pragma mark Class Methods
#pragma mark

+ (void)showTextFile:(NSString *)path title:(NSString *)title;
{
    CSTextFileWindowController *tfwc = [[CSTextFileWindowController alloc] initWithTextFilePath:path title:title];
    [tfwc showWindow:nil];
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithTextFilePath:(NSString *)textFilePath title:(NSString *)title
{
    if (self = [super initWithWindowNibName:@"TextFile"])
    {
        [self setTextFilePath:textFilePath];
        [self setTitle:title];
    }
    
    return self;
}

- (id)initWithText:(NSString *)text
{
    if (self = [super initWithWindowNibName:@"TextFile"])
    {
        [self setText:text];
    }
    
    return self;
}

- (void)awakeFromNib
{
//    NSString *text = [NSString stringWithContentsOfFile:[self textFilePath]];
//    [[self textView] setString:text];
    
    // Window title and text view path are set in Interface Builder
    NSFont *font = [NSFont fontWithName:@"Monaco" size:10.0];
    [[self textView] setFont:font];

    [[self window] center];
}

- (void) dealloc
{
    [self setTextFilePath:nil];
    [super dealloc];
}

#pragma mark
#pragma mark Window Delegate
#pragma mark

- (void)windowWillClose:(NSNotification *)notification
{
    NSWindow *window = [notification object];
    if (window == [self window])
    {
        [self autorelease];
    }
}

#pragma mark
#pragma mark Printing
#pragma mark

- (void)printTextFile:(id)sender
{
//    [[[self window] contentView] print:sender];
//	[[NSPrintOperation printOperationWithView:[self textView]] runOperation];
//	NSArray *printerNames = [NSPrinter printerNames];
//	NSArray *printerTypes = [NSPrinter printerTypes];
//	NSLog(@"printer names:\n%@\nprinter types:\n%@", printerNames, printerTypes);
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
//	NSPrinter *printer = [printInfo printer];
//	NSString *printerName = [printer name];
//	NSLog(@"shared print info printer name: %@", printerName);
	NSRect bounds = [printInfo imageablePageBounds];
	NSLog(@"shared print info page bounds: %0.1f %0.1f %0.1f %0.1f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
//	
//	NSRect contentViewFrame = [[[self window] contentView] frame];
//	CSPrintView *printView = [[CSPrintView alloc] initWithFrame:contentViewFrame];
//	NSTextContainer *textContainer = [[self textView] textContainer];
//	NSSize textContainerSize = [textContainer containerSize];
//	NSLog(@"text view container size %0.1f %0.1f", textContainerSize.width, textContainerSize.height);
//	NSArray *paragraphs = [textStorage paragraphs];
//	NSLog(@"text storage paragraphs:\n%@", paragraphs);
	NSTextStorage *textStorage = [[self textView] textStorage];
	NSString *s = [textStorage string];
	unsigned l = [s length];
	unsigned stringStart = 0;
	NSRange r = [s rangeOfString:@"\f"];
	while (NSNotFound != r.location) {
		if (r.location == NSNotFound) {
			NSLog(@"not found");
		} else {
			NSRange stringRange = NSMakeRange(stringStart, r.location - stringStart);
			NSAttributedString *as = [textStorage attributedSubstringFromRange:stringRange];
			NSSize stringSize = [as size];
			NSLog(@"found at %u size: %0.1f %0.1f\n%@", r.location, stringSize.width, stringSize.height, as);
			r.location++;
			r.length = l - r.location;
			stringStart = r.location;
			r = [s rangeOfString:@"\f" options:NSLiteralSearch range:r];
		}
	}
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSTextView *)textView
{
    return _textView;
}

- (NSString *)textFilePath
{
    return [[_textFilePath retain] autorelease];
}

- (void)setTextFilePath:(NSString *)value
{
    if (_textFilePath != value) {
        [_textFilePath release];
        _textFilePath = [value copy];
    }
}

- (NSString *)title {
    return [[_title retain] autorelease];
}

- (void)setTitle:(NSString *)value {
    if (_title != value) {
        [_title release];
        _title = [value copy];
    }
}

- (NSString *)text {
    return [[_text retain] autorelease];
}

- (void)setText:(NSString *)value {
    if (_text != value) {
        [_text release];
        _text = [value copy];
    }
}


@end
