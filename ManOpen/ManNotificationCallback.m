//
//  ManNotificationCallback.m
//  ManOpen
//
//  Created by C.W. Betts on 1/31/15.
//
//

#import "ManNotificationCallback.h"

void registerNameWithRootObject(NSString *aname, id aRootObject)
{
	NSConnection *connection = [NSConnection new];
	[connection registerName:aname];
	[connection setRootObject:aRootObject];
}

void tryCatchBlock(dispatch_block_t aTry, void(^catchBlock)(NSException*))
{
	@try {
		aTry();
	}
	@catch (NSException *exception) {
		catchBlock(exception);
	}
}
