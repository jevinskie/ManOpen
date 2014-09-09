//
//  ManDocumentController.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa

func EscapePath(path: String, addSurroundingQuotes: Bool = false) -> String {
	var modPath = path
	if (path as NSString).rangeOfString("'").length > 0 {
		var newString = ""
		let scanner = NSScanner(string: path)
		
		scanner.charactersToBeSkipped = nil
		
		while !scanner.atEnd {
			var betweenString: NSString? = nil
			if scanner.scanUpToString("'", intoString: &betweenString) {
				if let aBetweenString = betweenString {
					newString += aBetweenString
				}
				if scanner.scanString("'", intoString: nil) {
					newString += "'\\''"
				}
			}
		}
		
		modPath = newString;
	}
	
	if addSurroundingQuotes {
		modPath = "'\(modPath)'"
	}
	
	return modPath;
}


@objc(ManDocumentController) class ManDocumentController: NSDocumentController, ManOpen, NSApplicationDelegate {

	@IBOutlet weak var helpTextView: NSTextView!
	@IBOutlet weak var openTextPanel: NSPanel!
	@IBOutlet weak var aproposPanel: NSPanel!
	@IBOutlet weak var helpPanel: NSPanel!
	@IBOutlet weak var aproposField: NSTextField!
	@IBOutlet weak var openTextField: NSTextField!
	@IBOutlet weak var openSectionPopup: NSPopUpButton!
	var startedUp = false

	func openName(name: String!, section: String!, manPath: String!, forceToFront force: Bool) {
		
	}
	
	func openApropos(apropos: String!, manPath: String!, forceToFront force: Bool) {
		
	}
	
	func openFile(filename: String!, forceToFront force: Bool) {
		
	}

	
	override init() {
		
		
		super.init()
	}

	required init(coder: NSCoder!) {
	    fatalError("init(coder:) has not been implemented")
	}
}
