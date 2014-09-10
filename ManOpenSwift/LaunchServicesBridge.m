
#import "LaunchServicesBridge.h"

@import Foundation;
@import CoreFoundation;
@import CoreServices;

NSString *MODisplayNameForURL(NSURL *theURL)
{
	CFStringRef tmpStr = NULL;
	LSCopyDisplayNameForURL((__bridge CFURLRef)(theURL), &tmpStr);
	
	return CFBridgingRelease(tmpStr);
}

NSArray *MOAllHandlersForURLScheme(NSString *scheme)
{
	return CFBridgingRelease(LSCopyAllHandlersForURLScheme((__bridge CFStringRef)(scheme)));
}

NSString *MODefaultHandlerForURLScheme(NSString *scheme)
{
	return CFBridgingRelease(LSCopyDefaultHandlerForURLScheme((__bridge CFStringRef)(scheme)));
}

OSStatus MOSetDefaultHandlerForURLScheme(NSString* v1, NSString*v2)
{
	return LSSetDefaultHandlerForURLScheme((__bridge CFStringRef)(v1), (__bridge CFStringRef)(v2));
}
