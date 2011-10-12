//
//  CSBidDataImporter.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 6/22/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSBidDataImporter.h"

#import <regex.h>

#import "CSBidDocumentFile.h"
#import "CSBidPeriod.h"
#import "CSBidLine.h"
#import "CSBidLineTrip.h"
#import "CSTrip.h"
#import "CSTripLeg.h"
#import "CSPredicateOperator.h"

NSString *CSSecondRoundTripKeyFormat = @"%@_%d";

@implementation CSBidDataImporter

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod
{
    if (self = [super init])
    {
        [self setBidPeriod:bidPeriod];
    }
    
    return self;
}

- (void) dealloc
{
    [self setBidPeriod:nil];
    [self setTrips:nil];
    [self setTripLegs:nil];
    [super dealloc];
}

#pragma mark
#pragma mark Data Importing
#pragma mark

- (NSURL *)importBidLineNumbers
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSError *error = nil;
    // Bid period values
    NSDictionary *bidPerVals = [[self bidPeriodValues] dictionaryWithValuesForKeys:
        [NSArray arrayWithObjects:
            @"month",
            @"base",
            @"position",
            @"round", nil]];
    // Bid document file
    CSBidDocumentFile *bidDocFile = [NSEntityDescription insertNewObjectForEntityForName:@"BidDocumentFile" inManagedObjectContext:moc];    
    [bidDocFile setValuesForKeysWithDictionary:bidPerVals];
    NSString *bidDocPath = [[self bidPeriodValues] bidDocumentPath];
    NSURL *bidDocURL = [NSURL fileURLWithPath:bidDocPath];
    [bidDocFile setValue:bidDocURL forKey:@"url"];
    // Save
    if (![moc save:&error])
    {
        NSLog(@"error saving managed object context: %@", error);
    }
    // Create new managed object context for bid data
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *momPath = [mainBundle pathForResource:@"BidDocument" ofType:@"mom"];
    NSURL *momURL = [NSURL fileURLWithPath:momPath];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    [mom release];
    moc = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:psc];
    [psc release];
    [self setManagedObjectContext:moc];
    [moc release];
//    id bidDocStore = [psc addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:bidDocURL options:nil error:&error];
    id bidDocStore = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:bidDocURL options:nil error:&error];
    if (bidDocStore)
    {
        [self setBidDocumentStore:bidDocStore];
    }
    else
    {
        [NSApp presentError:error];
    }
    // Bid period
    CSBidPeriod *bidPer = [NSEntityDescription insertNewObjectForEntityForName:@"BidPeriod" inManagedObjectContext:moc];
    [bidPer setValuesForKeysWithDictionary:bidPerVals];
    [bidPer setValue:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES] autorelease]] forKey:@"bidLineSorts"];
    // Import bid lines, setting number and order only
    NSDate *start = [NSDate date];
    NSMutableSet *bidLines = [NSMutableSet setWithCapacity:1024];
    NSEntityDescription *bidLineEntity = [NSEntityDescription entityForName:@"BidLine" inManagedObjectContext:moc];
    NSRange numRange = {0, 6};
    int order = 1;
    char lineRec[128];
    lineRec[0] = '\0';
    FILE *fp = fopen([[self valueForKeyPath:@"bidPeriodValues.linesDataFilePath"] UTF8String], "r");

    while (fgets(lineRec, 127, fp))
    {
		if ('*' == lineRec[0]) break;
		
		CSBidLine *line = [[CSBidLine alloc] initWithEntity:bidLineEntity insertIntoManagedObjectContext:moc];
        int lineNum = IntFromCStringRange(lineRec, numRange);
        SetManagedObjectIntValueForKey(line, lineNum, @"number");
        SetManagedObjectIntValueForKey(line, order, @"order");
        SetManagedObjectBoolValueForKey(line, YES, @"isSelected");
        
        if ('C' == lineRec[70])
        {
            fgets(lineRec, 127, fp);
        }
		
        [bidLines addObject:line];
        [line release];
        order++;
    }

    fclose(fp);
    
    [bidPer setValue:bidLines forKey:@"bidLines"];;
    [bidPer setValue:[NSNumber numberWithInt:0] forKey:@"topFreeze"];
    [bidPer setValue:[NSNumber numberWithInt:[bidLines count] + 1] forKey:@"bottomFreeze"];

    // Save
    NSLog(@"Elapsed reading: %0.2f", [[NSDate date] timeIntervalSinceDate:start]);
    start = [NSDate date];
    if (![moc save:&error])
    {
        NSLog(@"error saving managed object context: %@", error);
    }
    NSLog(@"Elapsed saving: %0.2f", [[NSDate date] timeIntervalSinceDate:start]);
    
    NSDictionary *hideFileExtAttr = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden];
    if (![[NSFileManager defaultManager] changeFileAttributes:hideFileExtAttr atPath:bidDocPath])
    {
        NSLog(@"unable to change attributes for file: %@", [bidDocPath lastPathComponent]);
    }
    
    return bidDocURL;
}

