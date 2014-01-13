/* PrefPanelController.h created by lindberg on Fri 08-Oct-1999 */

#import <AppKit/NSWindowController.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSFormatter.h>

@class NSMutableArray;
@class NSFont, NSColor;
@class NSArrayController;
@class NSTableView, NSTextField, NSPopUpButton, NSMatrix;

@interface PrefPanelController : NSWindowController
{
    NSMutableArray *manPathArray;
}
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
- (NSFont *)manFont;
- (NSString *)manPath;
- (NSColor *)manTextColor;
- (NSColor *)manLinkColor;
- (NSColor *)manBackgroundColor;
@end

// This needs to be in the header so IB can find it
@interface DisplayPathFormatter : NSFormatter
@end
