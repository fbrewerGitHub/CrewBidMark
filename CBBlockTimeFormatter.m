//
//  CBBlockTimeFormatter.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/7/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import "CBBlockTimeFormatter.h"
#import "CBBlockTime.h"

@implementation CBBlockTimeFormatter

#pragma mark INITIALIZATION

- (id)init
{
   if (self = [super init]) {
   
      NSMutableCharacterSet * tempSet = nil;
      NSCharacterSet * decimalDigitPlusTimeSeparatorCharacterSet = nil;
      
      tempSet = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
      [tempSet addCharactersInString:@":"];
      decimalDigitPlusTimeSeparatorCharacterSet = [tempSet copy];
      [tempSet release];
      
      invertedDecimalDigitPlusTimeSeparatorCharacterSet = [[decimalDigitPlusTimeSeparatorCharacterSet invertedSet] retain];
      [decimalDigitPlusTimeSeparatorCharacterSet release];
      
      timeSeparatorCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@":"] retain];
   }

   return self;
}

- (BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error
{
   BOOL returnValue = NO;
   CBBlockTime * blockTime = nil;
   
   if ((blockTime = [CBBlockTime blockTimeWithString:string])) {

      returnValue = YES;
      
      if (object) {
         *object = blockTime;
      }
   
   } else {
   
      if (error) {
         *error = @"Couldn't convert to CBBlockTime";
      }
   }
   
   return returnValue;
}

- (NSString *)stringForObjectValue:(id)object
{
   NSString * objectString = nil;
   
   if ([object isKindOfClass:[CBBlockTime class]]) {
      objectString = [object description];
   }

   return objectString;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr
       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
              originalString:(NSString *)origString
       originalSelectedRange:(NSRange)origSelRange
            errorDescription:(NSString **)error
{

/*   NSLog(@"\n\nCBBlockTimeFormatter isPartialStringValid:...\n\
           partialString: %@\n\
           proposedSelRange: %u, %u\n\
           originalString: %@\n\
           origSelRange: %u, %u\n",\
           *partialStringPtr, proposedSelRangePtr->location, proposedSelRangePtr->length, origString, origSelRange.location, origSelRange.length);
*/

//   BOOL returnValue = NO;
   
   NSString * tempPartialString = nil;
   NSUInteger   tempPartialStringLength = 0;
   NSUInteger   tempProposedSelRangeLocation = 0;
   NSString * insertedString = nil;
   NSUInteger   timeSeparatorLocation = 0;
   NSScanner * scanner = nil;
   NSString * accumulatedDigits = nil;
   NSString * discardedDelimiters = nil;
   
   // empty string is allowed (will be turned into 00:00 in getObjectValue:
   // forString:errorDescription: method)
   if (0 == [*partialStringPtr length]) {
   
      return YES;

   } else {
      
      // deletion
      if (proposedSelRangePtr->location <= origSelRange.location) {
         insertedString = @"";
      
      // either typing (single character) or pasting (perhaps multiple 
      // characters)
      } else {
      
         // check inserted string (either typed or pasted) for illegal
         // characters
         insertedString = [*partialStringPtr substringWithRange:NSMakeRange(origSelRange.location, proposedSelRangePtr->location - origSelRange.location)];

         NSRange illegalCharacterRange = [insertedString rangeOfCharacterFromSet:invertedDecimalDigitPlusTimeSeparatorCharacterSet options:NSLiteralSearch];

         if (illegalCharacterRange.location != NSNotFound) {

            *error = [NSString stringWithFormat:@"\" %@ \" is not allowed in time field", insertedString];
            return NO;

         //  check for more than one time separator (":")
         } else {

            timeSeparatorLocation = [*partialStringPtr rangeOfCharacterFromSet:timeSeparatorCharacterSet options:NSLiteralSearch].location;
            
            if ((timeSeparatorLocation != NSNotFound) &&
                ([*partialStringPtr length] - 1 > timeSeparatorLocation) &&
                ([[*partialStringPtr substringFromIndex:timeSeparatorLocation + 1] rangeOfCharacterFromSet:timeSeparatorCharacterSet options:NSLiteralSearch].location != NSNotFound)) {
            
               *error = @"\" : \" can't be entered more than once";
               return NO;
            }
         }
      }
      
      tempPartialString = @"";
      tempProposedSelRangeLocation = proposedSelRangePtr->location;
      
      scanner = [NSScanner scannerWithString:*partialStringPtr];
      [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
      
      while (![scanner isAtEnd]) {
      
         if ([scanner scanCharactersFromSet:timeSeparatorCharacterSet intoString:&discardedDelimiters]) {
         
            if ([scanner scanLocation] <= proposedSelRangePtr->location) {
            
               tempProposedSelRangeLocation = tempProposedSelRangeLocation - [discardedDelimiters length];

            } else if (([scanner scanLocation] - [discardedDelimiters length]) <= proposedSelRangePtr->location) {
            
               tempProposedSelRangeLocation = tempProposedSelRangeLocation - ([discardedDelimiters length] - ([scanner scanLocation] - proposedSelRangePtr->location));
            }
         }
         
         if  ([scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&accumulatedDigits]) {
         
            tempPartialString = [tempPartialString stringByAppendingString:accumulatedDigits];
         }
      }
      
      tempPartialStringLength = [tempPartialString length];
      if (tempPartialStringLength > 2) {
         
         tempPartialString = [NSString stringWithFormat:@"%@:%@", [tempPartialString substringWithRange:NSMakeRange(0, tempPartialStringLength - 2)], [tempPartialString substringWithRange:NSMakeRange(tempPartialStringLength - 2, 2)]];
         
         if (tempProposedSelRangeLocation > tempPartialStringLength - 2) {
         
            tempProposedSelRangeLocation++;
         }
      }
   }
   
   *partialStringPtr = tempPartialString;
   *proposedSelRangePtr = NSMakeRange(tempProposedSelRangeLocation, 0);
   *error = nil;
   return NO;
}

@end
