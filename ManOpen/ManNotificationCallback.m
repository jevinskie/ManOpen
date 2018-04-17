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
		manConnection = [NSConnection serviceConnectionWithName:@"ManOpenApp" rootObject:self];
		docCont = cont;
	}
	return self;
}

- (oneway void)openName:(bycopy NSString *)name section:(bycopy nullable NSString *)section manPath:(bycopy nullable NSString *)manPath forceToFront:(BOOL)force
{
	if (force) {
		[docCont ensureActive];
	}
	[docCont openDocumentWithName:name section:section manPath:manPath];
}

- (oneway void)openApropos:(bycopy NSString *)apropos manPath:(bycopy nullable NSString *)manPath forceToFront:(BOOL)force
{
	[docCont openApropos:apropos manPath:manPath forceToFront:force];
}

- (oneway void)openFile:(bycopy NSString *)filename forceToFront:(BOOL)force
{
	if (force) {
		[docCont ensureActive];
	}
	[docCont openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES completionHandler:^(NSDocument * _Nullable theDoc, BOOL isNew, NSError * _Nullable error) {
		// do nothing
	}];
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
