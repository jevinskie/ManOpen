
#import <AppKit/NSDocument.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextView.h>

@class NSMutableArray, NSMutableDictionary;
@class NSTextField, NSButton, NSPopUpButton;

@interface ManTextView : NSTextView
- (void)scrollRangeToTop:(NSRange)charRange;
@end

@interface ManDocument : NSDocument <NSWindowDelegate>
{
    NSData *taskData;
    BOOL hasLoaded;
    NSURL *copyURL;
    NSMutableArray *sections;
    NSMutableArray *sectionRanges;
    NSMutableDictionary *restoreData;
}

- initWithName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath title:(NSString *)title;

@property (copy) NSString *shortTitle;
@property (unsafe_unretained) IBOutlet ManTextView *textView;
@property (weak) IBOutlet NSTextField    *titleStringField;
@property (weak) IBOutlet NSButton       *openSelectionButton;
@property (weak) IBOutlet NSPopUpButton  *sectionPopup;

- (void)loadCommand:(NSString *)command;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openSelection:(id)sender;
- (IBAction)displaySection:(id)sender;
- (IBAction)copyURL:(id)sender;

@end
