#import <Foundation/Foundation.h>

@interface NSData (Utils)

@property (getter=isNroffData, readonly) BOOL nroffData;
@property (getter=isRTFData, readonly) BOOL RTFData;
@property (getter=isGzipData, readonly) BOOL gzipData;
@property (getter=isBinaryData, readonly) BOOL binaryData;

@end

@interface NSFileHandle (Utils)

- (nonnull NSData *)readDataToEndOfFileIgnoreInterrupt;

@end
