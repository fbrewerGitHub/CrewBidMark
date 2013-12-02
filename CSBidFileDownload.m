//
//  CSBidFileDownload.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 3/4/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSBidFileDownload.h"

#import "CSBidPeriod.h"
#import "CSError.h"
#import "CSPreferenceKeys.h"
#import "CBDataModel.h"  // for CBFaReserveLineNumber and CBFaMrtLineNumber

//NSString *CSThirdPartyURL = @"https://www.myswa.com/webbid3pty/ThirdParty";
//NSString *CSThirdPartyURL = @"https://www1.swalife.com/webbid3pty/ThirdParty";
NSString *CSThirdPartyURL = @"https://www27.swalife.com/webbid3pty/ThirdParty";
NSString *CSBidFileDownloadDidFinishNotification = @"Bid File Download Did Finish Notification";
NSString *CSBidFileDownloadErrorKey = @"error";


@implementation CSBidFileDownload

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithType:(CSBidFileDownloadType)type directory:(NSString *)directory files:(NSArray *)files
{
    if (self = [super init])
    {
        [self setType:type];
        [self setDownloadDirectory:directory];
        [self setFilesToDownload:files];
    }
    
    return self;
}

- (void)dealloc
{
    // Bid perdiod values
    [self setBidPeriod:nil];
    // User credentials
    [self setUserID:nil];
    [self setPassword:nil];
    // Download progress
    [self setProgressText:nil];
    // File download
    [self setDownloadDirectory:nil];
    [self setFilesToDownload:nil];
    [self setFileEnumerator:nil];
    [self setPrelogonCredential:nil];
    [self setSessionCredential:nil];
    [self setURLRequest:nil];
    [self setURLData:nil];
    [self setURLConnection:nil];
	// bid employee number
	[self setBidEmployeeNumber:nil];

    [super dealloc];
}

#pragma mark
#pragma mark Bid File Downloading
#pragma mark

- (void)beginFileDownload
{
    // Create data directory
    [[NSFileManager defaultManager] createDirectoryAtPath:[self downloadDirectory] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Initialize third party url request
    NSURL *thirdPartyURL = [[NSURL alloc] initWithString:CSThirdPartyURL];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:thirdPartyURL];
    [self setURLRequest:urlRequest];
    [urlRequest release];
    
    // Initialize url data
    NSMutableData *urlData = [[NSMutableData alloc] init];
    [self setURLData:urlData];
    [urlData release];
    
    // Begin file download process by retrieving prelogon credential
    [self retrievePrelogonCredential];
}

- (void)retrievePrelogonCredential
{
    // Status
    [self setStatus:CSBidFileDownloadPrelogonCredential];
    
    // Download progress
    [self setIsDownloading:YES];
    [self setProgressText:@"Checking internet connection..."];
    
    // Initiate connection for prelogon credential
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:[self urlRequest] delegate:self];
    [self setURLConnection:urlConnection];
    [urlConnection release];
}

- (void)retrieveSessionCredential
{
    // Status
    [self setStatus:CSBidFileDownloadSessionCredential];
    
    // Download progress
    [self setProgressText:@"Authenticating..."];
    
    // Add session credential http body to url request, set http method
    // to POST, and zero out url data
    [[self urlRequest] setHTTPBody:[self sessionCredentialHTTPBody]];
    [[self urlRequest] setHTTPMethod:@"POST"];
    [[self urlData] setLength:0];
    
    // Initiate connection for session credential
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:[self urlRequest] delegate:self];
    [self setURLConnection:urlConnection];
    [urlConnection release];
}

- (void)downloadNextFile
{
   if ([self filesToDownload] && [self fileEnumerator])
   {
      [self setDownloadFileName:[[self fileEnumerator] nextObject]];
      if ([self downloadFileName])
      {
         [self downloadFile:[self downloadFileName]];
      }
   }
}

- (void)downloadFile:(NSString *)filename
{
    // Status
    [self setStatus:CSBidFileDownloadFileDownload];
    
    // Set progress text depending on type of file download
    NSString *progressText = nil;
    
    switch ([self type])
    {
        case CSBidFileDownloadBidDataType:
            progressText = @"Retrieving bid data...";
            break;
        case CSBidFileDownloadBidAwardsType:
            progressText = @"Retrieving bid awards...";
            break;
        case CSBidFileDownloadBidSubmissionType:
            progressText = @"Submitting bid...";
            break;
        default:
            progressText = @"Downloading...";
            break;
    }
    
    [self setProgressText:progressText];

    // Set url connection http body for file to be downloaded and zero out
    // url data
    NSData *fileHTTPbody = nil;
    if (CSBidFileDownloadBidSubmissionType == [self type])
    {
        fileHTTPbody = [self bidSubmissionHTTPBody];
    }
    else
    {
        fileHTTPbody = [self fileHTTPBodyForFilename:filename];
    }
    [[self urlRequest] setHTTPBody:fileHTTPbody];
    [[self urlData] setLength:0];
    
    // Initiate connection for file download
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:[self urlRequest] delegate:self];
    [self setURLConnection:urlConnection];
    [urlConnection release];
}