- (void)importBidDataForBidPeriod:(CSBidPeriod *)bidPeriod
{
    [self setBidPeriodValues:[bidPeriod bidPeriodValues]];
    [self setManagedObjectContext:[bidPeriod managedObjectContext]];
    // Trips
    NSDate *start = [NSDate date];
    [self importTrips];
    // Add second round trips
    if ([[self bidPeriodValues] isSecondRoundBid])
    {
        [self addSecondRoundTripsForBidPeriod:bidPeriod];
    }
    [bidPeriod setTrips:[self trips]];
    // Bid lines
    [self importBidLinesDataForBidPeriod:bidPeriod];
    NSLog(@"Elapsed reading: %0.2f", [[NSDate date] timeIntervalSinceDate:start]);
    // Predicate operators
    [self insertPredicateOperatorsForBidPeriod:bidPeriod];
}

- (void)insertPredicateOperatorsForBidPeriod:(CSBidPeriod *)bidPeriod
{
    // First see if there are any predicate operators, and insert them if not
    NSManagedObjectContext *moc = [bidPeriod managedObjectContext];
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    NSEntityDescription *predOpEntity = [NSEntityDescription entityForName:@"PredicateOperator" inManagedObjectContext:moc];
    [fr setEntity:predOpEntity];
    [fr setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:fr error:&error];
    [fr release];
    if (error)
    {
        NSLog(@"CSBidDataImporter error fetching predicate operators: %@", error);
    }
    else if (!results || [results count] == 0)
    {
        NSUndoManager *um = [moc undoManager];
        [um disableUndoRegistration];
        int opType = 0;
        int max = NSCustomSelectorPredicateOperatorType;
        for (opType = 0; opType <= max; opType++)
        {
            // Skip predicate operators in which we are not interested
            if (opType > NSNotEqualToPredicateOperatorType && 
                opType < NSInPredicateOperatorType)
            {
                continue;
            }
            CSPredicateOperator *predOp = [[CSPredicateOperator alloc] initWithEntity:predOpEntity insertIntoManagedObjectContext:moc];
            NSNumber *op = [[NSNumber alloc] initWithInt:opType];
            [predOp setOperatorType:op];
            [predOp release];
            [op release];
        }
        [moc processPendingChanges];
        [um enableUndoRegistration];
        [moc save:&error];
        if (error)
        {
            NSLog(@"CSBidDataImporter error saving after inserting predicate operators: %@", error);
        }
    }
}

#pragma mark
#pragma mark Trip File
#pragma mark

