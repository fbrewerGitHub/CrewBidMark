//
//  CBOvernightCitiesDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on Sat May 29 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"


@implementation CBDataModel ( CBOvernightCitiesDataModel )

- (CBSelectChoice)overnightCitiesSelectMatrixValue { return overnightCitiesSelectMatrixValue; }
- (void)setOvernightCitiesSelectMatrixValue:(CBSelectChoice)inValue
{
   overnightCitiesSelectMatrixValue = inValue;
      if (sortingEnabled) {
         [self selectLinesByOvernightCities];
         [self sortLines];
      }
}

// overnight cities select values are strings that correspond to cities
// either wanted or not wanted
- (NSSet *)overnightCitiesSelectValues { return overnightCitiesSelectValues; }
- (void)setOvernightCitiesSelectValues:(NSSet *)inValue
{
   if (overnightCitiesSelectValues != inValue) {
      overnightCitiesSelectValues = [inValue copy];

      if ([self overnightCitiesSelectMatrixValue] != CBNoSelect) {
         if (sortingEnabled) {
            [self selectLinesByOvernightCities];
            [self sortLines];
         }
      }
   }
}

- (BOOL)overnightCitiesPointsCheckboxValue { return overnightCitiesPointsCheckboxValue; }
- (void)setOvernightCitiesPointsCheckboxValue:(BOOL)inValue
{
   overnightCitiesPointsCheckboxValue = inValue;
   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

// overnight cities points values have key of NSString for a city and object an 
// NSNumber (float value) that corresponds to points for that city
- (NSDictionary *)overnightCitiesPointsValues { return overnightCitiesPointsValues; }
- (void)setOvernightCitiesPointsValues:(NSDictionary *)inValue
{
   if (overnightCitiesPointsValues != inValue) {
      overnightCitiesPointsValues = [inValue copy];

      if ([self overnightCitiesPointsCheckboxValue] == YES) {
         if (sortingEnabled) {
            [self adjustPointsForLines];
         }
      }
   }
}

@end
