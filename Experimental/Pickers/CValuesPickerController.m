//
//  CValuesPickerController.m
//  TouchCode
//
//  Created by Jonathan Wight on 05/07/09.
//  Copyright 2009 toxicsoftware.com. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "CValuesPickerController.h"

@interface CValuesPickerController ()
@end

#pragma mark -

@implementation CValuesPickerController

@synthesize selectedValueIndex;
@synthesize values;
@synthesize textLabelKeyPath;
@synthesize textLabelTransformer;
@synthesize imageViewKeyPath;
@synthesize picker;

- (id)init
{
if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:NULL]) != NULL)
	{
	self.selectedValueIndex = NSNotFound;
	self.values = NULL;
	self.textLabelKeyPath = NULL;
	self.textLabelTransformer = NULL;
	self.imageViewKeyPath = NULL;

	}
return(self);
}

- (void)dealloc
{
self.values = NULL;
self.textLabelKeyPath = NULL;
self.textLabelTransformer = NULL;
self.imageViewKeyPath = NULL;
self.picker = NULL;
//
[super dealloc];
}

- (void)viewDidLoad
{
[super viewDidLoad];
//
self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel:)] autorelease];
self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionDone:)] autorelease];
//
self.selectedValueIndex = [self.values indexOfObject:self.picker.value];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
return(self.values.count);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
self.selectedValueIndex = indexPath.row;
self.picker.value = [self.values objectAtIndex:self.selectedValueIndex];
[self.tableView reloadData];
[self performSelector:@selector(unselectRow:) withObject:indexPath afterDelay:0.0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *theCell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
if (theCell == NULL)
	{
	theCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
	}
	
id theValue = [self.values objectAtIndex:indexPath.row];

NSString *theTextLabelValue = theValue;
if (self.textLabelKeyPath)
	theTextLabelValue = [theValue valueForKeyPath:self.textLabelKeyPath];
	
if (self.textLabelTransformer)
	theTextLabelValue = [self.textLabelTransformer transformedValue:theValue];

theCell.textLabel.text = theTextLabelValue;

if (self.imageViewKeyPath)
	{
	theCell.imageView.image = [theValue valueForKeyPath:self.imageViewKeyPath];
	}

 if (indexPath.row == self.selectedValueIndex)
 	{
 	theCell.textLabel.textColor = [UIColor colorWithRed:0.31f green:0.408f blue:0.584f alpha:1.0f];
	theCell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
else
	{
	theCell.textLabel.textColor = [UIColor darkTextColor];
	theCell.accessoryType = UITableViewCellAccessoryNone;
	}
return(theCell);
}

- (void)actionCancel:(id)inSender
{
[self.navigationController popViewControllerAnimated:YES];
}

- (void)actionDone:(id)inSender
{
if (self.selectedValueIndex != NSNotFound)
	{
	}
else
	{
	}

[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

- (void)unselectRow:(NSIndexPath *)inIndexPath
{
[self.tableView deselectRowAtIndexPath:inIndexPath animated:YES];
}

@end
