//
//  CFeedFetcher.m
//  TouchRSS_iPhone
//
//  Created by Jonathan Wight on 10/5/08.
//  Copyright 2008 toxicsoftware.com. All rights reserved.
//

#import "CFeedFetcher.h"

#import "CFeedStore.h"
#import "CPersistentObjectManager.h"
#import "CSqliteDatabase.h"
#import "CManagedURLConnection.h"
#import "CRSSFeedDeserializer.h"
#import "CFeed.h"
#import "CFeedEntry.h"
#import "CObjectTranscoder.h"
#import "CURLConnectionManager.h"
#import "CURLConnectionManagerChannel.h"

@interface CFeedFetcher ()
@property (readwrite, nonatomic, assign) CFeedStore *feedStore;
@property (readwrite, nonatomic, assign) NSTimer *fetchTimer;
@property (readwrite, nonatomic, retain) NSMutableSet *currentURLs;
@end

#pragma mark -

@implementation CFeedFetcher

@synthesize feedStore;
@synthesize delegate;
@synthesize fetchInterval;
@synthesize fetchTimer;
@synthesize currentURLs;

- (id)initWithFeedStore:(CFeedStore *)inFeedStore;
{
if ((self = [super init]) != NULL)
	{
	self.feedStore = inFeedStore;
	self.fetchInterval = 2 * 60;
	self.currentURLs = [NSMutableSet set];
	}
return(self);
}

- (void)dealloc
{
[self cancel];

self.feedStore = NULL;
self.delegate = NULL;
self.currentURLs = NULL;
//
[super dealloc];
}

#pragma mark -

- (CRSSFeedDeserializer *)deserializerForData:(NSData *)inData
{
return([[[CRSSFeedDeserializer alloc] initWithData:inData] autorelease]);
}

- (CFeed *)subscribeToURL:(NSURL *)inURL error:(NSError **)outError
{
CFeed *theFeed = [self.feedStore feedforURL:inURL];
if (theFeed)
	return(NULL);

NSError *theError = NULL;
NSString *theExpression = [NSString stringWithFormat:@"INSERT INTO feed (url) VALUES('%@')", [inURL absoluteString]];
BOOL theResult = [self.feedStore.persistentObjectManager.database executeExpression:theExpression error:&theError];
if (theResult == NO)
	{
	if (outError)
		{
		NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithFormat:@"SQL expression '%@' failed", theExpression], NSLocalizedDescriptionKey,
			*outError, NSUnderlyingErrorKey,
			NULL];
		*outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:-1 userInfo:theUserInfo]; 
		}
	return(NULL);
	}

theFeed = [self.feedStore feedforURL:inURL];
if (theFeed == NULL)
	{
	if (outError)
		{
		NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			@"feedforURL failed", NSLocalizedDescriptionKey,
			NULL];
		*outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:-2 userInfo:theUserInfo]; 
		}
	return(NULL);
	}

return(theFeed);
}

- (BOOL)updateFeed:(CFeed *)inFeed
{
return([self updateFeed:inFeed completionTicket:NULL]);
}

- (BOOL)updateFeed:(CFeed *)inFeed completionTicket:(CCompletionTicket *)inCompletionTicket
{
NSDate *theLastChecked = inFeed.lastChecked;
if (theLastChecked != NULL)
	{
	NSDate *theDate = [NSDate date];
	
	NSTimeInterval theInterval = [theDate timeIntervalSinceDate:theLastChecked];
	if (theInterval <= self.fetchInterval)
		return(NO);
	}

NSURL *theURL = inFeed.url;

if ([self.currentURLs containsObject:theURL] == YES)
	{
	NSLog(@"Already fetching %@, ignoring this request to update.", theURL);
	return(NO);
	}

[inCompletionTicket didBeginForTarget:self];

NSURLRequest *theRequest = [[[NSURLRequest alloc] initWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0] autorelease];
CCompletionTicket *theCompletionTicket = [CCompletionTicket completionTicketWithIdentifier:@"Update Feed" delegate:self userInfo:NULL subTicket:inCompletionTicket];

[self.currentURLs addObject:theURL];

CManagedURLConnection *theConnection = [[[CManagedURLConnection alloc] initWithRequest:theRequest completionTicket:theCompletionTicket] autorelease];
[[CURLConnectionManager instance] addAutomaticURLConnection:theConnection toChannel:@"RSS"];

return(YES);
}

- (void)cancel
{
[[[CURLConnectionManager instance] channelForName:@"RSS"] cancelAll:YES];
}

#pragma mark -