- (void)importTrips
{
	NSMutableDictionary *tripsDict = [NSMutableDictionary dictionaryWithCapacity:1024];
    NSRange numRange = {0, 4};
    unsigned amIdx = 36;
	CSTrip *trip = nil;
    char tripRec[128];
    tripRec[0] = '\0';
	char rec5[512];
	rec5[0] = '\0';
	char rec6[512];
	rec6[0] = '\0';
	NSRange dataRange = {5, 72};
	NSRange recCountRange = {79, 1};
	int recCount = 0;
	int i = 0;
    
    // Trips pay file
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *tripsPayFilePath = [[self bidPeriodValues] tripsPayFilePath];
    if (![fm fileExistsAtPath:tripsPayFilePath])
    {
        [self grepTripTextFile];
    }
    FILE *tpfp = fopen([tripsPayFilePath UTF8String], "r");
    
    // Trips file
    FILE *fp = fopen([[[self bidPeriodValues] tripsDataFilePath] UTF8String], "r");	
    while (fgets(tripRec, 127, fp))
	{
		if ('*' == tripRec[0]) break;
		
		switch (tripRec[4])
		{
			case '1':
				trip = [[CSTrip alloc] init];
                NSString *tripNum = CopyStringFromCStringRange(tripRec, numRange);
                [trip setNumber:tripNum];
                // YES is default for CSTrip isAm, so only need to set if not 
                // AM trip
                if ('1' == tripRec[amIdx])
                {
                    [trip setIsAM:YES];
                }
				[tripsDict setObject:trip forKey:tripNum];
                [tripNum release];
				break;
			case '2':
				[self setDaysPayForTrip:trip withTripRecord:tripRec];
				recCount = IntFromCStringRange(tripRec, recCountRange);
				break;
			case '5':
				strncat(rec5, tripRec + dataRange.location, dataRange.length);
				for (i = 1; i < recCount; i++)
				{
					fgets(tripRec, 127, fp);
					strncat(rec5, tripRec + dataRange.location, dataRange.length);
				}
				recCount = IntFromCStringRange(tripRec, recCountRange);
				break;
			case '6':
				strncat(rec6, tripRec + dataRange.location, dataRange.length);
				for (i = 1; i < recCount; i++)
				{
					fgets(tripRec, 127, fp);
					strncat(rec6, tripRec + dataRange.location, dataRange.length);
				}
				[self addLegsForTrip:trip withRecord5:rec5 record6:rec6 payFile:tpfp];
                [trip release];
				rec5[0] = '\0';
				rec6[0] = '\0';
				break;
			default:
				break;
		}
	}

    fclose(tpfp);
    fclose(fp);
    
    [self setTrips:tripsDict];
    
    int la = 0;
    NSArray *allTrips = [tripsDict allValues];
    unsigned count = [allTrips count];
    for (i = 0; i < count; i++)
    {
        trip = [allTrips objectAtIndex:i];
        int arr = [[trip lastLeg] arrive] % (24 * 60);
        if ([trip isAM] && arr > la)
        {
            la = arr;
            div_t divArr = div( arr, 60 );
            NSLog(@"Trip %@ arrives: %02d:%02d", [trip number], divArr.quot, divArr.rem);
        }
    }
}

- (void)setDaysPayForTrip:(CSTrip *)trip withTripRecord:(char *)tripRec
{
	NSMutableArray *daysPay = [NSMutableArray arrayWithCapacity:4];
	
	NSRange payRange = {8, 4};
	unsigned INTVL = 7;
	float pay = 0.0;
	unsigned idx = 0;
	while (idx < 10)
	{
		pay = PayFromCStringRange(tripRec, payRange);
		if (0.0 == pay) break;
        NSNumber *payNum = [[NSNumber alloc] initWithFloat:pay];
        [daysPay addObject:payNum];
        [payNum release];
		payRange.location += INTVL;
		idx++;
	}
    [trip setValue:daysPay forKey:@"daysPay"];
    [trip setLength:idx];
    [trip setPay:[[daysPay valueForKeyPath:@"@sum.self"] floatValue]];
}

