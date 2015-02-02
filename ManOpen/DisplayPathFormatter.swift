//
//  DisplayPathFormatter.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa

private let resHome = NSHomeDirectory().stringByResolvingSymlinksInPath + "/"

/* Formatter to abbreviate folders in the user's home directory for a nicer display. */
class DisplayPathFormatter: NSFormatter {

	override func stringForObjectValue(obj: AnyObject) -> String? {
		if let aStr = obj as? String {
			var anew = aStr.stringByAbbreviatingWithTildeInPath;
			
			/* The above method may not work if the home directory is a symlink, and our path is already resolved */
			if (anew as NSString).absolutePath {
				
				if anew.hasPrefix(resHome) {
					anew = "~/" + (anew as NSString).substringFromIndex((resHome as NSString).length)
				}
			}
			
			return anew;
			
		}
		return nil;
	}
	
	override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>, forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
		obj.memory = string.stringByExpandingTildeInPath

		
		return true
	}
}
