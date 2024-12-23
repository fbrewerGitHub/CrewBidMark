//
//  Tests.m
//  Tests
//
//  Created by Mark Ackerman on 5/29/21.
//  Copyright © 2021 Mark Ackerman. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "CSBidDataReader.h"
#import "CSBidPeriod.h"
#import "CBTrip.h"

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)testReadSecondRoundTripFromLinesText {
    // ignore NSCalendarData deprecation warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    CSBidPeriod *bidPeriod = [[CSBidPeriod alloc] init];
    NSCalendarDate *month = [NSCalendarDate dateWithYear:2021 month:5 day:1 hour:0 minute:0 second:0 timeZone:NULL];
    [bidPeriod setMonth:month];
    [bidPeriod setBase:@"PHX"];
    [bidPeriod setRound:[NSNumber numberWithInt:2]];
    [bidPeriod setPosition:@"Captain"];
    CSBidDataReader *bidDataReader = [[CSBidDataReader alloc] initWithBidPeriod:bidPeriod];

#pragma clang diagnostic pop
    
    NSBundle *testBundle = [NSBundle bundleForClass:[Tests class]];
    NSString *path = [testBundle pathForResource:@"PHXCPN" ofType:@"TXT"];
    NSString *lineInfo = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    CBTrip *trip = [bidDataReader readTripForLineNumber:280 tripNumber:@"PP15" tripDate:1 tripSequence:2 fileInfo:lineInfo];
    
    if (trip == NULL) {
        NSLog(@"Failed to find trip P15 in line 280");
        XCTFail(@"Failed to find trip P15 in line 280");
    } else {
        NSLog(@"%@", [trip number]);
    }
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
