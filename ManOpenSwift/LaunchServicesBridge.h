//
//  LaunchServicesBridge.h
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>

#define __private_extern __attribute__((visibility("hidden")))

__private_extern NSString *MODisplayNameForURL(NSURL *theURL);
__private_extern NSArray *MOAllHandlersForURLScheme(NSString *scheme);
__private_extern NSString *MODefaultHandlerForURLScheme(NSString *scheme);
__private_extern OSStatus MOSetDefaultHandlerForURLScheme(NSString *URLScheme, NSString *bundleID);
