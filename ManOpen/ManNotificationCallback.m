//
//  ManNotificationCallback.m
//  ManOpen
//
//  Created by C.W. Betts on 1/31/15.
//
//

#import "ManNotificationCallback.h"

void tryCatchBlock(dispatch_block_t aTry, void(^catchBlock)(NSException*))
{
	@try {
		aTry();
	}
	@catch (NSException *exception) {
		if (catchBlock) {
			catchBlock(exception);
		}
	}
}
