//
//  CBDeadheadsTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/9/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"


@implementation CBDataModel ( CBDeadheadsTabDataModel )

- (BOOL)deadheadAtStartSelectCheckboxValue {
    return deadheadAtStartSelectCheckboxValue;
}

- (void)setDeadheadAtStartSelectCheckboxValue:(BOOL)value {
    if (deadheadAtStartSelectCheckboxValue != value) {
        deadheadAtStartSelectCheckboxValue = value;
        
        if (sortingEnabled) {
            [self selectLinesByDeadheadAtStart];
            [self sortLines];
        }
    }
}

- (NSArray *)deadheadAtStartCities {
    return deadheadAtStartCities;
}

- (void)setDeadheadAtStartCities:(NSArray *)value {
    if (deadheadAtStartCities != value) {
        [deadheadAtStartCities release];
        deadheadAtStartCities = [value copy];
    }
}

- (NSString *)deadheadAtStartCity {
    return deadheadAtStartCity;
}

- (void)setDeadheadAtStartCity:(NSString *)value {
    if (deadheadAtStartCity != value) {
        [deadheadAtStartCity release];
        deadheadAtStartCity = [value copy];

        if (sortingEnabled) {
            [self selectLinesByDeadheadAtStart];
            if (deadheadAtStartPointsCheckboxValue) {
                [self adjustPointsForLines];
            } else {
                [self sortLines];
            }
        }
    }
}

- (BOOL)deadheadAtStartPointsCheckboxValue {
    return deadheadAtStartPointsCheckboxValue;
}

- (void)setDeadheadAtStartPointsCheckboxValue:(BOOL)value {
    if (deadheadAtStartPointsCheckboxValue != value) {
        deadheadAtStartPointsCheckboxValue = value;

        if (sortingEnabled) {
            [self adjustPointsForLines];
        }
    }
}

- (float)deadheadAtStartPointsValue {
    return deadheadAtStartPointsValue;
}

- (void)setDeadheadAtStartPointsValue:(float)value {
    if (deadheadAtStartPointsValue != value) {
        deadheadAtStartPointsValue = value;

        if (sortingEnabled && deadheadAtStartPointsCheckboxValue) {
            [self adjustPointsForLines];
        }
    }
}

- (BOOL)deadheadAtEndSelectCheckboxValue {
    return deadheadAtEndSelectCheckboxValue;
}

- (void)setDeadheadAtEndSelectCheckboxValue:(BOOL)value {
    if (deadheadAtEndSelectCheckboxValue != value) {
        deadheadAtEndSelectCheckboxValue = value;

        if (sortingEnabled) {
            [self selectLinesByDeadheadAtEnd];
            [self sortLines];
        }
    }
}

- (NSArray *)deadheadAtEndCities {
    return deadheadAtEndCities;
}

- (void)setDeadheadAtEndCities:(NSArray *)value {
    if (deadheadAtEndCities != value) {
        [deadheadAtEndCities release];
        deadheadAtEndCities = [value copy];
    }
}

- (NSString *)deadheadAtEndCity {
    return deadheadAtEndCity;
}

- (void)setDeadheadAtEndCity:(NSString *)value {
    if (deadheadAtEndCity != value) {
        [deadheadAtEndCity release];
        deadheadAtEndCity = [value copy];

        if (sortingEnabled) {
            [self selectLinesByDeadheadAtEnd];
            if (deadheadAtEndPointsCheckboxValue) {
                [self adjustPointsForLines];
            } else {
                [self sortLines];
            }
        }
    }
}

- (BOOL)deadheadAtEndPointsCheckboxValue {
    return deadheadAtEndPointsCheckboxValue;
}

- (void)setDeadheadAtEndPointsCheckboxValue:(BOOL)value {
    if (deadheadAtEndPointsCheckboxValue != value) {
        deadheadAtEndPointsCheckboxValue = value;

        if (sortingEnabled) {
            [self adjustPointsForLines];
        }
    }
}

- (float)deadheadAtEndPointsValue {
    return deadheadAtEndPointsValue;
}

- (void)setDeadheadAtEndPointsValue:(float)value {
    if (deadheadAtEndPointsValue != value) {
        deadheadAtEndPointsValue = value;

        if (sortingEnabled) {
            [self adjustPointsForLines];
        }
    }
}

@end
