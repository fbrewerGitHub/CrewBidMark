//
//  CSError.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 4/2/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
    CSBidInfoError = 1
};

@interface CSError : NSObject
{

}

@end

extern NSString *CSCrewScheduleErrorDomain;