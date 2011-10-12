//
//  CBMatrixController.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri May 07 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMatrixController.h"


@implementation CBMatrixController

#pragma mark INITIALIZATION

- (id)initWithMatrix:(NSMatrix *)inMatrix
{
   if (self = [super init]) {
      [self setMatrix:inMatrix];
   }
   return self;
}

- (id)initWithMatrix:(NSMatrix *)inMatrix data:(NSArray *)inData
{
   if (self = [super init]) {
      [self setMatrix:inMatrix];
      [self setData:inData];
   }
   return self;
}

#pragma mark INTERFACE MANAGEMENT

- (void)loadEntries:(NSArray *)entries objects:(NSArray *)objects tags:(NSArray *)tags
{
   // set object value for each cell to data
   NSEnumerator * entriesEnumerator = [entries objectEnumerator];
   NSEnumerator * objectsEnumerator = nil;
   NSEnumerator * tagsEnumerator = nil;
   if (objects) {
      objectsEnumerator = [objects objectEnumerator];
   }
   if (tags) {
      tagsEnumerator = [tags objectEnumerator];
   }
   NSEnumerator * cellsEnumerator = [[matrix cells] objectEnumerator];
   id entry = nil;
   id object = nil;
   id tag = nil;
   NSCell * cell = nil;
   while (cell = [cellsEnumerator nextObject]) {
      if (entry = [entriesEnumerator nextObject]) {
         [cell setObjectValue:entry];
      }
      if (objectsEnumerator && (object = [objectsEnumerator nextObject])) {
         [cell setRepresentedObject:object];
      }
      if (tagsEnumerator && (tag = [tagsEnumerator nextObject])) {
         [cell setTag:[tag intValue]];
      }
   }
}

- (void)reloadData
{
   // set object value for each cell to data
   NSEnumerator * dataEnumerator = [[self data] objectEnumerator];
   NSEnumerator * cellsEnumerator = [[matrix cells] objectEnumerator];
   id dataObject = nil;
   NSCell * cell = nil;
   while ((dataObject = [dataEnumerator nextObject]) && (cell = [cellsEnumerator nextObject])) {
      [cell setObjectValue:dataObject];
   }
}

#pragma mark ACCESSORS

- (NSMatrix *)matrix { return matrix; }
- (void)setMatrix:(NSMatrix *)inValue { matrix = inValue; }

- (NSArray *)data {return data; }
- (void)setData:(NSArray *)inValue
{
   if (data != inValue) {
      [data release];
      data = [inValue copy];
      [self reloadData];
   }
}

@end
