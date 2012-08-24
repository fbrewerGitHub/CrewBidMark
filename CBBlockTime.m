//
//  CBBlockTime.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/7/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import "CBBlockTime.h"


@implementation CBBlockTime

#pragma mark INITIALIZATION

- (id)initWithHours:(unsigned)inHours minutes:(unsigned)inMinutes
{
   if (self = [super init]) {
      hours = inHours + inMinutes / 60;
      minutes = inMinutes % 60;
   }
   
   return self;
}

+ (id)blockTimeWithMinutes:(unsigned)inMinutes
{
   unsigned blockHours = inMinutes / 60;
   unsigned blockMinutes = inMinutes % 60;
   CBBlockTime * blockTime = [[CBBlockTime alloc] initWithHours:blockHours minutes:blockMinutes];
   return [blockTime autorelease];
}

+ (id)blockTimeWithString:(NSString *)string
{
   CBBlockTime * blockTime = nil;
   NSScanner * scanner = nil;
   NSString * tempString = @"";
   NSString * decimalDigitString = @"";
   unsigned stringLength = 0;
   unsigned blockHours = 0;
   unsigned blockMinutes = 0;
   
   // remove everything except decimal digits
   scanner = [NSScanner scannerWithString:string];
   while (![scanner isAtEnd]) {
      [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&tempString];
      [scanner scanCharactersFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet] intoString:nil];
      decimalDigitString = [decimalDigitString stringByAppendingString:tempString];
   }
   
   if ((stringLength = [decimalDigitString length])) {
      if (stringLength > 1) {
         blockHours = [[decimalDigitString substringToIndex:stringLength - 2] intValue];
         blockMinutes = [[decimalDigitString substringFromIndex:stringLength - 2] intValue];
      } else if (stringLength > 0) {
         blockMinutes = [[decimalDigitString substringFromIndex:stringLength - 1] intValue];
      }
      blockTime = [[CBBlockTime alloc] initWithHours:blockHours minutes:blockMinutes];
   } else {
      blockTime = [[CBBlockTime alloc] initWithHours:0 minutes:0];
   }
   return [blockTime autorelease];
}

+ (id)zeroBlockTime
{
   return [self blockTimeWithMinutes:0];
}

#pragma mark COPYING

- (id)copyWithZone:(NSZone *)zone
{
   CBBlockTime * copy = [[CBBlockTime allocWithZone:zone] initWithHours:hours minutes:minutes];
   return copy;
}

#pragma mark ARITHMETIC METHODS

- (CBBlockTime *)addBlockTime:(CBBlockTime *)addedBlockTime
{
   unsigned addedMinutes = 0;
   unsigned addedHours = 0;
   
   addedMinutes = ([self minutes] + [addedBlockTime minutes]) % 60;
   minutes = addedMinutes;
   
   addedHours = (([self minutes] + [addedBlockTime minutes]) / 60) + [addedBlockTime hours];
   hours = addedHours;
   return self;
}

- (CBBlockTime *)subtractBlockTime:(CBBlockTime *)subtractedBlockTime
{
      return self;
}

#pragma mark COMPARISON METHODS

- (BOOL)isEqualToBlockTime:(CBBlockTime *)compareValue
{
   return ([self totalMinutes] == [compareValue totalMinutes]);
}

- (BOOL)isZero
{
   return (0 == [self totalMinutes]);
}

#pragma mark DERIVED VALUES

- (unsigned)totalMinutes
{
   unsigned totalMinutes = 0;
   totalMinutes = [self hours] * 60 + [self minutes];
   return totalMinutes;
}

#pragma mark STORAGE

static NSString * CBBlockTimeHoursKey = @"Hours";
static NSString * CBBlockTimeMinutesKey = @"Minutes";

- (void)encodeWithCoder:(NSCoder *)encoder
{
   if ([encoder allowsKeyedCoding]) {
      [encoder encodeInt:[self hours] forKey:CBBlockTimeHoursKey];
      [encoder encodeInt:[self minutes] forKey:CBBlockTimeMinutesKey];
   } else {
      [encoder encodeValueOfObjCType:@encode(int) at:&hours];
      [encoder encodeValueOfObjCType:@encode(int) at:&minutes];
   }
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self = [super init];
   if ([decoder allowsKeyedCoding]) {
      hours = [decoder decodeIntForKey:CBBlockTimeHoursKey];
      minutes = [decoder decodeIntForKey:CBBlockTimeMinutesKey];
   } else {
      [decoder decodeValueOfObjCType:@encode(int) at:&hours];
      [decoder decodeValueOfObjCType:@encode(int) at:&minutes];
   }
   return self;
}

#pragma mark ACCESSORS

- (unsigned)hours { return hours; }

- (unsigned)minutes { return minutes; }

#pragma mark DESCRIPTION

- (NSString *)description
{
   return [NSString stringWithFormat:@"%02d:%02d", hours, minutes];
}

@end