- (void)cancelBidFileDownload
{
    [[self urlConnection] cancel];
    [self setIsDownloading:NO];
}


#pragma mark
#pragma mark HTTP Body
#pragma mark

- (NSData *)sessionCredentialHTTPBody
{
    NSString *sessionCredentialHTTPBodyString = [NSString stringWithFormat:@"CREDENTIALS=%@&REQUEST=LOGON&UID=%@&PWD=%@",
        [self prelogonCredential], 
        [self userID], 
        [self password]];
    
    NSData *sessionCredentialHTTPBody = [sessionCredentialHTTPBodyString dataUsingEncoding:NSUTF8StringEncoding];

    return sessionCredentialHTTPBody;
}

- (NSData *)fileHTTPBodyForFilename:(NSString *)name
{
    // Bid awards should be downloaded as TXTPACKET, and all others should be
    // downloaded as ZIPPACKET
    NSString *fileHTTPBodyString = [NSString stringWithFormat:@"REQUEST=%@&CREDENTIALS=%@&NAME=%@",
        CSBidFileDownloadBidAwardsType == [self type] ? @"TXTPACKET" : @"ZIPPACKET",
        [self sessionCredential], 
        name];
    
    NSData *fileHTTPBody = [fileHTTPBodyString dataUsingEncoding:NSUTF8StringEncoding];

    return fileHTTPBody;
}

- (NSData *)bidSubmissionHTTPBody
{
    NSString *bodyFormat = @"REQUEST=UPLOAD_BID&CREDENTIALS=%@&PACKETID=%@&BIDDER=%@%@&BASE=%@&SEAT=%@&BIDROUND=Round %@&VENDOR=MacCrewBid&BID=%@";
	NSString *bid = nil;
	// flight attendant first round bids have position appended to line number
	// and may have reserve and mrt bid
	if ([[self bidPeriod] isSecondRoundBid] || ![[self bidPeriod] isFlightAttendantBid]) {
		NSArray *bidLineNumbers = [[[self bidPeriod] bidLines] valueForKey:@"number"];
		bid = [bidLineNumbers componentsJoinedByString:@","];
	} else {
		NSArray *bidLines = [[self bidPeriod] bidLines];
		unsigned bidLinesCount = [bidLines count];
		unsigned bidLineIndex = 0;
		NSMutableString *faFirstRoundBid = [NSMutableString stringWithCapacity:bidLinesCount];
		for (; bidLineIndex < bidLinesCount; bidLineIndex++) {
			id line = [bidLines objectAtIndex:bidLineIndex];
			NSNumber *lineNum = [line valueForKey:@"number"];
			if (CBFaReserveLineNumber == [lineNum intValue]) {
				[faFirstRoundBid appendString:@"R"];
				break;
			} else if (CBFaMrtLineNumber == [lineNum intValue]) {
				[faFirstRoundBid appendString:@"M,"];
			} else {
				// omit comma for last bid
				if (bidLineIndex < bidLinesCount - 1) {
					[faFirstRoundBid appendFormat:@"%@%@,", lineNum, [line valueForKey:@"faPosition"]];
				} else {
					[faFirstRoundBid appendFormat:@"%@%@", lineNum, [line valueForKey:@"faPosition"]];
				}
			}
		}
		bid = faFirstRoundBid;
	}
	// optional paramaters - avoidance and buddy bids
	NSString *optionalParams = @"";
	if (![[self bidPeriod] isSecondRoundBid]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Temp fix to remove flight attendant buddy bids.
		if ([[self bidPeriod] isFlightAttendantBid]) {
            /*
			NSString *buddy1 = [defaults objectForKey:CBEmployeeBid1Key];
			NSString *buddy2 = [defaults objectForKey:CBEmployeeBid2Key];
			optionalParams = [NSString stringWithFormat:@"%@%@",
				buddy1 != nil && [buddy1 length] > 0 ? [NSString stringWithFormat:@"&BUDDY1=%@", buddy1] : @"",
				buddy2 != nil && [buddy2 length] > 0 ? [NSString stringWithFormat:@"&BUDDY2=%@", buddy2] : @""];
            */
        
		} else {
			NSString *avoid1 = [defaults objectForKey:CBEmployeeBid1Key];
			NSString *avoid2 = [defaults objectForKey:CBEmployeeBid2Key];
			NSString *avoid3 = [defaults objectForKey:CBEmployeeBid3Key];
			optionalParams = [NSString stringWithFormat:@"%@%@%@",
				avoid1 != nil && [avoid1 length] > 0 ? [NSString stringWithFormat:@"&PILOT1=%@", avoid1] : @"",
				avoid2 != nil && [avoid2 length] > 0 ? [NSString stringWithFormat:@"&PILOT2=%@", avoid2] : @"",
				avoid3 != nil && [avoid3 length] > 0 ? [NSString stringWithFormat:@"&PILOT3=%@", avoid3] : @""];
		}
	}
    NSString *body = [NSString stringWithFormat:bodyFormat,
        [self sessionCredential],
        [[self bidPeriod] packetID],
		[self bidEmployeeNumber],
		optionalParams,
        [[self bidPeriod] base],
        [[self bidPeriod] positionAbbreviation],
        [[self bidPeriod] round],
        bid];
    
    NSData *bidSubmissionHTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    return bidSubmissionHTTPBody;
}

