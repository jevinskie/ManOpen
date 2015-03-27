
/*
 * Protocol for the 'openman' command line util to communicate with us
 * through
 */

#import <Foundation/Foundation.h>

@protocol ManOpen <NSObject>

- (oneway void)openName:(nonnull NSString *)name section:(nullable NSString *)section manPath:(nullable NSString *)manPath forceToFront:(BOOL)force;
- (oneway void)openApropos:(nonnull NSString *)apropos manPath:(nullable NSString *)manPath forceToFront:(BOOL)force;
- (oneway void)openFile:(nonnull NSString *)filename forceToFront:(BOOL)force;

@end