- (void)addLegsForTrip:(CSTrip *)trip withRecord5:(char *)rec5 record6:(char *)rec6 payFile:(FILE *)payFilePtr
{
    // Read first line of trips pay file to get trip number
    char payStr[128];
    payStr[127] = '\0';
    NSRange tripNumRange = {0, 4};
    if (fgets(payStr, 127, payFilePtr))
    {
        NSString *tripNum = CopyStringFromCStringRange(payStr, tripNumRange);
        if (![tripNum isEqualToString:[trip valueForKey:@"number"]])
        {
            NSLog(@"Reading leg pay for wrong trip: %@", tripNum);
        }
        [tripNum release];
    }
    // Leg pay range
    NSRange payRange = {55, 5};

	unsigned dhIdx = 0;
	NSRange depRange = {2, 4};
	unsigned newDayIdx = 6;
	NSRange arrRange = {8, 4};
	NSRange fltRange = {0, 6};
	NSRange depCityRange = {6, 3};
	NSRange arrCityRange = {9, 3};
	unsigned acIdx = 12;
    int acCount = 0;
	NSRange equipRange = {13, 1};
	int maxLegs = strlen(rec5) / 12;
	int idx = 0;
    id prevLeg = nil;
    NSMutableArray *legs = [NSMutableArray arrayWithCapacity:maxLegs];
	while (idx < maxLegs)
	{
		if (0 == IntFromCStringRange(rec5, depRange)) break;
        // Create trip leg
		CSTripLeg *leg = [[CSTripLeg alloc] init];
		if ('9' == rec5[newDayIdx])
		{
            [leg setIsNewDay:YES];
		}
        if ('2' == rec5[dhIdx])
		{
            [leg setIsDeadhead:YES];
		}
        NSString *flight = CopyFlightFromCStringRange(rec6, fltRange);
        [leg setFlight:flight];
        [flight release];
        NSString *city = CopyStringFromCStringRange(rec6, depCityRange);
        [leg setDepartCity:city];
        [city release];
        [leg setDepart:IntFromCStringRange(rec5, depRange)];
        city = CopyStringFromCStringRange(rec6, arrCityRange);
        [leg setArriveCity:city];
        [city release];
        [leg setArrive:IntFromCStringRange(rec5, arrRange)];
        if ('*' == rec6[acIdx])
		{
            [leg setIsAircraftChange:YES];
            acCount++;
		}
        [leg setEquipment:IntFromCStringRange(rec6, equipRange)];     
        
        if (prevLeg)
        {
            [prevLeg setNextLeg:leg];
        }
        
        // Leg pay
        if (fgets(payStr, 127, payFilePtr))
        {
            float pay = FloatFromCStringRange(payStr, payRange);
            if (0.0 != pay)
            {
                [leg setPay:pay];
            }
            else
            {
                NSLog(@"Leg pay is 0.0");
            }
        }
        
        [legs addObject:leg];
        [leg release];
        prevLeg = leg;
		
		dhIdx += 12;
		depRange.location += 12;
		newDayIdx += 12;
		arrRange.location += 12;
		fltRange.location += 15;
		depCityRange.location += 15;
		arrCityRange.location += 15;
		acIdx += 15;
		equipRange.location += 15;
		idx++;
	}
    [trip setLegs:legs];
    [trip setAircraftChangesCount:acCount];
}

- (void)grepTripTextFile
{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *fh = [pipe fileHandleForReading];
    NSData *fhData = nil;
    NSMutableData *grepData = [NSMutableData data];

    NSTask *grep = [[NSTask alloc] init];
    [grep setLaunchPath:@"/usr/bin/grep"];
    [grep setCurrentDirectoryPath:[[self bidPeriodValues] bidDataDirectoryPath]];
    [grep setArguments:[NSArray arrayWithObjects:@"-E", @"([[:upper:]]{2}[[:digit:]]{2}) | ([[:upper:]]{3}.*[[:digit:]]{4}.*[[:upper:]]{3}.*[[:digit:]]{4})", [[self bidPeriodValues] tripsTextFilePath], nil]];
    [grep setStandardOutput:pipe];
    [grep launch];
    
    while ((fhData = [fh availableData]) && [fhData length])
    {
        [grepData appendData:fhData];
    }
    [grep waitUntilExit];
    [grep release];
    
    NSString *tripPayFilePath = [[self bidPeriodValues] tripsPayFilePath];
    NSError *error = nil;
    if (![grepData writeToFile:tripPayFilePath options:NSAtomicWrite error:&error])
    {
        NSLog(@"Error writing trips pay to file: %@", error);
    }
}