#pragma mark
#pragma mark File Processing
#pragma mark

- (void)processDownloadedFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    [self setFileEnumerator:[[self filesToDownload] objectEnumerator]];
    NSString *file = nil;
    while (file = [[self fileEnumerator] nextObject])
    {
        // Decompress all downloaded files except those that have TXT or txt extension
        NSRange txtRange = [file rangeOfString:@"txt" options:NSLiteralSearch | NSCaseInsensitiveSearch];
        if (NSNotFound == txtRange.location)
        {
            NSString *filePath = [[self downloadDirectory] stringByAppendingPathComponent:file];
            [self unzipFile:filePath intoDirectory:[self downloadDirectory]];
            // Remove the compressed file
            [fileManager removeItemAtPath:filePath error:NULL];
        }
    }
}

- (void)unzipFile:(NSString *)filePath intoDirectory:(NSString *)dirPath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;

    if (![fm fileExistsAtPath:dirPath isDirectory:&isDir] && isDir)
    {
        [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }

    NSString *dittoPath = @"/usr/bin/ditto";
    if ([fm isExecutableFileAtPath:dittoPath])
    {
        NSTask * task = [[NSTask alloc] init];
        [task setCurrentDirectoryPath:[self downloadDirectory]];
        NSArray * args = [NSArray arrayWithObjects:@"-x", @"-k", filePath, dirPath, nil];
        [task setArguments:args];
        [task setLaunchPath:dittoPath];
        [task launch];
        [task waitUntilExit];
        [task release];
    }
    // Can't find ditto utility
    else
    {
        NSLog(@"Ditto utility does not exist at path: %@", dittoPath);
    }
}

#pragma mark
#pragma mark Error Handling
#pragma mark

- (void)presentError:(NSError *)error
{
    [self setIsDownloading:NO];
    
    [self setProgressText:[error localizedDescription]];
}
   
- (NSError *)bidInfoErrorForReason:(NSString *)errorReason
{
    // Create error description based on type of bid file download
    NSString *errorDescription = nil;
    
    switch ([self type])
    {
        case CSBidFileDownloadBidDataType:
            errorDescription = @"Could not retrieve bid data.";
            break;
        case CSBidFileDownloadBidSubmissionType:
            errorDescription = @"Could not submit bid.";
            break;
        case CSBidFileDownloadBidAwardsType:
            errorDescription = @"Could not retrieve bid awards.";
            break;
        default:
            break;
    }
    
    // NSLocalizedFailureReasonErrorKey requires System 10.4, so using 
    // CSBidFileDownloadError as error reason key
    NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        errorDescription, NSLocalizedDescriptionKey,
        errorReason, CSBidFileDownloadErrorKey, nil];
//    NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//        errorDescription, NSLocalizedDescriptionKey,
//        errorReason, NSLocalizedFailureReasonErrorKey, nil];
    NSError *error = [NSError errorWithDomain:CSCrewScheduleErrorDomain code:CSBidInfoError userInfo:errorUserInfo];
    
    return error;
}

#pragma mark
#pragma mark URL Connection Delegate Methods
#pragma mark



