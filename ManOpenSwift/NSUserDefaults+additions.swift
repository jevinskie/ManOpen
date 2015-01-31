//
//  NSUserDefaults+additions.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa

let manTextColorKey = "ManTextColor"
let manLinkColorKey = "ManLinkColor"
let manBackgroundColorKey = "ManBackgroundColor"
let manFontKey = "ManFont"
let manPathKey = "ManPath"

private func ColorForKey(key: String, defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) -> NSColor? {
	if let colorData = defaults.dataForKey(key) {
		return NSUnarchiver.unarchiveObjectWithData(colorData) as NSColor?
	}
	
	return nil
}

extension NSUserDefaults {
	
	var manTextColor: NSColor {
		return ColorForKey(manTextColorKey, defaults: self)!
	}
	
	var manLinkColor: NSColor {
		return ColorForKey(manLinkColorKey, defaults: self)!
	}
	
	var manBackgroundColor: NSColor {
		return ColorForKey(manBackgroundColorKey, defaults: self)!
	}
	
	var manPath: String {
		return self.stringForKey(manPathKey)!
	}
	
	var manFont: NSFont {
		get {
			let fontString = self.stringForKey(manFontKey);
			
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
			
			return NSFont.userFixedPitchFontOfSize(12.0)! // Monaco, or Menlo
		}
	}
}
