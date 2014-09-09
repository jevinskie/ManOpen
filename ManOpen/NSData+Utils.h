#import <Foundation/Foundation.h>

@interface NSData (Utils)

@property (nonatomic, getter=isNroffData, readonly) BOOL nroffData;
@property (nonatomic, getter=isRTFData, readonly) BOOL RTFData;
@property (nonatomic, getter=isGzipData, readonly) BOOL gzipData;
@property (nonatomic, getter=isBinaryData, readonly) BOOL binaryData;

@end

@interface NSFileHandle (Utils)

- (NSData *)readDataToEndOfFileIgnoreInterrupt;

@end