-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Zero out url data
    [[self urlData] setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append received data to url data
    [[self urlData] appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Prelogon credential connection: we don't check for error here
    if ([self status] == CSBidFileDownloadPrelogonCredential)
    {
        // Create prelogon credential from url data. Note that escaped
        // characters are added to prelogon credential in the set method. 
        NSString *prelogonCredential = [[NSString alloc] initWithData:[self urlData] encoding:NSUTF8StringEncoding];
        [self setPrelogonCredential:prelogonCredential];
        [prelogonCredential release];
        
        // Next, get session credential
        [[self urlData] setLength:0];
        [self retrieveSessionCredential];
    }
    
    // For other connections we check for error string in received url data.
    else
    {
        // Check for "ERROR" in url data received
        NSString *urlDataString = [[[NSString alloc] initWithData:[self urlData] encoding:NSUTF8StringEncoding] autorelease];
        NSRange errorRange = [urlDataString rangeOfString:@"error" options:NSLiteralSearch | NSCaseInsensitiveSearch];
        // Error: note that urlDataString will be nil if the urlData could not 
        // be converted to a UTF-8 string
        if (urlDataString && NSNotFound != errorRange.location)
        {
            // Error reason is url data string with ERROR: removed from beginning
            NSString *errorReason = [urlDataString substringFromIndex:errorRange.length + 2];
            NSError *error = [self bidInfoErrorForReason:errorReason];
            // Post notification for error
            NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObject:error forKey:CSBidFileDownloadErrorKey];
            [[NSNotificationCenter defaultCenter] 
                postNotificationName:CSBidFileDownloadDidFinishNotification 
                object:self 
                userInfo:notificationUserInfo];
        }

        // No error
        else
        {
            // Session credential connection
            if ([self status] == CSBidFileDownloadSessionCredential)
            {
                // Create session credential from url data.  Note that escaped
                // characters are added to prelogon credential in the set method.
                NSString *sessionCredential = [[NSString alloc] initWithData:[self urlData] encoding:NSUTF8StringEncoding];
                [self setSessionCredential:sessionCredential];
                [sessionCredential release];
                
                // Start downloading file(s)
                [self downloadNextFile];
            }
            
            // File download connection
            else
            {
                NSString *filePath = [[self downloadDirectory] stringByAppendingPathComponent:[self downloadFileName]];
                NSError *error = nil;
                
                BOOL writeOk = [[self urlData] writeToFile:filePath atomically:NO];
                // Requires 10.4
//                BOOL writeOk = [[self urlData] writeToFile:filePath options:NSAtomicWrite error:&error];
                
                // No url data write to file error
                if (writeOk)
                {
                    // Download the next file. If there are no more files to be
                    // downloaded, this will do nothing.
                    [self downloadNextFile];
                    
                    // No more files to download, so process downloaded files.
                    // Download file name will be nil when there are no more
                    // files to download
                    if (![self downloadFileName])
                    {
                        // Process files for bid data download
                        if (CSBidFileDownloadBidDataType == [self type])
                        {
                            [self setProgressText:@"Processing Bid Data..."];
                            [self processDownloadedFiles];
                        }
                        
                        // Post notification the bid file download did finish
                        [[NSNotificationCenter defaultCenter] 
                            postNotificationName:CSBidFileDownloadDidFinishNotification
                            object:self];
                    }
                }
                
                // Error writing url data write to file
                else
                {
                    NSError *newError = [self bidInfoErrorForReason:[error localizedDescription]];
                    // Post notification for error
                    NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObject:newError forKey:CSBidFileDownloadErrorKey];
                    [[NSNotificationCenter defaultCenter] 
                        postNotificationName:CSBidFileDownloadDidFinishNotification 
                        object:self 
                        userInfo:notificationUserInfo];
                }
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSError *newError = [self bidInfoErrorForReason:[error localizedDescription]];
    // Post notification for error
    NSDictionary *notificationUserInfo = [NSDictionary dictionaryWithObject:newError forKey:CSBidFileDownloadErrorKey];
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:CSBidFileDownloadDidFinishNotification 
        object:self 
        userInfo:notificationUserInfo];
}

#pragma mark
#pragma mark Utility Methods
#pragma mark

// from RFC 2396 reserved    = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" |"$" | ","
- (NSString *)stringByAddingPercentEscapesToString:(NSString *)unescapedString;
{
   NSString *escapedString =
      (NSString *)CFURLCreateStringByAddingPercentEscapes(
         kCFAllocatorDefault, 
         (CFStringRef)unescapedString, 
         NULL, 
         CFSTR(";/?:@&=+$,"), 
         kCFStringEncodingUTF8);
         
   return [escapedString autorelease];
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (CSBidPeriod *)bidPeriod {
    return _bidPeriod;
}

- (void)setBidPeriod:(CSBidPeriod *)value {
    if (_bidPeriod != value) {
        [_bidPeriod release];
        _bidPeriod = [value copy];
    }
}

- (NSString *)userID {
    return [[_userID retain] autorelease];
}

- (void)setUserID:(NSString *)value {
    if (_userID != value) {
        [_userID release];
        _userID = [value copy];
    }
}

- (NSString *)password {
    return [[_password retain] autorelease];
}

- (void)setPassword:(NSString *)value {
    if (_password != value) {
        [_password release];
        _password = [[self stringByAddingPercentEscapesToString:value] copy];
    }
}

- (NSString *)progressText {
    return [[_progressText retain] autorelease];
}

- (void)setProgressText:(NSString *)value {
    if (_progressText != value) {
        [_progressText release];
        _progressText = [value copy];
    }
}

- (CSBidFileDownloadType)type {
    return _type;
}

- (void)setType:(CSBidFileDownloadType)value {
    if (_type != value) {
        _type = value;
    }
}

- (NSString *)downloadDirectory {
    return [[_downloadDirectory retain] autorelease];
}

- (void)setDownloadDirectory:(NSString *)value {
    if (_downloadDirectory != value) {
        [_downloadDirectory release];
        _downloadDirectory = [value copy];
    }
}

- (NSArray *)filesToDownload {
    return [[_filesToDownload retain] autorelease];
}

- (void)setFilesToDownload:(NSArray *)value {
    if (_filesToDownload != value) {
        [_filesToDownload release];
        _filesToDownload = [value copy];
        // Set file enumerator
        [self setFileEnumerator:[[self filesToDownload] objectEnumerator]];
    }
}

- (NSEnumerator *)fileEnumerator {
    return [[_fileEnumerator retain] autorelease];
}

- (void)setFileEnumerator:(NSEnumerator *)value {
    if (_fileEnumerator != value) {
        [_fileEnumerator release];
        _fileEnumerator = [value retain];
    }
}

- (NSString *)downloadFileName {
    return [[_downloadFileName retain] autorelease];
}

- (void)setDownloadFileName:(NSString *)value {
    if (_downloadFileName != value) {
        [_downloadFileName release];
        _downloadFileName = [value copy];
    }
}

- (NSString *)prelogonCredential {
    return [[_prelogonCredential retain] autorelease];
}

- (void)setPrelogonCredential:(NSString *)value {
    if (_prelogonCredential != value) {
        [_prelogonCredential release];
        _prelogonCredential = [[self stringByAddingPercentEscapesToString:value] copy];
    }
}

- (NSString *)sessionCredential {
    return [[_sessionCredential retain] autorelease];
}

- (void)setSessionCredential:(NSString *)value {
    if (_sessionCredential != value) {
        [_sessionCredential release];
        _sessionCredential = [[self stringByAddingPercentEscapesToString:value] copy];
    }
}

- (BOOL)isDownloading {
    return _isDownloading;
}

- (void)setIsDownloading:(BOOL)value {
    if (_isDownloading != value) {
        _isDownloading = value;
    }
}

- (NSMutableURLRequest *)urlRequest {
    return [[_urlRequest retain] autorelease];
}

- (void)setURLRequest:(NSMutableURLRequest *)value {
    if (_urlRequest != value) {
        [_urlRequest release];
        _urlRequest = [value mutableCopy];
    }
}

- (NSURLConnection *)urlConnection {
    return [[_urlConnection retain] autorelease];
}

- (void)setURLConnection:(NSURLConnection *)value {
    if (_urlConnection != value) {
        [_urlConnection release];
        _urlConnection = [value retain];
    }
}

- (NSMutableData *)urlData {
    return [[_urlData retain] autorelease];
}

- (void)setURLData:(NSMutableData *)value {
    if (_urlData != value) {
        [_urlData release];
        _urlData = [value mutableCopy];
    }
}

- (CSBidFileDownloadStatus)status {
    return _status;
}

- (void)setStatus:(CSBidFileDownloadStatus)value {
    _status = value;
}

- (NSString *)bidEmployeeNumber {
    return [[_bidEmployeeNumber retain] autorelease];
}

- (void)setBidEmployeeNumber:(NSString *)value {
    if (_bidEmployeeNumber != value) {
        [_bidEmployeeNumber release];
        _bidEmployeeNumber = [value copy];
    }
}

@end
