    //
//  CTabBarMenuViewController.m
//  TouchCode
//
//  Created by Jonathan Wight on 02/25/10.
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

#import "CTabBarMenuViewController.h"

#import "CMenu.h"
#import "CMenuItem.h"

@implementation CTabBarMenuViewController

@synthesize menu;
@synthesize menuHandlerDelegate;

- (id)initWithMenu:(CMenu *)inMenu
{
if ((self = [super initWithNibName:NULL bundle:NULL]))
	{
	menu = [inMenu retain];
    }
return(self);
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


- (void)loadView
{
[super loadView];

NSMutableArray *theViewControllers = [NSMutableArray array];
for (CMenuItem *theMenuItem in self.menu.items)
	{
	CMenu *theSubmenu = theMenuItem.submenu;
	
	UIViewController <CMenuHandler> *theViewController = [[[theSubmenu.controller alloc] initWithMenu:theMenuItem.submenu] autorelease];
	theViewController.title = theSubmenu.title;
	[theViewControllers addObject:theViewController];
	}
self.viewControllers = theViewControllers;

}


@end