#pragma mark
#pragma mark Lines File
#pragma mark

- (void)importBidLinesDataForBidPeriod:(CSBidPeriod *)bidPeriod
{    
    NSArray *bidLines = [[bidPeriod bidLines] allObjects];
    NSArray *bidLineKeys = [bidLines valueForKeyPath:@"number.stringValue"];
    NSDictionary *bidLinesDict = [NSDictionary dictionaryWithObjects:bidLines forKeys:bidLineKeys];

    NSRange numRange = {0, 6};
    NSRange payRange = {71, 5};
	NSRange blkRange = {76, 4};
    char lineRec[128];
    lineRec[0] = '\0';
    FILE *fp = fopen([[self valueForKeyPath:@"bidPeriodValues.linesDataFilePath"] UTF8String], "r");

    while (fgets(lineRec, 127, fp))
    {
		if ('*' == lineRec[0]) break;
		
        NSNumber *lineNum = [[NSNumber alloc] initWithInt:IntFromCStringRange(lineRec, numRange)];
        CSBidLine *line = [bidLinesDict objectForKey:[lineNum stringValue]];
        
        NSAssert(NSOrderedSame == [[line number] compare:lineNum], @"Setting data for wrong line number!");
        [lineNum release];
        
        [line setPay:PayFromCStringRange(lineRec, payRange)];
        [line setBlock:BlockFromCStringRange(lineRec, blkRange)];
        
		[self addTripsForBidLine:line withLineRecord:lineRec];

        if ('C' == lineRec[70])
        {
            fgets(lineRec, 127, fp);
			[self addTripsForBidLine:line withLineRecord:lineRec];
        }
        
        [line setDerivedProperties];
    }

    fclose(fp);
}

- (void)addTripsForBidLine:(CSBidLine *)line withLineRecord:(char *)lineRec
{
    NSMutableArray *lineTrips = [NSMutableArray arrayWithCapacity:16];
    NSDictionary *trips = [self trips];
    CSBidLineTrip *lineTrip = nil;
    NSArray *prevTrips = [line trips];
    if (prevTrips != nil)
    {
        [lineTrips addObjectsFromArray:prevTrips];
    }
	NSDate *month = [[self bidPeriodValues] month];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dc = [cal components: NSYearCalendarUnit | NSMonthCalendarUnit fromDate:month];
	NSRange numRange = {10, 4};
	NSRange dayRange = {14, 2};
	unsigned INTVL = 6;
	int day = 1;
	unsigned idx = 0;
	while (idx < 10)
	{
		day = IntFromCStringRange(lineRec, dayRange);
		if (0 == day) break;
        // Create bid line trip
		lineTrip = [[CSBidLineTrip alloc] init];
		// Trip
		NSString *tripNum = CopyStringFromCStringRange(lineRec, numRange);
		CSTrip *trip =  [trips objectForKey:tripNum];
        // If can't find trip with normal key, try second round key
        if (trip == nil)
        {
            NSString *secRndTripKey = [[NSString alloc] initWithFormat:CSSecondRoundTripKeyFormat, tripNum, day];
            trip = [trips objectForKey:secRndTripKey];
            [secRndTripKey release];
        }
        
		NSAssert3(trip != nil, @"Can't find trip %@ dated %@ for line %@", tripNum, [cal dateFromComponents:dc], [line valueForKey:@"number"]);
        [tripNum release];
		[lineTrip setTrip:trip];
		// Date
        [dc setDay:day];
        [lineTrip setDate:[cal dateFromComponents:dc]];

        // Add line trip to array and release
        [lineTrips addObject:lineTrip];
        [lineTrip release];
		// Increment for next trip
		numRange.location += INTVL;
		dayRange.location += INTVL;
		idx++;
	}
    
    [line setTrips:lineTrips];
}

