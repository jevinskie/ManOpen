//
//  ManNotificationCallback.h
//  ManOpen
//
//  Created by C.W. Betts on 1/31/15.
//
//

#import <Foundation/Foundation.h>

void registerNameWithRootObject(NSString * __nonnull aname, id __nonnull aRootObject);

void tryCatchBlock(dispatch_block_t __nonnull aTry, void(^ __nonnull catchBlock)(NSException* __nonnull));
