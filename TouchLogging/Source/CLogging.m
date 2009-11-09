//
//  CLogging.m
//  Touchcode
//
//  Created by Jonathan Wight on 3/24/07.
//  Copyright 2009 Small Society. All rights reserved.
//

#import "CLogging.h"

#import "CCoreDataManager.h"

static CLogging *gInstance = NULL;

@interface CLogging ()
@property (readwrite, retain) CCoreDataManager *coreDataManager;
@property (readwrite, copy) NSManagedObjectID *sessionID;
@property (readwrite, retain) NSMutableDictionary *handlers;
@property (readwrite, assign) BOOL started;

- (void)start;
- (void)end;
@end

#pragma mark -

@implementation CLogging

@synthesize sender;
@synthesize facility;
@dynamic coreDataManager;
@synthesize sessionID;
@synthesize handlers;
@synthesize started;

+ (CLogging *)instance
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

@synchronized(@"CLogging")
	{
	if (gInstance == NULL)
		{
		gInstance = [[CLogging alloc] init];
		}
	}

[thePool release];

return(gInstance);
}

+ (NSString *)stringForLevel:(NSInteger)inLevel;
{
switch (inLevel)
	{
	case LoggingLevel_EMERG:
		return(@"Emergency");
	case LoggingLevel_ALERT:
		return(@"Alert");
	case LoggingLevel_CRIT:
		return(@"Critcial");
	case LoggingLevel_ERR:
		return(@"Error");
	case LoggingLevel_WARNING:
		return(@"Warning");
	case LoggingLevel_NOTICE:
		return(@"Notice");
	case LoggingLevel_INFO:
		return(@"Info");
	case LoggingLevel_DEBUG:
		return(@"Debug");
	default:
		return([NSString stringWithFormat:@"%d", inLevel]);
	}
}

#pragma mark -

- (id)init
{
if ((self = [super init]) != NULL)
	{
	}
return(self);
}

- (void)dealloc
{
[self end];

[sender release];
sender = NULL;
[facility release];
facility = NULL;
[coreDataManager release];
coreDataManager = NULL;
[sessionID release];
sessionID = NULL;
[handlers release];
handlers = NULL;
//
[super dealloc];
}

#pragma mark -

- (NSManagedObject *)session
{
return([self.coreDataManager.managedObjectContext existingObjectWithID:self.sessionID error:NULL]);
}

#pragma mark -

- (CCoreDataManager *)coreDataManager
{
@synchronized(@"CLogging")
	{
	if (coreDataManager == NULL)
		{
		CCoreDataManager *theCoreDataManager = [[[CCoreDataManager alloc] initWithName:@"Logging" forceReplace:NO storeType:NSSQLiteStoreType storeOptions:NULL] autorelease];

		NSManagedObject *theSession = [NSEntityDescription insertNewObjectForEntityForName:@"LoggingSession" inManagedObjectContext:theCoreDataManager.managedObjectContext];
		[theSession setValue:[NSDate date] forKey:@"created"];

		[theCoreDataManager save];

		coreDataManager = [theCoreDataManager retain];
		coreDataManager.delegate = self;
		self.sessionID = theSession.objectID;
		}
	}
return(coreDataManager);
}

- (void)setCoreDataManager:(CCoreDataManager *)aCoreDataManager
{
if (coreDataManager != aCoreDataManager)
	{
	[coreDataManager release];
	coreDataManager = [aCoreDataManager retain];
    }
}

#pragma mark -

- (void)addHandler:(id <CLoggingHandler>)inHandler forEvents:(NSArray *)inEvents;
{
if (self.handlers == NULL)
	self.handlers = [NSMutableDictionary dictionary];

for (NSString *theEvent in inEvents)
	{
	NSMutableArray *theHandlers = [self.handlers objectForKey:theEvent];
	if (theHandlers == NULL)
		{
		theHandlers = [NSMutableArray arrayWithObject:inHandler];
		[self.handlers setObject:theHandlers forKey:theEvent];
		}
	else
		{
		[theHandlers addObject:inHandler];
		}
	}

if (self.started == YES)
	{
	if ([inEvents containsObject:@"start"])
		{
		[inHandler handleLogging:self event:@"start" error:NULL];
		}
	}
}

