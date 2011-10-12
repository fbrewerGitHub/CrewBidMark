//
//  CBBlockTimeFormatter.h
//  CrewBid
//
//  Created by Mark Ackerman on 8/7/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBBlockTimeFormatter : NSFormatter
{
   @protected
   NSCharacterSet * invertedDecimalDigitPlusTimeSeparatorCharacterSet;
   NSCharacterSet * timeSeparatorCharacterSet;
}

@end
