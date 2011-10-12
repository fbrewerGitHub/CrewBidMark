//
//  CBBidSubmitController.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 30 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBBidSubmitPreferencesWindowController.h"
#import "CBBidFileDownload.h"
#import "CBLine.h"
#import "CBAppController.h"
#import "CBDataModel.h"
#import "CSBidPeriod.h"
#import "CBDocument.h"
// import for user default CBSaveBidBeforeSubmitKey
//#import "CBMainPreferencesWindowController.h"
extern NSString *CBSaveBidBeforeSubmitKey;

// REQUEST = UPLOAD_BID (case sensitive)
// PACKETID format: Base(3 letters) Year(4 digits) Month(2 digits) BidRound(4 for pilot first round)
//   example: MCO2004054 would indicate MCO May 2004 pilot first round
// BIDDER format: employee number
// PILOT1, PILOT2, PILOT3 format: employee number of avoidance bid (remove if no avoidance bid)
// BASE format: 3 letters (case sensitive)
// SEAT format: CP for Captain, FO for First Officer
// BIDROUND format: "Round 1" for first round bid
// VENDOR format: limit to 10 characters
// BID format: comma-delimited list of bid lines (line number), with no comma after final bid line

NSString * BID_SUBMIT_REQUEST = @"REQUEST=UPLOAD_BID&CREDENTIALS=%@&PACKETID=%@&BIDDER=%@%@&BASE=%@&SEAT=%@&BIDROUND=Round %d&VENDOR=MacCrewBid&BID=%@";

@implementation CBMainWindowController ( CBBidSubmitController )

#pragma mark ACTIONS

//- (IBAction)submitBid:(id)sender
//{
//   // set crew position in user defaults
//   [[NSUserDefaults standardUserDefaults] setObject:[[self dataModel] crewPosition] forKey:CBCrewPositionKey];
//   
//   // save bid data
//   BOOL saveBeforeSubmit = [[[NSUserDefaults standardUserDefaults] objectForKey:CBSaveBidBeforeSubmitKey] boolValue];
//   if (saveBeforeSubmit) {
//      [[self document] saveDocument:self];
//   }
//   // display bid submit preferences sheet
//   if (!bidSubmitWindowController) {
//      bidSubmitWindowController = [[CBBidSubmitPreferencesWindowController alloc] initWithRound:[[[[self dataModel] bidPeriod] round] intValue]];
//   }
//   [NSApp beginSheet:[bidSubmitWindowController window]
//      modalForWindow:[self window]
//       modalDelegate:self
//      didEndSelector:@selector(bidSubmitSheetDidEnd:returnCode:contextInfo:)
//         contextInfo:nil];
//
//   // bid preferences sheet is being displayed
//}

#pragma mark BID SUBMISSION

- (void)bidSubmitSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   // remove bid submit preferences sheet
   [sheet orderOut:self];
   
   // determine which button of bid submit preferences window was clicked
   switch (returnCode)
   {
      case NSAlertDefaultReturn:
         [bidSubmitWindowController release];
         bidSubmitWindowController = nil;
         [self submitBid];
         break;
      case NSAlertAlternateReturn:
         [bidSubmitWindowController release];
         bidSubmitWindowController = nil;
         break;
      case NSAlertErrorReturn:
         break;
      default:      
         [bidSubmitWindowController release];
         bidSubmitWindowController = nil;
         break;
   }
}

