//
//  CSBidFileDownload.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 3/4/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CSBidDataModel;
@class CSBidPeriod;


typedef enum _CSBidFileDownloadType
{
    CSBidFileDownloadBidDataType,
    CSBidFileDownloadBidSubmissionType,
    CSBidFileDownloadBidAwardsType

} CSBidFileDownloadType;

typedef enum _CSBidFileDownloadStatus
{
    CSBidFileDownloadPrelogonCredential,
    CSBidFileDownloadSessionCredential,
    CSBidFileDownloadFileDownload

} CSBidFileDownloadStatus;


@interface CSBidFileDownload : NSObject
{
    // Bid Period
    CSBidPeriod *_bidPeriod;
    
    // User Credentials
    NSString *_userID;
    NSString *_password;
    
    // Download Progress
    NSString *_progressText;
    
    // File Download
    CSBidFileDownloadType _type;
    NSString *_downloadDirectory;
    NSArray *_filesToDownload;
    NSEnumerator *_fileEnumerator;
    NSString *_downloadFileName;
    NSString *_prelogonCredential;
    NSString *_sessionCredential;
    BOOL _isDownloading;
    NSMutableURLRequest *_urlRequest;
    NSURLConnection *_urlConnection;
    NSMutableData *_urlData;
    CSBidFileDownloadStatus _status;
	
	// bid file employee number - used for bid submission only
	NSString *_bidEmployeeNumber;
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithType:(CSBidFileDownloadType)type directory:(NSString *)directory files:(NSArray *)files;

#pragma mark
#pragma mark Bid File Downloading
#pragma mark

- (void)beginFileDownload;
- (void)retrievePrelogonCredential;
- (void)retrieveSessionCredential;
- (void)downloadNextFile;
- (void)downloadFile:(NSString *)filename;
- (void)cancelBidFileDownload;

#pragma mark
#pragma mark  HTTP Body Data
#pragma mark

- (NSData *)sessionCredentialHTTPBody;
- (NSData *)fileHTTPBodyForFilename:(NSString *)name;
- (NSData *)bidSubmissionHTTPBody;

#pragma mark
#pragma mark File Processing
#pragma mark

- (void)processDownloadedFiles;
- (void)unzipFile:(NSString *)filePath intoDirectory:(NSString *)dirPath;

#pragma mark
#pragma mark Error Handling
#pragma mark

- (NSError *)bidInfoErrorForReason:(NSString *)errorReason;

#pragma mark
#pragma mark Utility Methods
#pragma mark

- (NSString *)stringByAddingPercentEscapesToString:(NSString *)unescapedString;

#pragma mark
#pragma mark Accessors
#pragma mark

- (CSBidPeriod *)bidPeriod;
- (void)setBidPeriod:(CSBidPeriod *)value;

- (NSString *)userID;
- (void)setUserID:(NSString *)value;

- (NSString *)password;
- (void)setPassword:(NSString *)value;

- (NSString *)progressText;
- (void)setProgressText:(NSString *)value;

- (CSBidFileDownloadType)type;
- (void)setType:(CSBidFileDownloadType)value;

- (NSString *)downloadDirectory;
- (void)setDownloadDirectory:(NSString *)value;

- (NSArray *)filesToDownload;
- (void)setFilesToDownload:(NSArray *)value;

- (NSEnumerator *)fileEnumerator;
- (void)setFileEnumerator:(NSEnumerator *)value;

- (NSString *)downloadFileName;
- (void)setDownloadFileName:(NSString *)value;

- (NSString *)prelogonCredential;
- (void)setPrelogonCredential:(NSString *)value;

- (NSString *)sessionCredential;
- (void)setSessionCredential:(NSString *)value;

- (BOOL)isDownloading;
- (void)setIsDownloading:(BOOL)value;

- (NSMutableURLRequest *)urlRequest;
- (void)setURLRequest:(NSMutableURLRequest *)value;

- (NSURLConnection *)urlConnection;
- (void)setURLConnection:(NSURLConnection *)value;

- (NSMutableData *)urlData;
- (void)setURLData:(NSMutableData *)value;

- (CSBidFileDownloadStatus)status;
- (void)setStatus:(CSBidFileDownloadStatus)value;

- (NSString *)bidEmployeeNumber;
- (void)setBidEmployeeNumber:(NSString *)value;

@end

// Bid file download notification and user info keys
extern NSString *CSBidFileDownloadDidFinishNotification;
extern NSString *CSBidFileDownloadErrorKey;
