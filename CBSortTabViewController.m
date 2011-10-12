//
//  CBTripTextViewController.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu May 13 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBDocument.h"
#import "CBPopUpButtonController.h"
#import "CBCheckboxController.h"
#import "CBIntegerTextFieldController.h"
#import "CBLine.h"
#import "CBDataModel.h"

@implementation CBMainWindowController ( CBSortTabViewController )

#pragma mark INITIALIZATION

- (void)initializeSortTab
{
   // sort selection table views double-click action
   [[self availableSortSelectionsTableView] setDoubleAction:@selector(moveSortSelections:)];
   [[self inUseSortSelectionsTableView] setDoubleAction:@selector(moveSortSelections:)];
   // register sort selections table views drag types
   NSArray * dragTypes = [NSArray arrayWithObject:CBTableViewDragDropPBoardType];
   [[self availableSortSelectionsTableView] registerForDraggedTypes:dragTypes];
   [[self inUseSortSelectionsTableView] registerForDraggedTypes:dragTypes];
   // FA position table view
   [[self faPositionTableView] registerForDraggedTypes:dragTypes];
   // remove unneeded interface items
   [self initializeSortTabSubviews];
}

- (void)initializeSortTabSubviews
{
   if (![self isFlightAttendantFirstRoundBid])
   {
      [[self faPositionBox] retain];
      [[self faPositionBox] removeFromSuperview];
   }
}

#pragma mark ACTIONS

- (void)moveSortSelections:(id)sender
{
   int clickedRow = [sender clickedRow];
   if (clickedRow > -1) {
      NSMutableArray * available = [NSMutableArray arrayWithArray:[[self dataModel] availableSortSelections]];
      NSMutableArray * inUse = [NSMutableArray arrayWithArray:[[self dataModel] inUseSortSelections]];
      if (sender == [self availableSortSelectionsTableView]) {
         // move available sort selection to in use
         NSDictionary * sortSelection = [available objectAtIndex:clickedRow];
         [available removeObjectAtIndex:clickedRow];
         [inUse addObject:sortSelection];
         [[self dataModel] setAvailableSortSelections:[NSArray arrayWithArray:available]];
         [[self dataModel] setInUseSortSelections:[NSArray arrayWithArray:inUse]];
      } else if (sender == [self inUseSortSelectionsTableView]) {
         // move in use sort selection to available
         NSDictionary * sortSelection = [inUse objectAtIndex:clickedRow];
         [inUse removeObjectAtIndex:clickedRow];
         [available addObject:sortSelection];
         [[self dataModel] setAvailableSortSelections:[NSArray arrayWithArray:available]];
         [[self dataModel] setInUseSortSelections:[NSArray arrayWithArray:inUse]];
      }
      [sender deselectAll:sender];
   }
}

#pragma mark INTERFACE MANAGEMENT

- (void)updateSortSelections:(NSNotification *)notification
{
   [self updateSortTab];
}

- (void)updateFaPositionTableView:(NSNotification *)notification
{
   [self updateFaPositionTableView];
}

- (void)updateSortTab
{
   [[self availableSortSelectionsTableView] reloadData];
   [[self availableSortSelectionsTableView] deselectAll:nil];
   [[self inUseSortSelectionsTableView] reloadData];
   [[self inUseSortSelectionsTableView] deselectAll:nil];
   [self updateFaPositionTableView];
}

- (void)updateFaPositionTableView
{
   [[self faPositionTableView] reloadData];
   [[self faPositionTableView] deselectAll:nil];
}

#pragma mark NOTIFICATIONS

- (void)registerNotificationsForSortTab
{
   NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
   [defaultCenter addObserver:self selector:@selector(updateSortSelections:) name:CBDataModelSortSelectionsChangedNotification object:[self document]];
   [defaultCenter addObserver:self selector:@selector(updateSortSelections:) name:CBDataModelUnarchivedNotification object:[self document]];
   [defaultCenter addObserver:self selector:@selector(updateSortSelections:) name:CBDataModelUnarchivedNotification object:[self document]];
   // FA position table view
   [defaultCenter addObserver:self selector:@selector(updateFaPositionTableView:) name:CBDataModelFaPositionValuesChangedNotification object:[self document]];
   [defaultCenter addObserver:self selector:@selector(updateFaPositionTableView:) name:CBDataModelUnarchivedNotification object:[self document]];
}

#pragma mark ACCESSORS

- (NSTableView *)availableSortSelectionsTableView { return availableSortSelectionsTableView; }

- (NSTableView *)inUseSortSelectionsTableView { return inUseSortSelectionsTableView; }

- (NSTableView *)faPositionTableView { return faPositionTableView; }

- (NSBox *)faPositionBox { return faPositionBox; }

@end
