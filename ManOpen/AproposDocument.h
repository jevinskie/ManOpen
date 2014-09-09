/* AproposDocument.h created by lindberg on Tue 10-Oct-2000 */

#import <Cocoa/Cocoa.h>

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

- (instancetype)initWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (void)parseOutput:(NSString *)output;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openManPages:(id)sender;

@end
