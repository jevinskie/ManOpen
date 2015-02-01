//
//  ManDocument.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

import Cocoa


private let RestoreWindowDict = "RestoreWindowInfo"
private let RestoreSection    = "Section"
private let RestoreTitle      = "Title"
private let RestoreName       = "Name"
private let RestoreFileURL    = "URL"
private let RestoreFileType   = "DocType"

var filterCommand: String {
	let defaults = NSUserDefaults.standardUserDefaults()
	
	/* HTML parser in tiger got slow... RTF is faster, and is usable now that it supports hyperlinks */
	//let tool = "cat2html"
	let tool = "cat2rtf"
	var command = NSBundle.mainBundle().pathForResource(tool, ofType: nil)!
	
	command = EscapePath(command, addSurroundingQuotes: true)
	command += " -lH" // generate links, mark headers
	if defaults.boolForKey(kUseItalics) {
		command += " -i"
	}
	if !defaults.boolForKey(kUseBold) {
		command += " -g"
	}
	
	return command
}

class ManDocument: NSDocument {
	@IBOutlet weak var textScroll: NSScrollView!
	@IBOutlet weak var titleStringField: NSTextField!
	@IBOutlet weak var openSelectionButton: NSButton!
	@IBOutlet weak var sectionPopup: NSPopUpButton!
	private var hasLoaded = false
	private var restoreData = [String: AnyObject]()
	
	var sections = [String]()
	var sectionRanges = [NSRange]()
	
	var shortTitle = ""
	var copyURL: NSURL!
	var taskData: NSData?
	
	private var textView: ManTextView {
		return textScroll.contentView.documentView as ManTextView
	}
	
    override var windowNibName: String {
        // Override returning the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
        return "ManPage"
    }
	
	override class func canConcurrentlyReadDocumentsOfType(typeName: String) -> Bool {
		return true
	}

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override func dataOfType(typeName: String?, error outError: NSErrorPointer) -> NSData? {
        // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
		outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }

    override func readFromData(data: NSData?, ofType typeName: String?, error outError: NSErrorPointer) -> Bool {
        // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
        // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
		outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return false
    }

	/*
	* Standard NSDocument method.  We only want to override if we aren't
	* representing an actual file.
	*/
	override var displayName: String {
		return fileURL != nil ? super.displayName : shortTitle
	}

	init?(name: String, section: String?, manPath: String, title: String) {
		super.init()
		return nil
	}
	
	private func loadDocumentWithName(name: String, section: String?, manPath: String?, title: String) {
		var docController = ManDocumentController.sharedDocumentController() as ManDocumentController
		var command = docController.manCommandWithManPath(manPath)
		fileType = "man"
		shortTitle = title
		
		if section != nil && countElements(section!) > 0 {
			command += " " + section!.lowercaseString
			copyURL = NSURL(string: URL_SCHEME_PREFIX + "//\(section!)/\(title)")
		} else {
			copyURL = NSURL(string: URL_SCHEME_PREFIX + "//\(title)")
		}
		
		restoreData = [RestoreName: name,
			RestoreTitle: title,
			RestoreSection: section ?? ""]
		
		command += " " + name
		
		loadCommand(command)
	}
	
	func loadCommand(command: String) {
		var docController = ManDocumentController.sharedDocumentController() as ManDocumentController
		var fullCommand = "\(command) | \(filterCommand)"
		taskData = docController.dataByExecutingCommand(fullCommand)
		
		showData()
	}
	
