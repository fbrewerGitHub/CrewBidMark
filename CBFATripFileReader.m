//
//  CBFATripFileReader.m
//  CrewBid
//
//  Created by Mark on 2/10/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import "CBFATripFileReader.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBTripDayLeg.h"

@implementation CBFATripFileReader

- (id)initWithTripsDataFile:(NSString *)dataPath tripsTextFile:(NSString *)textPath
{
   if (self = [super init]) {
      // check that lines file exists
      if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath]/* &&
          [[NSFileManager defaultManager] fileExistsAtPath:textPath]*/)
      {
         [self setTripsDataPath:dataPath];
//         [self setTripsTextPath:textPath];
      } else {
         NSLog(@"CBFATripFileReader could not find file: %@", dataPath);
         [super dealloc];
         return nil;
      }
   }
   return self;
}

- (void)dealloc
{
   [tripsDataPath release];
   [tripsTextPath release];
   [super dealloc];
}

#pragma mark FILE READING

- (NSDictionary *)tripsDictionary
{
   // return value
   NSMutableDictionary * tripsDict = nil;
   
   NSString * fileContents = nil;
   NSRange  lineRange = NSMakeRange(0, 0);
//   NSUInteger fileLength = 0;
   NSUInteger start = 0;
   NSUInteger lineEnd = 0;
   NSUInteger contentsEnd = 0;
   NSMutableString * fileString = nil;
   NSString *EMPTY_STRING = nil;
   NSString *TRIP_START = nil;
   NSString *LEG_START = nil;
   NSString *DAY_END = nil;
   NSRange TRIP_NUMBER_RANGE = NSMakeRange(2, 4);
   NSRange TRIP_PAY_RANGE = NSMakeRange(45, 5);
   
   NSString *tripNumber = nil;
   float tripPay = 0.0;
   CBTrip *trip = nil;
   NSMutableArray *tripDays = nil;
   CBTripDay *tripDay = nil;
   NSMutableArray *dayLegs = nil;
   CBTripDayLeg *leg = nil;
   CBTripDayLeg *prevLeg = nil;
   CBTripDay *tripFirstDay = nil;
   CBTripDayLeg *tripFirstLeg = nil;
   CBTripDayLeg *tripLastLeg = nil;
   int prefsAmDepartTime = 0;
   int prefsAmArrivalTime = 0;
   
   // allocate trips dictionay for return value
   tripsDict = [[NSMutableDictionary alloc] init];
   // get preferences from user defaults
   prefsAmDepartTime = [[[NSUserDefaults standardUserDefaults] objectForKey:CBAmDepartTimePreferencesKey] intValue];
   prefsAmArrivalTime = [[[NSUserDefaults standardUserDefaults] objectForKey:CBAmArrivalTimePreferencesKey] intValue];

   // get file contents
    fileContents = [[NSString alloc] initWithContentsOfFile:[self tripsDataPath] encoding:NSUTF8StringEncoding error:NULL];
//   fileLength = [fileContents length];
   
   // get first line of file
   [fileContents getLineStart:&start end:&lineEnd contentsEnd:&contentsEnd forRange:lineRange];
   lineRange.location = start;
   lineRange.length = contentsEnd - start;
   fileString = [[NSMutableString alloc] init];
   [fileString setString:[fileContents substringWithRange:lineRange]];
   EMPTY_STRING = @"";
   TRIP_START = @"T1";
   LEG_START = @"L";
   DAY_END = @"D";
   
   while (![fileString isEqualToString:EMPTY_STRING])
   {
      if ([fileString hasPrefix:TRIP_START])
      {
         // add previously created trip to trips dictionary or create new trip 
         if (trip)
         {
            prevLeg = nil;
            // set trip days
            [trip setDays:[NSArray arrayWithArray:tripDays]];
            // set trip day is first day
            tripFirstDay = [tripDays objectAtIndex:0];
            [tripFirstDay setIsFirstDay:YES];
            // set trip departure station
            tripFirstLeg = [[tripFirstDay legs] objectAtIndex:0];
            [trip setDepartureStation:[tripFirstLeg departureCity]];
            // set last leg ground time to 0
            tripLastLeg = [[(CBTripDay *)[tripDays lastObject] legs] lastObject];
            [tripLastLeg setGroundTime:0];
            // set trip length
            [trip setDutyPeriods:[tripDays count]];
            [tripDays release];
            tripDays = nil;
            // set trip departure and arrival times
            [trip initializeDepartureAndReturnTimes];
            // set isAm
            [trip setIsAmWithDefaultAmDepartTime:prefsAmDepartTime arrivalTime:prefsAmArrivalTime];

            // TEMP FIX FOR IS_RESERVE METHOD, WHICH USES TRIP TOTAL BLOCK
            // IF TRIP TOTAL BLOCK IS ZERO, TRIP WILL BE TREATED AS RESERVE
            // AND TRIP BLOCK TIME WILL BE SAME AS RESERVE TRIP
            [trip setTotalBlock:1];

            // add trip to trips dictionary
            [tripsDict setObject:trip forKey:[trip number]];
            [trip release];
            trip = nil;
         }
         trip = [[CBTrip alloc] init];
         // trip number
         tripNumber = [[NSString alloc] initWithString:[fileString substringWithRange:TRIP_NUMBER_RANGE]];
         [trip setNumber:tripNumber];
         [tripNumber release];
         tripNumber = nil;
         // trip pay
         tripPay = (float)[[fileString substringWithRange:TRIP_PAY_RANGE] intValue] / 60.0;
         [trip setCredit:tripPay];
         // trip days
         tripDays = [[NSMutableArray alloc] init];
      }
      else if ([fileString hasPrefix:LEG_START])
      {
         if (!dayLegs)
         {
            dayLegs = [[NSMutableArray alloc] init];
         }
         leg = [self legWithFileString:fileString];
         [dayLegs addObject:leg];
         if (prevLeg)
         {
            [prevLeg setGroundTime:[leg departureTime] - [prevLeg arrivalTime]];
         }
         prevLeg = leg;
      }
      else if ([fileString hasPrefix:DAY_END])
      {
         // create day from legs
         tripDay = [[CBTripDay alloc] init];
         [tripDay setLegs:[NSArray arrayWithArray:dayLegs]];
         [tripDays addObject:tripDay];
         // clean up
         [tripDay release];
         tripDay = nil;
         [dayLegs release];
         dayLegs = nil;
      }
      // get next line of file
      lineRange.location = lineEnd;
      lineRange.length = 0;
      [fileContents getLineStart:&start end:&lineEnd contentsEnd:&contentsEnd forRange:lineRange];
      lineRange.location = start;
      lineRange.length = contentsEnd - start;
      [fileString setString:[fileContents substringWithRange:lineRange]];
   }
   
   // ADD THE LAST TRIP
   // set trip day is first day
   [(CBTripDay *)[tripDays objectAtIndex:0] setIsFirstDay:YES];
   // set last leg ground time to 0
   prevLeg = nil;
   [(CBTripDayLeg *)
      [[(CBTripDay *)[tripDays lastObject] legs] lastObject]
         setGroundTime:0];
   // set trip departure station
   [trip setDepartureStation:
      [(CBTripDayLeg *)[[(CBTripDay *)[tripDays objectAtIndex:0] legs] objectAtIndex:0] departureCity]];
   // set trip length
   [trip setDutyPeriods:[tripDays count]];
   // set trip days
   [trip setDays:[NSArray arrayWithArray:tripDays]];
   [tripDays release];
   tripDays = nil;
   // set trip departure and arrival times
   [trip initializeDepartureAndReturnTimes];
   // set isAm
   [trip setIsAmWithDefaultAmDepartTime:prefsAmDepartTime arrivalTime:prefsAmArrivalTime];

   // TEMP FIX FOR IS_RESERVE METHOD, WHICH USES TRIP TOTAL BLOCK
   // IF TRIP TOTAL BLOCK IS ZERO, TRIP WILL BE TREATED AS RESERVE
   // AND TRIP BLOCK TIME WILL BE SAME AS RESERVE TRIP
   [trip setTotalBlock:1];

   // add trip to trips dictionary
   [tripsDict setObject:trip forKey:[trip number]];
   [trip release];
   trip = nil;

    [fileContents release];
   [fileString release];
   
   return [NSDictionary dictionaryWithDictionary:[tripsDict autorelease]];
}

