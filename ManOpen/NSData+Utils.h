#import <Foundation/Foundation.h>

@interface NSData (Utils)

@property (getter=isNroffData, readonly) BOOL nroffData;
@property (getter=isRTFData, readonly) BOOL RTFData;
@property (getter=isGzipData, readonly) BOOL gzipData;
@property (getter=isBinaryData, readonly) BOOL binaryData;

@end

@interface NSFileHandle (Utils)

/*!
 * The <code>NSData -readDataToEndOfFile</code> method does not deal with \c EINTR errors, which in most
 * cases is fine, but sometimes not when running under a debugger.  So... this is more to help
 * folks working on the code, rather the users ;-)
 */
- (nullable NSData *)readDataToEndOfFileIgnoreInterruptAndReturnError:(NSError * __nullable * __null_unspecified)error;

@end
