/* AproposDocument.h created by lindberg on Tue 10-Oct-2000 */

#import <AppKit/NSDocument.h>

@class NSMutableArray;
@class NSTableColumn, NSTableView;

@interface AproposDocument : NSDocument
{
    NSString *title;
    NSString *searchString;
    NSMutableArray *titles;
    NSMutableArray *descriptions;
}
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTableColumn *titleColumn;
@property (copy) NSString *title;

- (id)initWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)title;
- (void)parseOutput:(NSString *)output;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openManPages:(id)sender;

@end
