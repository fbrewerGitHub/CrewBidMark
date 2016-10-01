//
//  CSBidFileDownloadWindowController.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 5/12/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSBidFileDownloadWindowController.h"

#import "CSBidPeriod.h"
#import "CSBidFileDownload.h"

NSString *CSBidFileDownloadWindowControllerDidFinishNotification = @"Bid File Download Window Controller Did Finish";
void *CSUserCredentialsChangedContext = (void *)4321;


@implementation CSBidFileDownloadWindowController

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithWindowNibName:(NSString *)windowNibName bidPeriod:(CSBidPeriod *)bidPeriod
{
    if (self = [super initWithWindowNibName:windowNibName])
    {
        [self setBidPeriod:bidPeriod];
        // Create bid file download
        CSBidFileDownload *bidFileDownload = [[CSBidFileDownload alloc] init];
        [bidFileDownload setBidPeriod:bidPeriod];
        [self setBidFileDownload:bidFileDownload];
        [bidFileDownload release];
        // Subclasses need to set bidFileDownload type
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setBidPeriod:nil];
    [self setBidFileDownload:nil];
    [self setWindowView:nil];
    [super dealloc];
}

#pragma mark
#pragma mark Actions
#pragma mark

- (IBAction)okButtonAction:(id)sender
{
    // force the user id/password binding to the bid file download
    [[self window] makeFirstResponder:[self window]];
    // Start bid file download
    [self downloadBidData];
    // Show progress interface
    [self showProgressInterface];
}

- (IBAction)cancelButtonAction:(id)sender
{
    if ([[self window] isSheet])
    {
        [NSApp endSheet:[self window]];
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CSBidFileDownloadWindowControllerDidFinishNotification object:self];
	
    [[self window] orderOut:nil];
    [self autorelease];
}

- (IBAction)progressCancelButtonAction:(id)sender
{
    [[self bidFileDownload] cancelBidFileDownload];
    [self showWindowInterface];
}

#pragma mark
#pragma mark User Interface
#pragma mark

- (void)showProgressInterface
{
    if (![self windowView])
    {
        NSView *windowView = [[self window] contentView];
        [self setWindowView:windowView];
    }
    [self exchangeWindowViewWithView:progressView];
}

- (void)showWindowInterface
{
	[self setEnableOkButton:NO];
    [self exchangeWindowViewWithView:[self windowView]];
}

- (void)exchangeWindowViewWithView:(NSView *)otherView
{
    NSRect oldContentFrame = [[[self window] contentView] frame];
    NSRect newContentFrame = [otherView frame];
    
    float heightDiff = oldContentFrame.size.height - newContentFrame.size.height;
    
    NSRect windowFrame = [[self window] frame];
    
    NSSize oldSindowSize = windowFrame.size;
    NSSize newWindowSize = NSMakeSize(oldSindowSize.width, oldSindowSize.height - heightDiff);
    windowFrame.size = newWindowSize;
    windowFrame.origin.y += heightDiff;
    
    [[self window] setContentView:otherView];
    [[self window] setFrame:windowFrame display:YES animate:YES];
}

#pragma mark
#pragma mark File Download
#pragma mark

- (void)downloadBidData
{
    // Add self as observer to be notified when bid file download ends
    [[NSNotificationCenter defaultCenter] 
        addObserver:self 
        selector:@selector(bidFileDownloadDidFinish:) 
        name:CSBidFileDownloadDidFinishNotification 
        object:[self bidFileDownload]];
    
    [[self bidFileDownload] setDownloadDirectory:[[self bidPeriod] bidDataDirectoryPath]];
    [[self bidFileDownload] setFilesToDownload:[self bidFilesToDownload]];

    [[self bidFileDownload] beginFileDownload];
}

- (NSArray *)bidFilesToDownload
{
    NSArray *filesToDownload = nil;
    CSBidFileDownloadType type = [[self bidFileDownload] type]; 
    switch (type)
    {
        case CSBidFileDownloadBidDataType:
            filesToDownload = [NSArray arrayWithObjects:
                [[self bidPeriod] bidDataFileName],
                [[self bidPeriod] textDataFileName], nil];
            break;
        case CSBidFileDownloadBidSubmissionType:
            filesToDownload = [NSArray arrayWithObject:[self nextBidReceipt]];
            break;
        case CSBidFileDownloadBidAwardsType:
            filesToDownload = [NSArray arrayWithObject:
                [[self bidPeriod] bidAwardFileName]];
            break;
        default:
            break;
    }
    // get text data file for first round bid, if this is a second round bid
    if (type == CSBidFileDownloadBidDataType && [[self bidPeriod] isSecondRoundBid])
    {
        CSBidPeriod *round1bpv = [[self bidPeriod] copy];
        [round1bpv setRound:[NSNumber numberWithInt:1]];
        NSString *round1TextDataFile = [round1bpv textDataFileName];
        NSMutableArray *files = [NSMutableArray arrayWithArray:filesToDownload];
        [files addObject:round1TextDataFile];
        filesToDownload = [NSArray arrayWithArray:files];
        [round1bpv release];
    }
    
    return filesToDownload;
}

- (NSString *)nextBidReceipt
{
    return [[self bidPeriod] nextBidReceiptName];
}

