//
//  ManNotificationCallback.h
//  ManOpen
//
//  Created by C.W. Betts on 1/31/15.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void registerNameWithRootObject(NSString *aname, id aRootObject);

void tryCatchBlock(dispatch_block_t aTry, void(^ __nullable catchBlock)(NSException*));

NS_ASSUME_NONNULL_END