	func showData() {
		let defaults = NSUserDefaults.standardUserDefaults()
		var storage: NSTextStorage? = nil
		let manFont = defaults.manFont
		let linkColor = defaults.manLinkColor
		let textColor = defaults.manTextColor
		let backgroundColor = defaults.manBackgroundColor
		if textScroll == nil || hasLoaded {
			return
		}
		
		if taskData?.RTFData ?? false {
			storage = NSTextStorage(RTF: taskData!, documentAttributes: nil)
		} else if taskData != nil {
			storage = NSTextStorage(HTML: taskData!, documentAttributes: nil)
		}
		
		if storage == nil {
			storage = NSTextStorage()
		}
		
		if storage?.string.rangeOfCharacterFromSet(NSCharacterSet.letterCharacterSet())?.isEmpty ?? true {
			storage?.mutableString.setString("\nNo manual entry.")
		}
		
		sections.removeAll()
		sectionRanges.removeAll()
		
		if let aStorage = storage {
			let manager = NSFontManager.sharedFontManager()
			let family = manFont.familyName!
			let size = manFont.pointSize
			var currIndex = 0

			tryCatchBlock({ () -> Void in
				aStorage.beginEditing()
				
				while currIndex < aStorage.length {
					var currRange = NSRange(location: 0, length: 0)
					var attribs = aStorage.attributesAtIndex(currIndex, effectiveRange: &currRange)
					var font = attribs[NSFontAttributeName] as? NSFont
					var isLink = false
					
					if font != nil && font!.familyName == "Courier" {
						self.addSectionHeader(aStorage.mutableString.substringWithRange(currRange), range: currRange)
					}
					
					isLink = (attribs[NSLinkAttributeName] != nil)
					
					if (font != nil && (font!.familyName != family)) {
					font = manager.convertFont(font!, toFamily: family) ;
					}
					if (font != nil && font!.pointSize != size) {
						font = manager.convertFont(font!, toSize: size)
					}
					if (font != nil) {
						storage?.addAttribute(NSFontAttributeName, value: font!, range: currRange)
					}
					
					/*
					* Starting in 10.3, there is a -setLinkTextAttributes: method to set these, without having to
					* determine the ranges ourselves.  However, since we are already iterating all the ranges
					* for other reasons, may as well keep the old way.
					*/
					if isLink {
						storage?.addAttribute(NSForegroundColorAttributeName, value: linkColor, range: currRange)
					} else {
						storage?.addAttribute(NSForegroundColorAttributeName, value: textColor, range: currRange)
					}
					
					currIndex = NSMaxRange(currRange)
				}
				
				aStorage.endEditing()
			}, { (localException) -> Void in
				NSLog("Exception during formatting: %@", localException);
			})
			
			textView.backgroundColor = backgroundColor
			setupSectionPopup()
			
			/*
			* The 10.7 document reloading stuff can cause the loading methods to be invoked more than
			* once, and the second time through we have thrown away our raw data.  Probably indicates
			* some overkill code elsewhere on my part, but putting in the hadLoaded guard to only
			* avoid doing anything after we have loaded real data seems to help.
			*/
			if (taskData != nil) {
				hasLoaded = true
			}
			
			// no need to keep around rtf data
			taskData = nil;
		}
	}

	func setupSectionPopup() {
		sectionPopup.removeAllItems()
		sectionPopup.addItemWithTitle("Section:")
		sectionPopup.enabled = sections.count > 0
		
		if sectionPopup.enabled {
			sectionPopup.addItemsWithTitles(sections)
		}
	}

	func addSectionHeader(header: String, range: NSRange) {
		/* Make sure it is a header -- error text sometimes is not Courier, so it gets passed in here. */
		if !header.rangeOfCharacterFromSet(NSCharacterSet.uppercaseLetterCharacterSet())!.isEmpty &&
			!header.rangeOfCharacterFromSet(NSCharacterSet.uppercaseLetterCharacterSet())!.isEmpty {
				var label = header
				var count = 1
				
				/* Check for dups (e.g. lesskey(1) ) */
				while find(sections, label) != nil {
					count++
					label = "\(header) [\(count)]"
				}
				sections.append(label)
				sectionRanges.append(range)
		}
	}
	
	@IBAction func saveCurrentWindowSize(sender: AnyObject?) {

	}

	@IBAction func openSelection(sender: AnyObject?) {
		var selectedRange = textView.selectedRange()
		
		if selectedRange.length > 0 {
			let selectedString = (textView.string! as NSString).substringWithRange(selectedRange)
			(ManDocumentController.sharedDocumentController() as ManDocumentController).openString(selectedString)
		}
		
		textView.window?.makeFirstResponder(textView)
	}

	@IBAction func displaySection(sender: AnyObject?) {
		let section = sectionPopup.indexOfSelectedItem
		if (section > 0 && section <= sectionRanges.count) {
			let range = sectionRanges[section - 1]
			textView.scrollRangeToTop(range)
		}
	}

	@IBAction func copyURL(sender: AnyObject?) {

	}
}