#pragma mark
#pragma mark Second Round Trips
#pragma mark

- (void)addSecondRoundTripsForBidPeriod:(CSBidPeriod *)bidPeriod
{
    NSMutableDictionary *tripsDict = [[self trips] mutableCopy];
    NSMutableArray *tripLegs = [[NSMutableArray alloc] initWithCapacity:4];
    char trip1stChar = [self tripNumberFirstChar];
    // Create regular expression for finding second round trips in lines
    // text file. The regular expression should find text that begins with
    // the letters P-V, followed by 2 digits, and not followed by an '='
    // sign (to avoid finding the text for trip times and pay).
    char *tripPattern = "[P-V][[:digit:]]{2}[^=]";
    regex_t tripRegEx;
    regcomp(&tripRegEx, tripPattern, REG_EXTENDED);
    
    // Variables for regular expression matching and reading data
    char tripStr[256];
    tripStr[0] = 0;
    regmatch_t pMatch[1];
    int tripStart = 0;
    char tripNum[4];
    tripNum[3] = 0;
    int day = 0;
    int tripLen = 0;
    char ovntStr[256];
    char ovnt[4];
    ovnt[3] = 0;
    char payStr[256];
    int payStart = 0;
    char payRegExPattern[128];
    payRegExPattern[0] = 0;
    char pay[64];
    pay[0] = 0;

    // Used for determining end of trip
    const char *base = [[bidPeriod base] UTF8String];
    
    // Open lines text file
    NSString *linesTextFilePath = [[self bidPeriodValues] linesTextFilePath];
    FILE *fp = fopen([linesTextFilePath UTF8String], "r");
    
    // Read each line of text file, searching for text that matches trip
    while (fgets(tripStr, 255, fp))
    {
        // Reset variables
        tripStart = 0;
        tripLen = 0;
        ovntStr[0] = 0;
        payStr[0] = 0;
        payStart = 0;
        
        // Match each trip in line of text
        while (0 == regexec(&tripRegEx, tripStr + tripStart, 1, pMatch, 0))
        {
            // Start of trip number: copy 3 characters into trip number
            tripStart = pMatch[0].rm_so + tripStart;
            strncpy(tripNum, tripStr + tripStart, 3);
            
            // Day of trip
            day = (tripStart - 24) / 3 + 1;
            
            // Create a new trip and add to trips dictionary
            CSTrip *trip = [[CSTrip alloc] init];
            NSString *num = [[NSString alloc] initWithFormat:@"%c%s", trip1stChar, tripNum];
            [trip setNumber:num];
            NSString *key = [[NSString alloc] initWithFormat:CSSecondRoundTripKeyFormat, num, day];
            [tripsDict setObject:trip forKey:key];
            [num release];
            [key release];
           
            // If overnight string has not yet been read, read it now
            if (0 == strlen(ovntStr))
            {
                fgets(ovntStr, 255, fp);
            }
            
            // Starting at index where trip started in the trip string, read
            // overnight cities until reaching city that is equal to the base,
            // which will indicate the end of the trip. Note that this will also
            // move trip start up to end of trip, placing it in the correct
            // position to search for the next trip in the line of text.
            CSTripLeg *leg = [[CSTripLeg alloc] init];
            [leg setDepartCity:[bidPeriod base]];
            strncpy(ovnt, ovntStr + tripStart, 3);
            NSString *city = [[NSString alloc] initWithCString:ovnt encoding:NSASCIIStringEncoding];
            [leg setArriveCity:city];
            [tripLegs addObject:leg];
            [leg release];
            tripLen++;
            while (0 != strncmp(base, ovnt, 3))
            {
                // Create a new leg, set depart city, and is new day
                leg = [[CSTripLeg alloc] init];
                [leg setDepartCity:city];
                [city release]; city = nil;
                [leg setIsNewDay:YES];
                // Get next city, and set leg arrive city
                tripStart += 3;
                strncpy(ovnt, ovntStr + tripStart, 3);
                city = [[NSString alloc] initWithCString:ovnt encoding:NSASCIIStringEncoding];
                [leg setArriveCity:city];
                // Add leg to array and release
                [tripLegs addObject:leg];
                [leg release];
                tripLen++;
            }
            [city release]; city = nil;
            [trip setLegs:tripLegs];
            [tripLegs removeAllObjects];
            [trip setLength:tripLen];
            tripLen = 0;
            tripStart += 3;

            // If pay string has not yet been read, read it now
            if (0 == strlen(payStr))
            {
                fgets(payStr, 255, fp);
            }
            // Create a regular expression to find the trip time and pay data
            // in the pay string. The regular expression should find text that
            // begins with trip number, followed by '=' char, followed by 4
            // digits, followed by '/' char, followed by 4 digits, followed by
            // '(' char, followed by 1 to 2 digits, followed by '.' char, 
            // followed by 2 digits, followed by ')' char. Something with the
            // format 'FP01=0600/1400(22.10)'.
            strcat(payRegExPattern, tripNum);
            strcat(payRegExPattern, "=[[:digit:]]{4}\\/[[:digit:]]{4}\\([[:digit:]]{1,2}\\.[[:digit:]]{2}\\)");
            regex_t payRegEx;
            regcomp(&payRegEx, payRegExPattern, REG_EXTENDED);
            // Attempt to match trip time and pay data
            if(0 != regexec(&payRegEx, payStr + payStart, 1, pMatch, 0))
            {
                // No match, so try to match with the next line of text
                fgets(payStr, 255, fp);
                payStart = 0;
                if(0 != regexec(&payRegEx, payStr + payStart, 1, pMatch, 0))
                {
                    // Still no match, so log error and bail
                    fprintf(stderr, "Could not find pay and times for trip %s\n", tripNum);
                    // Reset for next trip
                    [trip release];
                    payRegExPattern[0] = 0;
                    payStart += pMatch[0].rm_eo;
                    regfree(&payRegEx);
                    continue;
                }
            }
            // Set pay string
            strncpy(pay, payStr + payStart + pMatch[0].rm_so + 4, pMatch[0].rm_eo - pMatch[0].rm_so);
            pay[pMatch[0].rm_eo - pMatch[0].rm_so - 4] = 0;
            
            // Set depart time for first leg of trip, arrive time for last leg 
            // of trip, and pay for trip
            char tripPayStr[6];
            tripPayStr[5] = 0;
            NSRange r = NSMakeRange(0, 4);
            [[trip firstLeg] setDepart:BlockFromCStringRange(pay, r)];
            r.location = 5;
            [[trip lastLeg] setArrive:BlockFromCStringRange(pay, r)];
            strncpy(tripPayStr, pay + 10, 5);
            [trip setPay:atof(tripPayStr)];
            // Set isAm for trip
            if ([[trip lastLeg] arrive] < 18 * 60)
            {
                [trip setIsAM:YES];
            }
            
            // Reset for next trip
            [trip release];
            payRegExPattern[0] = 0;
            payStart += pMatch[0].rm_eo;
            regfree(&payRegEx);
        }
    }
    
    [self setTrips:tripsDict];
    
    // Clean up
    [tripsDict release];
    [tripLegs release];
    fclose(fp);
    regfree(&tripRegEx);
}

