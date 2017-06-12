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

private func color(for key: String, defaults: UserDefaults = UserDefaults.standard) -> NSColor? {
	if let colorData = defaults.data(forKey: key) {
		return NSUnarchiver.unarchiveObject(with: colorData) as? NSColor
	}
	
	return nil
}

internal func dataForColor(_ color: NSColor) -> Data {
	return NSArchiver.archivedData(withRootObject: color)
}

extension UserDefaults {
	var manTextColor: NSColor {
		get {
			return color(for: manTextColorKey, defaults: self)!
		}
		set {
			self.set(dataForColor(newValue), forKey: manTextColorKey)
		}
	}
	
	var manLinkColor: NSColor {
		get {
			return color(for: manLinkColorKey, defaults: self)!
		}
		set {
			self.set(dataForColor(newValue), forKey: manLinkColorKey)
		}
	}
	
	var manBackgroundColor: NSColor {
		get {
			return color(for: manBackgroundColorKey, defaults: self)!
		}
		set {
			self.set(dataForColor(newValue), forKey: manBackgroundColorKey)
		}
	}
	
	var manPath: String {
		get {
			return self.string(forKey: manPathKey)!
		}
		set {
			self.setValue(newValue, forKey: manPathKey)
		}
	}
	
	var manFont: NSFont {
		if let fontString = self.string(forKey: manFontKey) {
			if let spaceRange = fontString.range(of: " ") {
				func getEndIdx(_ string: String) -> String.Index {
					let endIdx = string.endIndex
					return string.index(before: endIdx)
				}
				let size = CGFloat((fontString[fontString.startIndex..<spaceRange.lowerBound] as NSString).floatValue)
				let endIdx = getEndIdx(fontString)
				let name = fontString[spaceRange.upperBound..<endIdx]
				let font = NSFont(name: name, size: size)
				if font != nil {
					return font!
				}
			}
		}
		
		return NSFont.userFixedPitchFont(ofSize: 12.0)! // Monaco, or Menlo
	}
}
