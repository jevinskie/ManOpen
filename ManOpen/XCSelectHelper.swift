import Foundation

func XCManPaths() -> Array<String> {
    if var xc_manpaths: Array<String> = xcselect_helper_get_manpaths() {
        for xcmp in xc_manpaths {
            while xc_manpaths.firstIndex(of: xcmp)! != xc_manpaths.lastIndex(of: xcmp)! {
                xc_manpaths.remove(at: xc_manpaths.lastIndex(of: xcmp)!)
            }
        }
        return xc_manpaths
    } else {
        return []
    }
}