- (void)removeHandler:(id <CLoggingHandler>)inHandler
{
for (NSMutableArray *theHandlers in [self.handlers allValues])
	{
	if ([theHandlers containsObject:inHandler])
		[theHandlers removeObject:inHandler];
	}
}

- (void)start
{
NSArray *theHandlers = [self.handlers objectForKey:@"start"];
for (id <CLoggingHandler> theHandler in theHandlers)
	{
	[theHandler handleLogging:self event:@"start" error:NULL];
	}
	
self.started = YES;
}

- (void)end
{
NSArray *theHandlers = [self.handlers objectForKey:@"end"];
for (id <CLoggingHandler> theHandler in theHandlers)
	{
	[theHandler handleLogging:self event:@"end" error:NULL];
	}
}

#pragma mark -

- (void)logLevel:(int)inLevel format:(NSString *)inFormat, ...
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

va_list theArgList;
va_start(theArgList, inFormat);
NSString *theMessage = [[[NSString alloc] initWithFormat:inFormat arguments:theArgList] autorelease];
va_end(theArgList);

SFileFunctionLine theFileFunctionLine = { 0, NULL };
[self logLevel:inLevel fileFunctionLine:theFileFunctionLine dictionary:NULL format:@"%@", theMessage];

[thePool release];
}

- (void)logLevel:(int)inLevel dictionary:(NSDictionary *)inDictionary format:(NSString *)inFormat, ...;
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

va_list theArgList;
va_start(theArgList, inFormat);
NSString *theMessage = [[[NSString alloc] initWithFormat:inFormat arguments:theArgList] autorelease];
va_end(theArgList);

SFileFunctionLine theFileFunctionLine = { 0, NULL };
[self logLevel:inLevel fileFunctionLine:theFileFunctionLine dictionary:inDictionary format:@"%@", theMessage];

[thePool release];
}

- (void)logLevel:(int)inLevel fileFunctionLine:(SFileFunctionLine)inFileFunctionLine dictionary:(NSDictionary *)inDictionary format:(NSString *)inFormat, ...;
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

if (self.started == NO)
	[self start];

va_list theArgList;
va_start(theArgList, inFormat);
NSString *theMessageString = [[[NSString alloc] initWithFormat:inFormat arguments:theArgList] autorelease];
va_end(theArgList);

char *theLevelString = NULL;
switch (inLevel)
	{
	case LoggingLevel_EMERG:
		theLevelString = "EMERG: ";
		break;
	case LoggingLevel_ALERT:
		theLevelString = "ALERT: ";
		break;
	case LoggingLevel_CRIT:
		theLevelString = "CRIT:  ";
		break;
	case LoggingLevel_ERR:
		theLevelString = "ERROR: ";
		break;
	case LoggingLevel_WARNING:
		theLevelString = "WARN:  ";
		break;
	case LoggingLevel_NOTICE:
		theLevelString = "NOTICE:";
		break;
	case LoggingLevel_INFO:
		theLevelString = "INFO:  ";
		break;
	case LoggingLevel_DEBUG:
		theLevelString = "DEBUG: ";
		break;
	}


fprintf(stderr, "%s %s\n", theLevelString, [theMessageString UTF8String]);

NSManagedObject *theMessage = [NSEntityDescription insertNewObjectForEntityForName:@"LoggingMessage" inManagedObjectContext:self.coreDataManager.managedObjectContext];

NSError *theError = NULL;
NSManagedObject *theSession = [self.coreDataManager.managedObjectContext existingObjectWithID:self.sessionID error:&theError];
NSAssert1(theSession != NULL, @"No session found (%@)", theError);

