#import "xcselect-helper.h"


typedef void * xcselect_manpaths;


extern xcselect_manpaths _Nullable xcselect_get_manpaths(char const * _Nullable sdk);
extern uint32_t xcselect_manpaths_get_num_paths(xcselect_manpaths manpaths);
extern const char * _Nullable xcselect_manpaths_get_path(xcselect_manpaths manpaths, uint32_t idx);
extern void xcselect_manpaths_free(xcselect_manpaths manpaths);

NSArray<NSString *> *xcselect_helper_get_manpaths(void) {
    xcselect_manpaths manpaths = xcselect_get_manpaths(NULL);
    if (!manpaths) {
        return nil;
    }
    const uint32_t num_paths = xcselect_manpaths_get_num_paths(manpaths);
    NSMutableArray<NSString *> *res = [NSMutableArray arrayWithCapacity:num_paths];
    for (uint32_t i = 0; i < num_paths; ++i) {
        res[i] = [NSString stringWithUTF8String:xcselect_manpaths_get_path(manpaths, i)];
    }
    xcselect_manpaths_free(manpaths);
    return res;
}