- (void)submitBid
{
   // bidder 
   NSString * bidder = [[NSUserDefaults standardUserDefaults] objectForKey:CBEmployeeNumberKey];
   // avoidance bids
   NSString * avoidanceBids = [self employeeBidsFromUserDefaults];
   // crew base
   NSString * base = [[self dataModel] crewBase];
   // month
   NSCalendarDate * month = [[self dataModel] month];
   // position
   NSString *dataModelPosition = [[self dataModel] crewPosition];
   NSString *position = nil;
   if ([dataModelPosition isEqualToString:@"Captain"])
   {
      position = @"CP";
   }
   else if ([dataModelPosition isEqualToString:@"First Officer"])
   {
      position = @"FO";
   }
   else
   {
      position = @"FA";
   }
   // bid round
   int round = [[self dataModel] bidRound];
   // packet id
   NSString * packetID = [self packetIDWithBase:base month:month position:position round:round];
   // bid lines
   NSString * bidLines = [self bidLines];
   // directory
   NSString * crewBidDirectory = [[NSApp delegate] crewBidDirectoryPath];
   // file name
   NSString * bidReceiptFileName = [self bidReceiptFileNameWithBidder:bidder month:month];
   // request body
   NSString * requestBody = [NSString stringWithFormat:BID_SUBMIT_REQUEST, @"%@", packetID, bidder, avoidanceBids, base, position, round, bidLines];
   // create bid file download
   [self setBidFileDownload:[[[CBBidFileDownload alloc] initWithBidDataFile:bidReceiptFileName directory:crewBidDirectory requestBody:requestBody owner:self] autorelease]];
   [[self bidFileDownload] showCredentialWindow];
}

#pragma mark BID REQUEST BODY CREATION

- (NSString *)packetIDWithBase:(NSString *)base month:(NSCalendarDate *)month position:(NSString *)position round:(int)round
{
   NSString * yearString = [NSString stringWithFormat:@"%d", [month yearOfCommonEra]];
   NSString * monthString = [NSString stringWithFormat:@"%02d", [month monthOfYear]];
   int bidRound = round;
   if (![position isEqualToString:@"FA"]) {
      if (1 == round) {
         bidRound = 4;
      } else {
         bidRound = 5;
      }
   }
   NSString * packetID = [NSString stringWithFormat:@"%@%@%@%d", base, yearString, monthString, bidRound];
   return packetID;
}

- (NSString *)bidLines
{
   NSMutableString * bid = [NSMutableString string];
   NSArray * lines = [[self dataModel] lines];
   unsigned numBids = (lines ? [lines count] : 0);
   unsigned index = 0;
   CBLine * line = nil;
   int lineNumber = 0;
   BOOL isFaFirstRoundBid = [self isFlightAttendantFirstRoundBid];
   NSString *pos = nil;
   for (index = 0; index < numBids - 1; index++) {
      line = [lines objectAtIndex:index];
      lineNumber = [line number];
      if (isFaFirstRoundBid)
      {
         if (CBFaReserveLineNumber == lineNumber)
         {
            [bid appendString:@"R"];
            // no more bids should be submitted, so return bid
            return [NSString stringWithString:bid];
         }
         else if (CBFaMrtLineNumber == lineNumber)
         {
            [bid appendString:@"M,"];
         }
         else
         {
            pos = [line faPosition];
            [bid appendFormat:@"%d%@,", lineNumber, pos];
         }
      }
      else
      {
         [bid appendFormat:@"%d,", lineNumber];
      }
   }
   // last bid line, without delimiting comma
   line = [lines objectAtIndex:(numBids - 1)];
   lineNumber = [line number];
   if (isFaFirstRoundBid)
   {
      pos = [line faPosition];
      [bid appendFormat:@"%d%@", lineNumber, pos];
   }
   else
   {
      [bid appendFormat:@"%d", lineNumber];
   }
   return [NSString stringWithString:bid];
}

- (NSString *)employeeBidsFromUserDefaults
{
   NSMutableString *avoidanceBids = [NSMutableString string];
   // second round bids should not include avoidance/buddy bids
   if ([self isFirstRoundBid])
   {
       NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
       NSString * emp1 = [defaults objectForKey:CBEmployeeBid1Key];
       NSString * emp2 = [defaults objectForKey:CBEmployeeBid2Key];
       NSString * emp3 = [defaults objectForKey:CBEmployeeBid3Key];
       NSString * typeBid = [self isFlightAttendantBid] ? @"BUDDY" : @"PILOT";
       NSString * empBidFormat = @"&%@%d=%@";
       unsigned empNumber = 1;
       if (![emp1 isEqualToString:@""]) {
          [avoidanceBids appendFormat:empBidFormat, typeBid, empNumber, emp1];
          empNumber++;
       }
       if (![emp2 isEqualToString:@""]) {
          [avoidanceBids appendFormat:empBidFormat, typeBid, empNumber, emp2];
          empNumber++;
       }
       if (![emp3 isEqualToString:@""]) {
          [avoidanceBids appendFormat:empBidFormat, typeBid, empNumber, emp3];
       }
   }
   return [NSString stringWithString:avoidanceBids];
}