- (char)tripNumberFirstChar
{
    // Get first char of trip number (e.g., 'F' for MCO)
    char tripNumberFirstChar = '\0';
    NSArray *allTripNums = [[self trips] allKeys];
    if (allTripNums && [allTripNums count])
    {
        NSString *tripNum = [allTripNums objectAtIndex:0];
        tripNumberFirstChar = [tripNum characterAtIndex:0];
    }
    else
    {
      NSLog(@"Trips dictionary is empty!");
    }
    
    return tripNumberFirstChar;
}


#pragma mark
#pragma mark File Reading Utility Functions
#pragma mark

NSString * CopyStringFromCStringRange( char *str, NSRange r )
{
    char *temp = malloc(r.length + 1);
    temp[r.length] = '\0';
    strncpy(temp, str + r.location, r.length);
	NSString *s = [[NSString alloc] initWithUTF8String:temp];
	free(temp);
	return s;
}

float PayFromCStringRange( char *str, NSRange r)
{
	// Integer part is all characters up to last two characters of range
	NSRange intPartRange = {r.location, r.length - 2};
	// Fractional part is last two characters of range
	NSRange fracPartRange = {r.location + intPartRange.length, 2};
	// Pay is integer part plus fractional part divided by 60
	float pay = FloatFromCStringRange(str, intPartRange) + FloatFromCStringRange(str, fracPartRange) / 60.0;
	return pay;
}

