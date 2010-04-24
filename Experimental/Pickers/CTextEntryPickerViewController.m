//
//  CTextEntryPickerViewController.m
//  TouchCode
//
//  Created by Jonathan Wight on 04/09/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
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

#import "CTextEntryPickerViewController.h"

@implementation CTextEntryPickerViewController

@synthesize cell;
@synthesize label;
@synthesize field;

- (id)initWithPicker:(CPicker *)inPicker
{
if ((self = [super initWithPicker:inPicker]) != NULL)
	{
	self.initialStyle = UITableViewStyleGrouped;
	
	[self cell];
	}
return(self);
}

- (UITableViewCell *)cell
{
if (cell == NULL)
	{
	UITableViewCell *theCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:NULL] autorelease];
	theCell.textLabel.text = @"Text";
	theCell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	self.label = theCell.textLabel;
	
	[theCell.contentView addSubview:self.field];
	
	cell = [theCell retain];
	}
return(cell);
}

- (UITextField *)field
{
if (field == NULL)
	{
	UITextField *theField = [[[UITextField alloc] initWithFrame:CGRectMake(100, 0, 210, 44)] autorelease];
	theField.tag = 0;
	theField.delegate = self;
	theField.textAlignment = UITextAlignmentLeft;
	theField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	theField.textColor = [UIColor colorWithRed:0.31f green:0.408f blue:0.584f alpha:1.0f];
	theField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	theField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	theField.text = self.picker.value;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChangeNotification:) name:UITextFieldTextDidChangeNotification object:theField];
	
	field = [theField retain];
	}
return(field);
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
return(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : toInterfaceOrientation == UIDeviceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;              // Default is 1 if not implemented
{
return(1);
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
switch (section)
	{
	case 0:
		return(1);
	}
return(0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
UITableViewCell *theCell = NULL;

switch (indexPath.section)
	{
	case 0:
		{
		switch (indexPath.row)
			{
			case 0:
				{
				theCell = self.cell;
				}
				break;
			}
		}
		break;
	}

return(theCell);
}

#pragma mark -

- (void)keyboardWillShowNotification:(NSNotification *)inNotification
{
}

- (void)keyboardDidShowNotification:(NSNotification *)inNotification
{
[UIView beginAnimations:nil context:nil];
[UIView setAnimationDuration:0.3];
[UIView setAnimationBeginsFromCurrentState:YES];

CGRect theViewFrame = self.view.frame;
theViewFrame.size.height -= 150;
self.view.frame = theViewFrame;

[UIView commitAnimations];

//[self.tableView scrollToRowAtIndexPath:self.editedCellIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)keyboardWillHideNotification:(NSNotification *)inNotification
{
[UIView beginAnimations:nil context:nil];
[UIView setAnimationDuration:0.3];
[UIView setAnimationBeginsFromCurrentState:YES];

CGRect theViewFrame = self.view.frame;
theViewFrame.size.height += 150;
self.view.frame = theViewFrame;

[UIView commitAnimations];
}

#pragma mark -

- (void)textFieldTextDidChangeNotification:(NSNotification *)inNotification
{
UITextField *theTextField = inNotification.object;

switch (theTextField.tag)
    {
    case 0:
        self.picker.value = theTextField.text;
        break;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//self.editedCellIndexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
[textField resignFirstResponder];

[self done:NULL];

return(YES);
}

// The password field is not firing this event
- (void)textFieldDidEndEditing:(UITextField *)textField
{
switch (textField.tag)
    {
    case 0:
        self.picker.value = textField.text;
        break;
    }
}


@end
