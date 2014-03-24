
#import "ManOpenProtocol.h"
#import <Cocoa/Cocoa.h>

extern NSString *EscapePath(NSString *path, BOOL addSurroundingQuotes);

@interface ManDocumentController : NSDocumentController <ManOpen, NSApplicationDelegate>
@property (unsafe_unretained) IBOutlet NSTextView *helpTextView;
@property (weak) IBOutlet NSPanel *openTextPanel;
@property (weak) IBOutlet NSPanel *aproposPanel;
@property (weak) IBOutlet NSPanel *helpPanel;
@property (weak) IBOutlet NSTextField *aproposField;
@property (weak) IBOutlet NSTextField *openTextField;
@property (weak) IBOutlet NSPopUpButton *openSectionPopup;
@property BOOL startedUp;

- (id)openWord:(NSString *)word;

- (oneway void)openFile:(NSString *)filename;
- (oneway void)openString:(NSString *)string;
- (oneway void)openString:(NSString *)string oneWordOnly:(BOOL)oneOnly;
- (oneway void)openName:(NSString *)name;
- (oneway void)openName:(NSString *)name section:(NSString *)section;
- (oneway void)openName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath;
- (oneway void)openApropos:(NSString *)apropos;
- (oneway void)openApropos:(NSString *)apropos manPath:(NSString *)manPath;

- (IBAction)openSection:(id)sender;
- (IBAction)openTextPanel:(id)sender;
- (IBAction)openAproposPanel:(id)sender;
- (IBAction)okApropos:(id)sender;
- (IBAction)okText:(id)sender;
- (IBAction)cancelText:(id)sender;

- (IBAction)orderFrontHelpPanel:(id)sender;
- (IBAction)orderFrontPreferencesPanel:(id)sender;
- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)display error:(NSError **)outError DEPRECATED_ATTRIBUTE;

// Helper methods for document classes
- (NSMutableString *)manCommandWithManPath:(NSString *)manPath;
- (NSData *)dataByExecutingCommand:(NSString *)command;
- (NSData *)dataByExecutingCommand:(NSString *)command manPath:(NSString *)manPath;

@end
