//
//  CBMaxLegsPerDayTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on 12/14/07.
//  Copyright 2007 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"


@implementation CBDataModel ( CBMaxLegsPerDayTabDataModel )

#pragma mark ACCESSORS

- (BOOL)maxLegsPerDaySelectCheckboxValue {
    return maxLegsPerDaySelectCheckboxValue;
}

- (void)setMaxLegsPerDaySelectCheckboxValue:(BOOL)value {
    if (maxLegsPerDaySelectCheckboxValue != value) {
        maxLegsPerDaySelectCheckboxValue = value;

		if (sortingEnabled) {
			[self selectLinesByMaxLegsPerDay];
			[self sortLines];
		}
    }
}

- (int)maxLegsPerDaySelectTriggerValue {
    return maxLegsPerDaySelectTriggerValue;
}

- (void)setMaxLegsPerDaySelectTriggerValue:(int)value {
    if (maxLegsPerDaySelectTriggerValue != value) {
        maxLegsPerDaySelectTriggerValue = value;

		if (maxLegsPerDaySelectCheckboxValue && sortingEnabled) {
			[self selectLinesByMaxLegsPerDay];
			[self sortLines];
		}
    }
}

- (BOOL)maxLegsPerDayLessThanOrEqualPointsCheckboxValue {
    return maxLegsPerDayLessThanOrEqualPointsCheckboxValue;
}

- (void)setMaxLegsPerDayLessThanOrEqualPointsCheckboxValue:(BOOL)value {
    if (maxLegsPerDayLessThanOrEqualPointsCheckboxValue != value) {
        maxLegsPerDayLessThanOrEqualPointsCheckboxValue = value;
		
		if (sortingEnabled) {
			[self adjustPointsForLines];
		}
    }
}

- (int)maxLegsPerDayLessThanOrEqualPointsTriggerValue {
    return maxLegsPerDayLessThanOrEqualPointsTriggerValue;
}

- (void)setMaxLegsPerDayLessThanOrEqualPointsTriggerValue:(int)value {
    if (maxLegsPerDayLessThanOrEqualPointsTriggerValue != value) {
        maxLegsPerDayLessThanOrEqualPointsTriggerValue = value;

		if (maxLegsPerDayLessThanOrEqualPointsCheckboxValue && sortingEnabled) {
			[self adjustPointsForLines];
		}
    }
}

- (float)maxLegsPerDayLessThanOrEqualPointsValue {
    return maxLegsPerDayLessThanOrEqualPointsValue;
}

- (void)setMaxLegsPerDayLessThanOrEqualPointsValue:(float)value {
    if (maxLegsPerDayLessThanOrEqualPointsValue != value) {
        maxLegsPerDayLessThanOrEqualPointsValue = value;

		if (maxLegsPerDayLessThanOrEqualPointsCheckboxValue && sortingEnabled) {
			[self adjustPointsForLines];
		}
    }
}

- (BOOL)maxLegsPerDayGreaterThanPointsCheckboxValue {
    return maxLegsPerDayGreaterThanPointsCheckboxValue;
}

- (void)setMaxLegsPerDayGreaterThanPointsCheckboxValue:(BOOL)value {
    if (maxLegsPerDayGreaterThanPointsCheckboxValue != value) {
        maxLegsPerDayGreaterThanPointsCheckboxValue = value;
		
		if (sortingEnabled) {
			[self adjustPointsForLines];
		}
    }
}

- (int)maxLegsPerDayGreaterThanPointsTriggerValue {
    return maxLegsPerDayGreaterThanPointsTriggerValue;
}

- (void)setMaxLegsPerDayGreaterThanPointsTriggerValue:(int)value {
    if (maxLegsPerDayGreaterThanPointsTriggerValue != value) {
        maxLegsPerDayGreaterThanPointsTriggerValue = value;

		if (sortingEnabled) {
			[self adjustPointsForLines];
		}
    }
}

- (float)maxLegsPerDayGreaterThanPointsValue {
    return maxLegsPerDayGreaterThanPointsValue;
}

- (void)setMaxLegsPerDayGreaterThanPointsValue:(float)value {
    if (maxLegsPerDayGreaterThanPointsValue != value) {
        maxLegsPerDayGreaterThanPointsValue = value;
		
		if (maxLegsPerDayGreaterThanPointsCheckboxValue && sortingEnabled) {
			[self adjustPointsForLines];
		}
    }
}

@end
