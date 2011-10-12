//
//  CBLineFileReader.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBLineFileReader.h"
#import "CBLine.h"

@implementation CBLineFileReader

#pragma mark INITIALIZATION

- (id)initWithLinesFile:(NSString *)path trips:(NSDictionary *)trips
{
   if (self = [super init]) {
      // check that lines file exists
      if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
         [self setLinesFilePath:path];
		  [self setTrips:trips];
      } else {
         NSLog(@"CBLineFileReader could not find file: %@", path);
         [super dealloc];
         return nil;
      }
   }
   return self;
}

- (void)dealloc
{
	[linesFilePath release];
	[_trips release];
	[super dealloc];
}

#pragma mark FILE READING
- (NSArray *)linesArray
{
   // create an array of strings that contain data for each line
	NSString * linesString = [NSString stringWithContentsOfFile:[self linesFilePath] encoding:NSUTF8StringEncoding error:NULL];
   NSRange lineRange = NSMakeRange(0, [linesString length]);
   unsigned lineStartIndex = 0;
   unsigned lineEndIndex = 0;
   unsigned nextLineStartIndex = 0;
   [linesString getLineStart:&lineStartIndex end:&nextLineStartIndex contentsEnd:&lineEndIndex forRange:lineRange];
   NSString * lineSeparator = [linesString substringWithRange:NSMakeRange(lineEndIndex, nextLineStartIndex - lineEndIndex)];
   NSArray * linesStringArray = [linesString componentsSeparatedByString:lineSeparator];
   // return value - array of lines
   NSMutableArray * linesArray = [NSMutableArray arrayWithCapacity:([linesStringArray count] - 2)];
   // create line from each data string
   NSString * lineData = nil;
   NSEnumerator * linesEnumerator = [linesStringArray objectEnumerator];
   while (lineData = [linesEnumerator nextObject]) {
      // check that lineData contains valid line data
      // does not contain valid data if it has prefix *E
      if ((![lineData hasPrefix:@"*E"]) && ([lineData length] > 79)) {
         NSMutableArray * lineDataArray = [NSMutableArray arrayWithCapacity:2];
         [lineDataArray addObject:lineData];
         // add next line to data array if it is continued data for line
         const int CONTINUE_INDEX = 70;
         const char CONTINUE_CHAR = 'C';
         if ([lineData characterAtIndex:CONTINUE_INDEX] == CONTINUE_CHAR) {
            [lineDataArray addObject:[linesEnumerator nextObject]];
         }
         // create line
         CBLine * line = [self lineWithData:lineDataArray];
         // add newly created line
         [linesArray addObject:line];
      }
   }
   return [NSArray arrayWithArray:linesArray];
}

// returns nil if lineString does not contain valid line data
// checks for lineString with prefix *E to determine if line contains valid data
- (CBLine *)lineWithData:(NSArray *)lineData
{
   CBLine * line = nil;
   // ranges
   NSRange NUMBER_RANGE = NSMakeRange( 0,  6);
   NSRange CREDIT_RANGE = NSMakeRange(71,  5);
   NSRange BLOCK_RANGE =  NSMakeRange(76,  4);
   NSRange TRIP_RANGE =   NSMakeRange(10, 60);
   // data string
   NSString * dataString = [lineData objectAtIndex:0];
   // number, credit, and block
   int lineNumber = [[dataString substringWithRange:NUMBER_RANGE] intValue];
   float lineCredit = [self lineCreditWithString:[dataString substringWithRange:CREDIT_RANGE]];
   float lineBlock = [self lineBlockWithString:[dataString substringWithRange:BLOCK_RANGE]];
   // trips
   NSMutableArray * lineTrips = [NSMutableArray arrayWithArray:[self lineTripsWithString:[dataString substringWithRange:TRIP_RANGE]]];
   if ([lineData count] > 1) {
      NSString * continuedDataString = [lineData objectAtIndex:1];
      NSArray * continuedLineTrips = [self lineTripsWithString:[continuedDataString substringWithRange:TRIP_RANGE]];
      [lineTrips addObjectsFromArray:continuedLineTrips];
   }
   // need to add some validity checking for line data
   // create line
   line = [[CBLine alloc] initWithNumber:lineNumber credit:lineCredit block:lineBlock trips:[NSArray arrayWithArray:lineTrips]];
   return [line autorelease];
}

- (float)lineCreditWithString:(NSString *)creditData
{
   int creditIntegerPart = [[creditData substringWithRange:NSMakeRange(0, 3)] intValue];
   float creditDecimalPart = [[creditData substringWithRange:NSMakeRange(3, 2)] floatValue];
   if (creditDecimalPart > 0.0) {
      creditDecimalPart /= 60.0;
   }
   return (float)creditIntegerPart + creditDecimalPart;
}

- (float)lineBlockWithString:(NSString *)blockData
{
   int blockIntegerPart = [[blockData substringWithRange:NSMakeRange(0, 2)] intValue];
   float blockDecimalPart = [[blockData substringWithRange:NSMakeRange(2, 2)] floatValue];
   if (blockDecimalPart > 0.0) {
      blockDecimalPart /= 60.00;
   }
   return (float)blockIntegerPart + blockDecimalPart;
}

- (NSArray *)lineTripsWithString:(NSString *)tripData
{
   const int MAX_TRIPS = 10;
   NSMutableArray * lineTrips = [NSMutableArray arrayWithCapacity:MAX_TRIPS];
   const unsigned TRIP_INTVL = 6;
   NSRange tripNumberRange = NSMakeRange(0, 4);
   NSRange tripDateRange =   NSMakeRange(4, 2);
   NSString * tripNumber = nil;
   int tripDate = 0;
   int tripCount = 0;

   while (tripCount < MAX_TRIPS && (![tripNumber = [tripData substringWithRange:tripNumberRange] isEqualToString:@"   0"])) {
      
      tripDate = [[tripData substringWithRange:tripDateRange] intValue];

//      char tripNumSecondChar = [tripNumber characterAtIndex:1];
//      if (tripNumSecondChar >= 'P' && tripNumSecondChar <= 'V')
	   if (![[self trips] objectForKey:tripNumber])
	   {
		   tripNumber = [NSString stringWithFormat:@"%@%d", tripNumber, tripDate];
	   }
      
      NSDictionary * tripDictionary = [NSDictionary dictionaryWithObjectsAndKeys:tripNumber, CBLineTripNumberKey, [NSNumber numberWithInt:tripDate], CBLineTripDateKey, nil];
      [lineTrips addObject:tripDictionary];
      tripCount++;
      tripNumberRange.location += TRIP_INTVL;
      tripDateRange.location += TRIP_INTVL;
   }
   return [NSArray arrayWithArray:lineTrips];
}

#pragma mark ACCESSORS

- (NSString *)linesFilePath { return linesFilePath; }
- (void)setLinesFilePath:(NSString *)inValue
{
   if (linesFilePath != inValue)  {
      [linesFilePath release];
      linesFilePath = [inValue copy];
   }
}

- (NSDictionary *)trips {
    return _trips;
}

- (void)setTrips:(NSDictionary *)value {
    if (_trips != value) {
        [_trips release];
        _trips = [value copy];
    }
}

@end
