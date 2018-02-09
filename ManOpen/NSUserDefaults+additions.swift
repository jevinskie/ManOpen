//
//  NSUserDefaults+additions.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa
import SwiftAdditions

let manTextColorKey = "ManTextColor"
let manLinkColorKey = "ManLinkColor"
let manFontKey		= "ManFont"
let manPathKey		= "ManPath"
let manBackgroundColorKey = "ManBackgroundColor"

private func color(for key: String, defaults: UserDefaults = UserDefaults.standard) -> NSColor? {
	if let colorData: Data = defaults[key] {
		return NSKeyedUnarchiver.unarchiveObject(with: colorData) as? NSColor
	}
	
	return nil
}

internal func dataForColor(_ color: NSColor) -> Data {
	return NSKeyedArchiver.archivedData(withRootObject: color)
}

extension UserDefaults {
	var manTextColor: NSColor {
		get {
			return color(for: manTextColorKey, defaults: self)!
		}
		set {
			self[manTextColorKey] = dataForColor(newValue)
		}
	}
	
	var manLinkColor: NSColor {
		get {
			if let newCol = color(for: manLinkColorKey, defaults: self) {
				return newCol
			} else {
				removeObject(forKey: manLinkColorKey)
			}
			return color(for: manLinkColorKey, defaults: self)!
		}
		set {
			self[manLinkColorKey] = dataForColor(newValue)
		}
	}
	
	var manBackgroundColor: NSColor {
		get {
			if let newCol = color(for: manBackgroundColorKey, defaults: self) {
				return newCol
			} else {
				removeObject(forKey: manBackgroundColorKey)
			}
			return color(for: manBackgroundColorKey, defaults: self)!
		}
		set {
			self[manBackgroundColorKey] = dataForColor(newValue)
		}
	}
	
	var manPath: String {
		get {
			return self[manPathKey]!
		}
		set {
			self[manPathKey] = newValue
		}
	}
	
	var manFont: NSFont {
		if let fontString: String = self[manFontKey] {
			if let spaceRange = fontString.range(of: " ") {
				func getEndIdx(_ string: String) -> String.Index {
					let endIdx = string.endIndex
					return string.index(before: endIdx)
				}
				let size = CGFloat((fontString[fontString.startIndex..<spaceRange.lowerBound] as NSString).floatValue)
				let endIdx = getEndIdx(fontString)
				let name = fontString[spaceRange.upperBound..<endIdx]
				if let font = NSFont(name: String(name), size: size) {
					return font
				}
			}
		}
		
		return NSFont.userFixedPitchFont(ofSize: 12.0)! // Monaco, or Menlo
	}
}