[theMessage setValue:[NSNumber numberWithInteger:inLevel] forKey:@"level"];
[theMessage setValue:theMessageString forKey:@"message"];
[theMessage setValue:[NSDate date] forKey:@"timestamp"];
[theMessage setValue:self.sender forKey:@"sender"];
[theMessage setValue:self.facility forKey:@"facility"];
[theMessage setValue:theSession forKey:@"session"];

if (inDictionary)
	{
	NSData *theAttributesData = [NSPropertyListSerialization dataFromPropertyList:inDictionary format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
	[theMessage setValue:theAttributesData forKey:@"extraAttributes"];
	}

[self.coreDataManager save];

NSArray *theHandlers = [self.handlers objectForKey:@"log"];
for (id <CLoggingHandler> theHandler in theHandlers)
	{
	[theHandler handleLogging:self event:@"log" error:NULL];
	}


[thePool release];
}

#pragma mark -

- (void)logError:(NSError *)inError
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

NSDictionary *theUserInfo = [inError userInfo];

int theLevel = LoggingLevel_ERR;
NSNumber *theLevelValue = [theUserInfo objectForKey:@"level"];
if (theLevelValue != NULL)
	theLevel = [theLevelValue intValue];

NSMutableDictionary *theDictionary = [NSMutableDictionary dictionaryWithDictionary:theUserInfo];
[theDictionary setObject:[inError domain] forKey:@"domain"];
[theDictionary setObject:[NSNumber numberWithInteger:[inError code]] forKey:@"code"];
if ([inError localizedDescription] != NULL)
	[theDictionary setObject:[inError localizedDescription] forKey:@"localizedDescription"];
if ([inError localizedFailureReason] != NULL)
	[theDictionary setObject:[inError localizedFailureReason] forKey:@"localizedFailureReason"];
if ([inError localizedRecoverySuggestion] != NULL)
	[theDictionary setObject:[inError localizedRecoverySuggestion] forKey:@"localizedRecoverySuggestion"];

[self logLevel:theLevel dictionary:theDictionary format:@"%@", [inError localizedDescription]];

[thePool release];
}

- (void)logException:(NSException *)inException
{
NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];

if ([inException.userInfo objectForKey:@"error"] != NULL)
	[self logError:[inException.userInfo objectForKey:@"error"]];
else
	{
	NSDictionary *theUserInfo = [inException userInfo];

	NSMutableDictionary *theDictionary = [NSMutableDictionary dictionaryWithDictionary:theUserInfo];
	[theDictionary setObject:[inException name] forKey:@"name"];
	[theDictionary setObject:[inException reason] forKey:@"reason"];

	int theLevel = LoggingLevel_ERR;
	NSNumber *theLevelValue = [theUserInfo objectForKey:@"level"];
	if (theLevelValue != NULL)
		theLevel = [theLevelValue intValue];

	[self logLevel:theLevel dictionary:theDictionary format:@"%@", [inException reason]];
	}

[thePool release];
}

#pragma mark -

- (void)coreDataManager:(CCoreDataManager *)inCoreDataManager didCreateNewManagedObjectContext:(NSManagedObjectContext *)inManagedObjectContext;
{
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:inManagedObjectContext];
}

- (void)managedObjectContextDidSaveNotification:(NSNotification *)notification
{
if ([NSThread mainThread] != [NSThread currentThread])
	{
	[self performSelectorOnMainThread:@selector(managedObjectContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
	return;
	}

[self.coreDataManager.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
[self.coreDataManager save];
}

@end

#pragma mark -

@implementation NSError (NSError_LogExtensions)

- (void)log
{
#if LOGGING == 1
[[CLogging instance] logError:self];
#endif /* LOGGING == 1 */
}

@end

#pragma mark -

@implementation NSException (NSException_LogExtensions)

- (void)log
{
#if LOGGING == 1
[[CLogging instance] logException:self];
#endif /* LOGGING == 1 */
}

@end
