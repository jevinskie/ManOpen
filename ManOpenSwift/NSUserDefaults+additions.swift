//
//  NSUserDefaults+additions.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa

private func ColorForKey(key: String, defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) -> NSColor? {
	let colorData = defaults.dataForKey(key)
	
	if (colorData == nil) {
		return nil;
	}
	
	return NSUnarchiver.unarchiveObjectWithData(colorData!) as NSColor?
}

extension NSUserDefaults {
	
	var textColor: NSColor {
		get {
			return ColorForKey(manTextColor, defaults: self)!
		}
	}
	
	var linkColor: NSColor {
		get {
			return ColorForKey(manLinkColor, defaults: self)!
		}
	}
	
	var backgroundColor: NSColor {
		get {
			return ColorForKey(manBackgroundColor, defaults: self)!
		}
	}
	
	var path: String {
		get {
			return self.stringForKey(manPath)!
		}
	}
	
	var font: NSFont {
		get {
			let fontString = self.stringForKey(manFont);
			
			if fontString != nil {
				let spaceRange = fontString!.rangeOfString(" ")
				if spaceRange != nil {
					func getEndIdx(string: String) -> String.Index {
						var endIdx = string.endIndex
						return --endIdx
					}
					let size = CGFloat((fontString![fontString!.startIndex..<spaceRange!.startIndex] as NSString).floatValue)
					let endIdx = getEndIdx(fontString!)
					var name = fontString![spaceRange!.endIndex..<endIdx]
					let font = NSFont(name: name, size: size) as NSFont?
					if font != nil {
						return font!
					}
				}
			}
			return NSFont.userFixedPitchFontOfSize(12.0) // Monaco, or Menlo
		}
	}
}