- (void)completionTicket:(CCompletionTicket *)inCompletionTicket didCompleteForTarget:(id)inTarget result:(id)inResult
{
CFeed *theFeed = NULL;

[self.feedStore.persistentObjectManager.database begin];

CManagedURLConnection *theConnection = (CManagedURLConnection *)inTarget;
[self.currentURLs removeObject:theConnection.request.URL];
CRSSFeedDeserializer *theDeserializer = [self deserializerForData:theConnection.data];
for (id theDictionary in theDeserializer)
	{
	if (theDeserializer.error != NULL)
		{
		NSLog(@"ERROR: bailing.");
		break;
		}
		
	ERSSFeedDictinaryType theType = [[theDictionary objectForKey:@"type"] intValue];
	switch (theType)
		{
		case FeedDictinaryType_Feed:
			{
			NSURL *theFeedURL = theConnection.request.URL;
			theFeed = [self.feedStore feedforURL:theFeedURL];
			// TODO - in theory this will never be null.
			if (theFeed == NULL)
				{
				NSError *theError = NULL;
				theFeed = [self.feedStore.persistentObjectManager makePersistentObjectOfClass:[[self class] feedClass] error:&theError];
				theFeed.feedStore = self.feedStore;
				}

			NSError *theError = NULL;
			
			CObjectTranscoder *theTranscoder = [[theFeed class] objectTranscoder];
			
			NSDictionary *theUpdateDictonary = [theTranscoder dictionaryForObjectUpdate:theFeed withPropertiesInDictionary:theDictionary error:&theError];
			if (theUpdateDictonary == NULL)
				{
				[NSException raise:NSGenericException format:@"dictionaryForObjectUpdate failed: %@", theError];
				}
			
			if ([[[theFeed class] objectTranscoder] updateObject:theFeed withPropertiesInDictionary:theUpdateDictonary error:&theError] == NO)
				{
				[NSException raise:NSGenericException format:@"Update Object failed: %@", theError];
				}
			
			theFeed.lastChecked = [NSDate date];
			if ([theFeed write:&theError] == NO)
				[NSException raise:NSGenericException format:@"Write failed: %@", theError];
			}
			break;
		case FeedDictinaryType_Entry:
			{
			CFeedEntry *theEntry = [theFeed entryForIdentifier:[theDictionary objectForKey:@"identifier"]];
			if (theEntry == NULL)
				{
				NSError *theError = NULL;
				theEntry = [self.feedStore.persistentObjectManager makePersistentObjectOfClass:[[self.feedStore class] feedEntryClass] error:&theError];
				if (theEntry == NULL && theError != NULL)
					{
					[NSException raise:NSGenericException format:@"makePersistentObjectOfClass failed.: %@", theError];
					}
				theEntry.feed = theFeed;
				}
			
			NSError *theError = NULL;
			CObjectTranscoder *theTranscoder = [[theEntry class] objectTranscoder];
			NSDictionary *theUpdateDictonary = [theTranscoder dictionaryForObjectUpdate:theEntry withPropertiesInDictionary:theDictionary error:&theError];
			if (theUpdateDictonary == NULL)
				{
				[NSException raise:NSGenericException format:@"dictionaryForObjectUpdate failed: %@", theError];
				}
			
			if ([theTranscoder updateObject:theEntry withPropertiesInDictionary:theUpdateDictonary error:&theError] == NO)
				{
				[NSException raise:NSGenericException format:@"Update Object failed: %@", theError];
				}

			[theFeed addEntry:theEntry];

			if ([theEntry write:&theError] == NO)
				[NSException raise:NSGenericException format:@"FeedStore: Entry Write Failed: %@", theError];
			}
			break;
		}
	}

if (theDeserializer.error != NULL)
	{
	NSLog(@"CFeedStore got an error: %@", theDeserializer.error);
	
	[self.feedStore.persistentObjectManager.database rollback];

	if (self.delegate && [self.delegate respondsToSelector:@selector(feedFetcher:didFail:)])
		[self.delegate feedFetcher:self didFailFetchingFeed:theFeed withError:theDeserializer.error];

	if (inCompletionTicket.subTicket)
		[inCompletionTicket.subTicket didFailForTarget:self error:theDeserializer.error];
	}
else
	{
	[self.feedStore.persistentObjectManager.database commit];
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(feedFetcher:didFetchFeed:)])
		[self.delegate feedFetcher:self didFetchFeed:theFeed];
	
	if (inCompletionTicket.subTicket)
		[inCompletionTicket.subTicket didCompleteForTarget:self result:theFeed];
	}
}

- (void)completionTicket:(CCompletionTicket *)inCompletionTicket didFailForTarget:(id)inTarget error:(NSError *)inError
{
NSLog(@"CFeedstore got an error: %@", inError);

CManagedURLConnection *theConnection = (CManagedURLConnection *)inTarget;
[self.currentURLs removeObject:theConnection.request.URL];

if (inCompletionTicket.subTicket)
	[inCompletionTicket.subTicket didFailForTarget:self error:inError];
}


@end
