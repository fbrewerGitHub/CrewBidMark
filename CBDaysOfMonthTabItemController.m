//
//  CBDaysOfMonthTabItemController.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/10/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBDataModel.h"


@implementation CBMainWindowController (CBDaysOfMonthTabItemController)

#pragma mark Intialization

- (void)registerDaysOfMonthNotifications
{
    // register for notification that data model days of month select values 
    // changed
    [[NSNotificationCenter defaultCenter]
        addObserver:self 
        selector:@selector(updateDaysOfMonthSelectMatrix:) 
        name:CBDataModelDaysOfMonthSelectValuesChangedNotification 
        object:[self dataModel]];
    // register for notification that data model days of month points values 
    // changed
    [[NSNotificationCenter defaultCenter]
        addObserver:self 
        selector:@selector(updateDaysOfMonthPointsMatrix:) 
        name:CBDataModelDaysOfMonthPointsValuesChangedNotification 
        object:[self dataModel]];
    // register for notification that data model days of week select values 
    // changed
    [[NSNotificationCenter defaultCenter]
        addObserver:self 
        selector:@selector(updateDaysOfWeekSelectMatrix:) 
        name:CBDataModelDaysOfWeekSelectValuesChangedNotification 
        object:[self dataModel]];
    // register for notification that data model days of week points values 
    // changed
    [[NSNotificationCenter defaultCenter]
        addObserver:self 
        selector:@selector(updateDaysOfWeekPointsMatrix:) 
        name:CBDataModelDaysOfWeekPointsValuesChangedNotification 
        object:[self dataModel]];
}