- (void)bidFileDownloadDidFinish:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSError *error = [userInfo objectForKey:CSBidFileDownloadErrorKey];
    if (error)
    {
        // Remove password
        [[self bidFileDownload] setPassword:nil];
        // Remove user id
        [[self bidFileDownload] setUserID:nil];
        NSWindow *windowForSheet = nil;
        if ([[self window] isSheet])
        {
            [NSApp endSheet:[self window]];
            [[self window] orderOut:nil];
            windowForSheet = [[self document] windowForSheet];
        }
        else
        {
            windowForSheet = [self window];
        }
        [self showWindowInterface];
        [self displayError:error forWindow:windowForSheet];
    }
    else
    {
        [self bidFileDownloadDidFinish];
    }
}

- (void)bidFileDownloadDidFinish
{
	[[NSNotificationCenter defaultCenter] postNotificationName:CSBidFileDownloadWindowControllerDidFinishNotification object:self];
    // Sublcasses must override to take some action after the bid file download 
    // has finished
    return;
}

- (void)displayError:(NSError *)error forWindow:(NSWindow *)window
{
    // NSAlert alertWithError: method on available in System 10.4
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//    NSAlert *alert = [NSAlert alertWithError:error];

    [alert setMessageText:[error localizedDescription]];
    [alert addButtonWithTitle:@"OK"];
    
    // NSError localizedFailureReason requires 10.4, so using
    // NSLocalizedFailureReasonErrorKey as error userInfo key
    [alert setInformativeText:[NSString stringWithFormat:@"Reason: %@", [[error userInfo] objectForKey:CSBidFileDownloadErrorKey]]];
    
//    [alert setInformativeText:[NSString stringWithFormat:@"Reason: %@", [error localizedFailureReason]]];
    [alert 
        beginSheetModalForWindow:window 
        modalDelegate:self 
        didEndSelector:@selector(errorAlerDidEnd:returnCode:contextInfo:) 
        contextInfo:[self document]];
}

- (void)errorAlerDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [[alert window] orderOut:nil];
    // Context info is document, which only subclasses that are displayed as
    // a sheet should have
    if (contextInfo)
    {
        [NSApp 
            beginSheet:[self window] 
            modalForWindow:[(NSDocument *)contextInfo windowForSheet] 
            modalDelegate:nil 
            didEndSelector:NULL 
            contextInfo:nil];
    }
}

#pragma mark
#pragma mark Key-Value Observing
#pragma mark

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (CSUserCredentialsChangedContext == context)
    {
        NSString *uid = [[self bidFileDownload] userID];
        NSString *pwd = [[self bidFileDownload] password];
        // enable ok button if we have valid user id and password
        if (uid && pwd && [uid length] > 0 && [pwd length] > 0)
        {
            [self setEnableOkButton:YES];
        }
        else
        {
            [self setEnableOkButton:NO];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark
#pragma mark Control Delegate Methods
#pragma mark

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSString *uid = [[self bidFileDownload] userID];
    NSString *pwd = [[self bidFileDownload] password];
    
    // a bit of a hack to get the OK button to enabled
    id noteObj = [notification object];
    if ([noteObj isMemberOfClass:[NSTextField class]])
    {
        uid = [(NSTextField *)noteObj stringValue];
    }
    else if ([noteObj isMemberOfClass:[NSSecureTextField class]])
    {
        pwd = [(NSSecureTextField *)noteObj stringValue];
    }
    
    // enable ok button if we have valid user id and password
    if (uid && pwd && [uid length] > 0 && [pwd length] > 0)
    {
        [self setEnableOkButton:YES];
    }
    else
    {
        [self setEnableOkButton:NO];
    }
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (CSBidPeriod *)bidPeriod {
    return [[_bidPeriod retain] autorelease];
}

- (void)setBidPeriod:(CSBidPeriod *)value {
    if (_bidPeriod != value) {
        [_bidPeriod release];
        _bidPeriod = [value retain];
    }
}

- (CSBidFileDownload *)bidFileDownload {
    return [[_bidFileDownload retain] autorelease];
}

- (void)setBidFileDownload:(CSBidFileDownload *)value {
    if (_bidFileDownload != value) {
    
        // stop observing old bid file download
//        [_bidFileDownload removeObserver:self forKeyPath:@"userID"];
//        [_bidFileDownload removeObserver:self forKeyPath:@"password"];
        
        [_bidFileDownload release];
        _bidFileDownload = [value retain];
        
        // observe userID and password of bid file download, to update
        // enable ok button
//        [_bidFileDownload 
//            addObserver:self 
//            forKeyPath:@"userID" 
//            options:0 
//            context:CSUserCredentialsChangedContext];
//        [_bidFileDownload 
//            addObserver:self 
//            forKeyPath:@"password" 
//            options:0 
//            context:CSUserCredentialsChangedContext];
    }
}

- (NSArray *)selectedBidPeriodIndexes {
    return [[_selectedBidPeriodIndexes retain] autorelease];
}

- (void)setSelectedBidPeriodIndexes:(NSArray *)value {
    if (_selectedBidPeriodIndexes != value) {
        [_selectedBidPeriodIndexes release];
        _selectedBidPeriodIndexes = [value copy];
    }
}

- (NSView *)windowView {
    return [[_windowView retain] autorelease];
}

- (void)setWindowView:(NSView *)value {
    if (_windowView != value) {
        [_windowView release];
        _windowView = [value retain];
    }
}

- (BOOL)enableOkButton {
    return _enableOkButton;
}

- (void)setEnableOkButton:(BOOL)value {
    if (_enableOkButton != value) {
        _enableOkButton = value;
    }
}

@end
