//
//  LaunchServicesBridge.h
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

@import Foundation.NSString;
@import Foundation.NSURL;

NSString *MODisplayNameForURL(NSURL *theURL);
NSArray *MOAllHandlersForURLScheme(NSString *scheme);
NSString *MODefaultHandlerForURLScheme(NSString *scheme);
OSStatus MOSetDefaultHandlerForURLScheme(NSString *URLScheme, NSString *bundleID);