- (void)initializeDaysOfMonthTabItem
{
    // set next responder for days of month select matrix to days of month
    // points matrix
    // this allows text field matrix to respond to clicks
//    [daysOfMonthSelectMatrix setNextResponder:daysOfMonthPointsMatrix];

    NSNumberFormatter *pointsFormatter = [[NSNumberFormatter alloc] init];
    
    if ([pointsFormatter respondsToSelector:@selector(setFormatterBehavior:)])
    {
//        [pointsFormatter setFormatterBehavior:NSNumberFormatterBehavior10_0];
    }
    [pointsFormatter setFormat:@"0.00;0.00;-0.00"];
    
	NSCalendarDate *firstBidDate = [[self dataModel] firstBidDate];
	NSCalendarDate *lastBidDate = [[self dataModel] lastBidDate];
    NSCalendarDate *date = [[self dataModel] firstCalendarDate];
    NSEnumerator *buttonsEnumerator = [[daysOfMonthSelectMatrix cells] objectEnumerator];
    NSEnumerator *textFieldsEnumerator = [[daysOfMonthPointsMatrix cells] objectEnumerator];
    NSButtonCell *buttonCell = nil;
    NSTextFieldCell *textFieldCell = nil;
    while ((buttonCell = [buttonsEnumerator nextObject]) &&
           (textFieldCell = [textFieldsEnumerator nextObject])) {
        [buttonCell setRepresentedObject:date];
        [buttonCell setTitle:[date descriptionWithCalendarFormat:@"%e"]];
        [textFieldCell setRepresentedObject:date];
        [textFieldCell setFormatter:pointsFormatter];
        // disable buttons and text fields for dates before first bid date and
		// after last bid date
        if ([date timeIntervalSinceReferenceDate] < [firstBidDate timeIntervalSinceReferenceDate] || 
		    [date timeIntervalSinceReferenceDate] > [lastBidDate timeIntervalSinceReferenceDate])
		{
            [buttonCell setEnabled:NO];
            [textFieldCell setEnabled:NO];
        }
        date = [date dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
    }
    
    // Initialize days of week select and points matrices (set represented
    // object as NSNumber (0-6) that corresponds to day of week
    buttonsEnumerator = [[daysOfWeekSelectMatrix cells] objectEnumerator];
    textFieldsEnumerator = [[daysOfWeekPointsMatrix cells] objectEnumerator];
    int day = 0;
    while ((buttonCell = [buttonsEnumerator nextObject]) &&
           (textFieldCell = [textFieldsEnumerator nextObject]))
    {
        NSNumber *dayNumber = [NSNumber numberWithInt:day];
        [buttonCell setRepresentedObject:dayNumber];
        [textFieldCell setRepresentedObject:dayNumber];
        [textFieldCell setFormatter:pointsFormatter];
        day++;
    }
    
    [pointsFormatter release];

    // Update days of month select matrix with data model days of month select
    // dates (a set of calendar dates)
    [self updateDaysOfMonthSelectMatrix:nil];
    [self updateDaysOfMonthPointsMatrix:nil];
    [self updateDaysOfWeekSelectMatrix:nil];
    [self updateDaysOfWeekPointsMatrix:nil];
}

#pragma mark Actions

- (IBAction)daysOfMonthSelectMatrixAction:(id)sender
{
    // Set the data model days of month select values (a set of calendar dates)
    // to the set of represented objects (calendar dates) for each selected
    // cell in the matrix
    NSMutableSet *selectedDates = [NSMutableSet set];
    NSEnumerator *cellsEnumerator = [[(NSMatrix *)sender cells] objectEnumerator];
    NSButtonCell *cell = nil;
    while (cell = [cellsEnumerator nextObject]) {
        if (NSOnState == [cell state]) {
            [selectedDates addObject:[cell representedObject]];
        }
    }
    [[self dataModel] setDaysOfMonthSelectValues:selectedDates];
}

- (IBAction)daysOfMonthPointsMatrixAction:(id)sender
{
    // Set the data model days of month points values (a dictionary that 
    // contains all cell float values that are non-zero, each float value
    // having of key of the cell's represented object, a calendar date)
    NSMutableDictionary *nonZeroValues = [NSMutableDictionary dictionary];
    NSEnumerator *cellsEnumerator = [[(NSMatrix *)sender cells] objectEnumerator];
    NSTextFieldCell *cell = nil;
    while (cell = [cellsEnumerator nextObject]) {
        if (0.0 != [cell floatValue]) {
            [nonZeroValues 
                setObject:[NSNumber numberWithFloat:[cell floatValue]] 
                forKey:[cell representedObject]];
        }
    }
    [[self dataModel] setDaysOfMonthPointsValues:nonZeroValues];
}

- (IBAction)daysOfWeekSelectMatrixAction:(id)sender
{
    NSMutableSet *selectedDaysOfWeek = [NSMutableSet set];
    NSEnumerator *cellsEnumerator = [[(NSMatrix *)sender cells] objectEnumerator];
    NSButtonCell *cell = nil;
    while (cell = [cellsEnumerator nextObject])
    {
        if (NSOnState == [cell state])
        {
            [selectedDaysOfWeek addObject:[cell representedObject]];
        }
    }
    [[self dataModel] setDaysOfWeekSelectValues:selectedDaysOfWeek];
}

- (IBAction)daysOfWeekPointsMatrixAction:(id)sender
{
    NSMutableDictionary *nonZeroDaysOfWeek = [NSMutableDictionary dictionary];
    NSEnumerator *cellsEnumerator = [[(NSMatrix *)sender cells] objectEnumerator];
    NSButtonCell *cell = nil;
    while (cell = [cellsEnumerator nextObject])
    {
        if (0.0 != [cell floatValue])
        {
            [nonZeroDaysOfWeek 
                setObject:[NSNumber numberWithFloat:[cell floatValue]] 
                forKey:[cell representedObject]];
        }
    }
    [[self dataModel] setDaysOfWeekPointsValues:nonZeroDaysOfWeek];
}

#pragma mark Interface Updating

- (void)updateDaysOfMonthSelectMatrix:(NSNotification *)notification
{
    // Get selected dates from notification, or if there is no user info for
    // notification, get selected dates directly from data model
    NSDictionary *userInfo = [notification userInfo];
    NSSet *selectedDates = [userInfo objectForKey:CBDataModelDaysOfMonthSelectValuesChangedNotification];
    if (selectedDates == nil) {
        selectedDates = [[self dataModel] daysOfMonthSelectValues];
    }
    // Set cell state to NSOnState if cell's represented object (a calendar
    // date) is in selected dates, or set cell state to NSOffState if it isn't
    NSEnumerator *cellsEnumerator = [[daysOfMonthSelectMatrix cells] objectEnumerator];
    NSButtonCell *cell = nil;
    while (cell = [cellsEnumerator nextObject]) {
        if ([selectedDates containsObject:[cell representedObject]]) {
            [cell setState:NSOnState];
        } else {
            [cell setState:NSOffState];
        }
    }
}

- (void)updateDaysOfMonthPointsMatrix:(NSNotification *)notification
{
    // Get non-zero values from notification, or if there is no user info for
    // notification, get non-zero values directly from data model
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *nonZeroValues = [userInfo objectForKey:CBDataModelDaysOfMonthPointsValuesChangedNotification];
    if (nonZeroValues == nil) {
        nonZeroValues = [[self dataModel] daysOfMonthPointsValues];
    }
    NSSet *nonZeroValueKeys = [NSSet setWithArray:[nonZeroValues allKeys]];
    // Set cell float value to value in non-zero values if cell's represented
    // object (a calendar date) is a key in non-zero values dictionary, or set
    // cell float value to 0.0 if it isn't
    NSEnumerator *cellsEnumerator = [[daysOfMonthPointsMatrix cells] objectEnumerator];
    NSTextFieldCell *cell = nil;
    while (cell = [cellsEnumerator nextObject]) {
        if ([nonZeroValueKeys containsObject:[cell representedObject]]) {
            [cell setObjectValue:[nonZeroValues objectForKey:[cell representedObject]]];
        } else {
            [cell setFloatValue:0.0];
        }
    }
}

- (void)updateDaysOfWeekSelectMatrix:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSSet *selectedDaysOfWeek = [userInfo objectForKey:CBDataModelDaysOfWeekSelectValuesChangedNotification];
    if (!selectedDaysOfWeek)
    {
        selectedDaysOfWeek = [[self dataModel] daysOfWeekSelectValues];
    }
    NSEnumerator *cellsEnumerator = [[daysOfWeekSelectMatrix cells] objectEnumerator];
    NSButtonCell *cell = nil;
    while (cell = [cellsEnumerator nextObject])
    {
        if ([selectedDaysOfWeek containsObject:[cell representedObject]])
        {
            [cell setState:NSOnState];
        }
        else
        {
            [cell setState:NSOffState];
        }
    }
}

- (void)updateDaysOfWeekPointsMatrix:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *nonZeroDaysOfWeek = [userInfo objectForKey:CBDataModelDaysOfWeekPointsValuesChangedNotification];
    if (!nonZeroDaysOfWeek)
    {
        nonZeroDaysOfWeek = [[self dataModel] daysOfWeekPointsValues];
    }
    NSEnumerator *cellsEnumerator = [[daysOfWeekPointsMatrix cells] objectEnumerator];
    NSTextFieldCell *cell = nil;
    while (cell = [cellsEnumerator nextObject])
    {
        if ([nonZeroDaysOfWeek objectForKey:[cell representedObject]])
        {
            [cell setFloatValue:[[nonZeroDaysOfWeek objectForKey:[cell representedObject]] floatValue]];
        }
        else
        {
            [cell setFloatValue:0.0];
        }
    }
}

@end
