
/*
 * Protocol for the 'openman' command line util to communicate with us
 * through
 */

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSObject.h>
@class NSString;

@protocol ManOpen <NSObject>

- (oneway void)openName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath forceToFront:(BOOL)force;
- (oneway void)openApropos:(NSString *)apropos manPath:(NSString *)manPath forceToFront:(BOOL)force;
- (oneway void)openFile:(NSString *)filename forceToFront:(BOOL)force;

@end