- (NSString *)bidReceiptFileNameWithBidder:(NSString *)bidder month:(NSCalendarDate *)month
{
   NSMutableString * bidReceiptFileName = [NSMutableString stringWithFormat:@"%@ %@ Bid Receipt", [month descriptionWithCalendarFormat:@"%b %y"], bidder];
   NSFileManager * defaultFileManager = [NSFileManager defaultManager];
   NSString * crewBidDirectory = [[NSApp delegate] crewBidDirectoryPath];
   int fileNumber = 1;
   if ([defaultFileManager fileExistsAtPath:[crewBidDirectory stringByAppendingPathComponent:[bidReceiptFileName stringByAppendingPathExtension:@"txt"]]]) {
      [bidReceiptFileName appendFormat:@"-%d", fileNumber];
      while ([defaultFileManager fileExistsAtPath:[crewBidDirectory stringByAppendingPathComponent:[bidReceiptFileName stringByAppendingPathExtension:@"txt"]]]) {
         fileNumber++;
         [bidReceiptFileName replaceCharactersInRange:NSMakeRange([bidReceiptFileName length] - 2, 2) withString:[NSString stringWithFormat:@"-%d", fileNumber]];
      }
   }
   return [bidReceiptFileName stringByAppendingPathExtension:@"txt"];
}

#pragma mark BID FILE WINDOW CONTROLLER METHODS

- (void)handleDownloadedBidFile:(NSString *)path
{
   // remove progress sheet
   [NSApp endSheet:[[self bidFileDownload] progressWindow]];
   [[[self bidFileDownload] progressWindow] orderOut:self];
   // release bid file download
   [self setBidFileDownload:nil];
   // set user defaults for most recent bid receipt and bid document
   [[NSUserDefaults standardUserDefaults] setObject:path forKey:CBMostRecentBidReceiptKey];

   // context info is bid file path
   
   
   NSBeginAlertSheet(@"Bid Submitted",    // alert title
                     @"View Bid Receipt", // default button
                     @"Not Now",          // alternate button
                     nil,                 // other button
                     [self window],       // document window
                     self,                // modal delegate
                     @selector(bidReceiptSheetDidEnd:returnCode:contextInfo:), // did end selector
                     NULL,                // did dismiss selector
                     [path retain],       // context info
                     @"Your bid was successfully submitted, and you have received a receipt (%@).\n\nYou should check your receipt to make sure your bid was correctly received.\n\nTo view your bid receipt, click the \"View Bid Receipt\" button, which will open the bid receipt in your default text editor.\n\nYou may view your most recent bid receipt at any time by selecting the \"Open Bid Receipt...\" menu.", [[path lastPathComponent] stringByDeletingPathExtension] // message
   );
}

#pragma mark SHEET HANDLING

- (void)bidReceiptSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   // context info is path to downloaded bid receipt
   
   switch (returnCode)
   {
      // view bid receipt, open with default text editor
      case NSAlertDefaultReturn:
         // show bid receipt with default text editor
         [[NSWorkspace sharedWorkspace] openFile:(NSString *)contextInfo];
         break;

      // not now, do nothing
      case NSAlertAlternateReturn:
         break;

      default:
         break;
   }
   // release context info because it was retained in handleDownloadedFile:
   // method
   [(NSString *)contextInfo release];
}

#pragma mark ACCESSORS

- (CBBidSubmitPreferencesWindowController *)bidSubmitWindowController { return bidSubmitWindowController; }


@end
