
/*
 * Protocol for the 'openman' command line util to communicate with us
 * through
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ManOpen <NSObject>

- (oneway void)openName:(NSString *)name section:(nullable NSString *)section manPath:(nullable NSString *)manPath forceToFront:(BOOL)force;
- (oneway void)openApropos:(NSString *)apropos manPath:(nullable NSString *)manPath forceToFront:(BOOL)force;
- (oneway void)openFile:(NSString *)filename forceToFront:(BOOL)force;

@end

NS_ASSUME_NONNULL_END
