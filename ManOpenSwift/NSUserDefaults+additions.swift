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
let manFontKey		= "ManFont"
let manPathKey		= "ManPath"
let manBackgroundColorKey = "ManBackgroundColor"

private func ColorForKey(key: String, defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) -> NSColor? {
	if let colorData = defaults.dataForKey(key) {
		return NSUnarchiver.unarchiveObjectWithData(colorData) as NSColor?
	}
	
	return nil
}

internal func dataForColor(color: NSColor) -> NSData {
	return NSArchiver.archivedDataWithRootObject(color)
}

extension NSUserDefaults {
	
	var manTextColor: NSColor {
		get {
			return ColorForKey(manTextColorKey, defaults: self)!
		}
		set {
			self.setObject(dataForColor(newValue), forKey: manTextColorKey)
		}
	}
	
	var manLinkColor: NSColor {
		get {
			return ColorForKey(manLinkColorKey, defaults: self)!
		}
		set {
			self.setObject(dataForColor(newValue), forKey: manLinkColorKey)
		}
	}
	
	var manBackgroundColor: NSColor {
		get {
			return ColorForKey(manBackgroundColorKey, defaults: self)!
		}
		set {
			self.setObject(dataForColor(newValue), forKey: manBackgroundColorKey)
		}
	}
	
	var manPath: String {
		get {
			return self.stringForKey(manPathKey)!
		}
		set {
			self.setValue(newValue, forKey: manPathKey)
		}
	}
	
	var manFont: NSFont {
		if let fontString = self.stringForKey(manFontKey) {
			if let spaceRange = fontString.rangeOfString(" ") {
				func getEndIdx(string: String) -> String.Index {
					var endIdx = string.endIndex
					return --endIdx
				}
				let size = CGFloat((fontString[fontString.startIndex..<spaceRange.startIndex] as NSString).floatValue)
				let endIdx = getEndIdx(fontString)
				var name = fontString[spaceRange.endIndex..<endIdx]
				let font = NSFont(name: name, size: size)
				if font != nil {
					return font!
				}
			}
		}
		
		return NSFont.userFixedPitchFontOfSize(12.0)! // Monaco, or Menlo
	}
}
