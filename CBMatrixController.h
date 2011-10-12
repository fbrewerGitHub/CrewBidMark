//
//  CBMatrixController.h
//  CrewBid
//
//  Created by Mark Ackerman on Fri May 07 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBMatrixController : NSObject
{
   NSMatrix * matrix;
   NSArray *  data;
}

#pragma mark INITIALIZATION
- (id)initWithMatrix:(NSMatrix *)inMatrix;
- (id)initWithMatrix:(NSMatrix *)inMatrix data:(NSArray *)inData;

#pragma mark INTERFACE MANAGEMENT
- (void)loadEntries:(NSArray *)entries objects:(NSArray *)objects tags:(NSArray *)tags;
- (void)reloadData;

#pragma mark ACCESSORS
- (NSMatrix *)matrix;
- (void)setMatrix:(NSMatrix *)inValue;
- (NSArray *)data;
- (void)setData:(NSArray *)inValue;

@end
