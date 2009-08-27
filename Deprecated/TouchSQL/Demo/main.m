//
//  main.m
//  TouchCode
//
//  Created by Jonathan Wight on 5/16/09.
//  Copyright 2009 Small Society. All rights reserved.
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


#import "TouchSQL.h"

int main(int argc, char **argv)
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

	CSqliteDatabase *db = [[[CSqliteDatabase alloc] initInMemory] autorelease];
	[db open:NULL];
	
	BOOL result;
	result = [db executeExpression:@"create table foo (name varchar(100))" error:NULL];
	NSLog(@"%d", result);
	
	result = [db executeExpression:@"INSERT INTO foo VALUES ('testname') " error:NULL];
	NSLog(@"%d", result);

	
	NSError *err = NULL;
	NSArray *rows = [db rowsForExpression:@"SELECT * FROM foo WHERE 1" error:&err];
	NSLog(@"%@", err);
	NSLog(@"%@", rows);
	
	NSDictionary *row = [rows objectAtIndex:0];
	NSLog(@"%@", row);


[thePool release];
return(0);
}