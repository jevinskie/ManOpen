//
//  ManNotificationCallback.m
//  ManOpen
//
//  Created by C.W. Betts on 1/31/15.
//
//

#import "ManNotificationCallback.h"
#import "ManOpenProtocol.h"
#import "ManOpen-Swift.h"

@interface ManBridgeCallback () <ManOpen>

@end

@implementation ManBridgeCallback
{
	NSConnection *manConnection;
	__weak ManDocumentController* docCont;
}

- (instancetype)initWithManDocumentController:(ManDocumentController*)cont
{
	if (self = [super init]) {
		manConnection = [NSConnection new];
		[manConnection registerName:@"ManOpenApp"];
		[manConnection setRootObject:self];
		docCont = cont;
	}
	return self;
}

- (oneway void)openName:(bycopy NSString *)name section:(bycopy nullable NSString *)section manPath:(bycopy nullable NSString *)manPath forceToFront:(BOOL)force
{
	[docCont openName:name section:section manPath:manPath forceToFront:force];
}

- (oneway void)openApropos:(bycopy NSString *)apropos manPath:(bycopy nullable NSString *)manPath forceToFront:(BOOL)force
{
	[docCont openApropos:apropos manPath:manPath forceToFront:force];
}

- (oneway void)openFile:(bycopy NSString *)filename forceToFront:(BOOL)force
{
	[docCont openFile:filename forceToFront:force];
}

@end

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