int BlockFromCStringRange( char *str, NSRange r)
{
	// Hours part is all characters up to last two characters of range
	NSRange hoursRange = {r.location, r.length - 2};
	// Minutes part is last two characters of range
	NSRange minsRange = {r.location + hoursRange.length, 2};
	// Block (minutes) is hours times 60 plus minutes
	int block = IntFromCStringRange(str, hoursRange) * 60 + IntFromCStringRange(str, minsRange);
	return block;
}

int IntFromCStringRange( char *str, NSRange r)
{
    char *temp = malloc(r.length + 1);
    temp[r.length] = '\0';
    strncpy(temp, str + r.location, r.length);
	int retInt = atoi(temp);
    free(temp);
	return retInt;
}

float FloatFromCStringRange( char *str, NSRange r)
{
    char *temp = malloc(r.length + 1);
    temp[r.length] = '\0';
    strncpy(temp, str + r.location, r.length);
    float retFloat = atof(temp);
    free(temp);
	return retFloat;
}

NSString * CopyFlightFromCStringRange( char *str, NSRange r)
{
    char *temp = malloc(r.length + 1);
    temp[r.length] = '\0';
    strncpy(temp, str + r.location, r.length);
    NSString *s = nil;
    // Reserve
    if (0 != strncmp(temp, "DH", 2) && 0 != strncmp(temp, "  ", 2))
    {
        temp[3] = '\0';
        s = [[NSString alloc] initWithUTF8String:temp];
    }
    else
    {
        // Get the flight number
        int fltNum = atoi(temp + 2);
        // Deadhead
        if ('D' == temp[0])
        {
            s = [[NSString alloc] initWithFormat:@"DH%4d", fltNum];
        }
        // Not deadhead, just the flight number
        else
        {
            s = [[NSString alloc] initWithFormat:@"%d", fltNum];
        }
    }
    
	free(temp);
	return s;
}

void SetManagedObjectIntValueForKey( NSManagedObject *mo, int val, NSString *key )
{
    NSNumber *num = [[NSNumber alloc] initWithInt:val];
    [mo setValue:num forKey:key];
    [num release];
}

void SetManagedObjectFloatValueForKey( NSManagedObject *mo, float val, NSString *key )
{
    NSNumber *num = [[NSNumber alloc] initWithFloat:val];
    [mo setValue:num forKey:key];
    [num release];
}

void SetManagedObjectBoolValueForKey( NSManagedObject *mo, BOOL val, NSString *key )
{
    NSNumber *num = [[NSNumber alloc] initWithBool:val];
    [mo setValue:num forKey:key];
    [num release];
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

- (NSDictionary *)trips {
    return _trips;
}

- (void)setTrips:(NSDictionary *)value {
    if (_trips != value) {
        [_trips release];
        _trips = [value copy];
    }
}

- (NSMutableDictionary *)tripLegs {
    if (!_tripLegs)
    {
        _tripLegs = [NSMutableDictionary dictionaryWithCapacity:1024];
    }
    return _tripLegs;
}

- (void)setTripLegs:(NSDictionary *)value {
    if (_tripLegs != value) {
        [_tripLegs release];
        _tripLegs = [value mutableCopy];
    }
}

@end
