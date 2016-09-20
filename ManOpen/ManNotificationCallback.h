//
//  ManNotificationCallback.h
//  ManOpen
//
//  Created by C.W. Betts on 1/31/15.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void registerNameWithRootObject(NSString *aname, id aRootObject) NS_SWIFT_NAME(register(name:rootObject:));

void tryCatchBlock(NS_NOESCAPE dispatch_block_t aTry, void(NS_NOESCAPE^ __nullable catchBlock)(NSException*)) NS_SWIFT_NAME(exceptionBlock(try:catch:));

NS_ASSUME_NONNULL_END
