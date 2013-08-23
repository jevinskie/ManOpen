
#import <Foundation/NSData.h>
#import <Foundation/NSFileHandle.h>

@interface NSData (Utils)

- (BOOL)isNroffData;
- (BOOL)isRTFData;
- (BOOL)isGzipData;
- (BOOL)isBinaryData;

@end

@interface NSFileHandle (Utils)

- (NSData *)readDataToEndOfFileIgnoreInterrupt;

@end