- (CBTripDayLeg *)legWithFileString:(NSString *)fileString
{
   return [[[CBTripDayLeg alloc] initWithFlightNumber:
         // to make format compatible with pilot line number format,
         // add DH if leg is DH or two spaces if not
         [NSString stringWithFormat:
            ('1' == [fileString characterAtIndex:60] ? @"DH%@" : @"  %@"), 
            [fileString substringWithRange:NSMakeRange(4, 4)]]
      departureCity:
         [fileString substringWithRange:NSMakeRange(13, 3)] 
      departureTime:
         [[fileString substringWithRange:NSMakeRange(23, 4)] intValue] - 1440
      arrivalCity:
         [fileString substringWithRange:NSMakeRange(32, 3)] 
      arrivalTime:
         [[fileString substringWithRange:NSMakeRange(42, 4)] intValue] - 1440
      equipmentType:
         [fileString substringWithRange:NSMakeRange(9, 3)] 
      isDeadhead:
         ('1' == [fileString characterAtIndex:60] ? YES : NO)
      isAircraftChange:
         NO
      ] autorelease];
}

- (void)setTripDaysCreditWithFile:(NSString *)path trips:(NSMutableDictionary *)trips
{
   NSString * fileContents = nil;
   NSScanner *scanner = nil;
   unsigned scanLocation = 0;
   NSCharacterSet *hyphen = nil;
   NSCharacterSet *decPoint = nil;
   NSCharacterSet *colon = nil;
   NSString *tripNumber = nil;
   CBTrip *trip = nil;
   BOOL isNotNewTrip = YES;
   CBTripDay *tripDay = nil;
   CBTripDayLeg *tripDayLeg = nil;
   unsigned tripDayIndex = 0;
   unsigned dayLegIndex = 0;
   NSRange r = NSMakeRange(0, 10);
   NSString *s = nil;
   float dayPay = 0.0;
   NSString *kCredit = @"Credit";
   char c = 0;
   
    fileContents = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
   scanner = [[NSScanner alloc] initWithString:fileContents];
   hyphen = [NSCharacterSet characterSetWithCharactersInString:@"-"];
   decPoint = [NSCharacterSet characterSetWithCharactersInString:@"."];
   colon = [NSCharacterSet characterSetWithCharactersInString:@":"];

   // scan to end of file contents
   while (![scanner isAtEnd])
   {
      isNotNewTrip = YES;
      tripDayIndex = 0;
      dayLegIndex = 0;
      [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&tripNumber];
      trip = [trips objectForKey:tripNumber];
      
      while(isNotNewTrip)
      {
         [scanner scanUpToCharactersFromSet:decPoint intoString:nil];
         scanLocation = [scanner scanLocation];
         r.location = scanLocation - 10;
         s = [fileContents substringWithRange:r];
         // check for end of trip
         if (NSNotFound != [s rangeOfString:kCredit].location)
         {
            isNotNewTrip = NO;
            [scanner scanUpToCharactersFromSet:hyphen intoString:nil];
            [scanner scanCharactersFromSet:hyphen intoString:nil];
         }
         // check for end of trip day
         else if (NSNotFound != [s rangeOfCharacterFromSet:colon].location)
         {
            scanLocation -= 2;
            [scanner setScanLocation:scanLocation];
            [scanner scanFloat:&dayPay];
            tripDay = [[trip days] objectAtIndex:tripDayIndex];
            [tripDay setCredit:dayPay];
            tripDayIndex++;
            dayLegIndex = 0;
         }
         // check for aircraft change and move scan location beyond decimal
         // point
         else
         {
            c = [fileContents characterAtIndex:scanLocation - 19];
            if ('A' == c)
            {
               tripDay = [[trip days] objectAtIndex:tripDayIndex];
               tripDayLeg = [[tripDay legs] objectAtIndex:dayLegIndex];
               [tripDayLeg setIsAircraftChange:YES];
            }
            scanLocation++;
            [scanner setScanLocation:scanLocation];
            dayLegIndex++;
         }
      }
   }
   
   
   [fileContents release];
   [scanner release];
}

#pragma mark ACCESSORS

- (NSString *)tripsDataPath { return tripsDataPath; }
- (void)setTripsDataPath:(NSString *)inValue
{
   if (tripsDataPath != inValue)  {
      [tripsDataPath release];
      tripsDataPath = [inValue copy];
   }
}

- (NSString *)tripsTextPath { return tripsTextPath; }
- (void)setTripsTextPath:(NSString *)inValue
{
   if (tripsTextPath != inValue)  {
      [tripsTextPath release];
      tripsTextPath = [inValue copy];
   }
}

@end
