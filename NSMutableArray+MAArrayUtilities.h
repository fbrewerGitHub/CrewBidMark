//
//  NSMutableArray+MAArrayUtilities.h
//  CrewBid
//
//  Created by Mark on 5/15/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNull.h>

@interface NSMutableArray (MAArrayUtilities)

- (void)moveObjectAtIndex:(unsigned)oldIndex toIndex:(unsigned)newIndex;
- (void)moveObjectsAtIndexes:(NSArray *)oldIndexes toIndexes:(NSArray *)newIndexes;

@end
