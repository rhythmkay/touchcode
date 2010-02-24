    //
//  CSplitTesterViewController.m
//  Menus
//
//  Created by Jonathan Wight on 02/03/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CSplitTesterController.h"

#import "CMainController.h"
#import "CBlankViewController.h"
#import "CMenuItem.h"

@implementation CSplitTesterController

- (void)viewDidLoad
{
[super viewDidLoad];
//
[self setValue:[NSNumber numberWithInt:0] forKey:@"hidesMasterViewInPortrait"];

self.menu = [CMainController instance].menu;


}

- (BOOL)menuHandler:(id <CMenuHandler>)inMenuHandler didSelectMenuItem:(CMenuItem *)inMenuItem;
{
if (inMenuItem.submenu != NULL)
	return(NO);

CBlankViewController *theBlankViewController = [[[CBlankViewController alloc] initWithText:inMenuItem.title] autorelease];
theBlankViewController.title = inMenuItem.title;

[self.detailViewController setViewControllers:[NSArray arrayWithObject:theBlankViewController] animated:NO];

return(YES);
}

@end
