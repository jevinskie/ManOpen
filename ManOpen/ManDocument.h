
#import "SystemType.h"
#import <AppKit/NSDocument.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextView.h>

@class NSMutableArray, NSMutableDictionary;
@class NSTextField, NSText, NSButton, NSPopUpButton;

@interface ManTextView : NSTextView
- (void)scrollRangeToTop:(NSRange)charRange;
@end

@interface ManDocument : NSDocument <NSWindowDelegate>
{
    NSString *shortTitle;
    NSData *taskData;
    BOOL hasLoaded;
    NSURL *copyURL;
    NSMutableArray *sections;
    NSMutableArray *sectionRanges;
    NSMutableDictionary *restoreData;

    IBOutlet ManTextView *textView;
    IBOutlet NSTextField *titleStringField;
    IBOutlet NSButton    *openSelectionButton;
    IBOutlet NSPopUpButton *sectionPopup;
}

- initWithName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath title:(NSString *)title;

- (NSString *)shortTitle;
- (void)setShortTitle:(NSString *)aString;

- (NSText *)textView;

- (void)loadCommand:(NSString *)command;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openSelection:(id)sender;
- (IBAction)displaySection:(id)sender;
- (IBAction)copyURL:(id)sender;

@end
