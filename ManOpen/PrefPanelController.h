/* PrefPanelController.h created by lindberg on Fri 08-Oct-1999 */

#import <Cocoa/Cocoa.h>

@interface PrefPanelController : NSWindowController
@property (strong) NSMutableArray *manPathArray;
@property (weak) IBOutlet NSArrayController *manPathController;
@property (weak) IBOutlet NSTableView *manPathTableView;
@property (weak) IBOutlet NSTextField *fontField;
@property (weak) IBOutlet NSMatrix *generalSwitchMatrix;
@property (weak) IBOutlet NSPopUpButton *appPopup;

+ (id)sharedInstance;
+ (void)registerManDefaults;

- (IBAction)openFontPanel:(id)sender;
- (IBAction)addPathFromPanel:(id)sender;
- (IBAction)chooseNewApp:(id)sender;
@end

@interface NSUserDefaults (ManOpenPreferences)
@property (nonatomic, readonly, copy) NSFont *manFont;
@property (nonatomic, readonly, copy) NSString *manPath;
@property (nonatomic, readonly, copy) NSColor *manTextColor;
@property (nonatomic, readonly, copy) NSColor *manLinkColor;
@property (nonatomic, readonly, copy) NSColor *manBackgroundColor;
@end

// This needs to be in the header so IB can find it
@interface DisplayPathFormatter : NSFormatter
@end
