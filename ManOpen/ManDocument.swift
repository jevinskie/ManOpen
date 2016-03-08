//
//  ManDocument.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

import Cocoa
import ApplicationServices
import SwiftAdditions

private let RestoreWindowDict = "RestoreWindowInfo"
private let RestoreSection    = "Section"
private let RestoreTitle      = "Title"
private let RestoreName       = "Name"
private let RestoreFileURL    = "URL"
private let RestoreFileType   = "DocType"

private var filterCommand: String {
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

final class ManDocument: NSDocument, NSWindowDelegate {
	@IBOutlet weak var textScroll: NSScrollView!
	@IBOutlet weak var titleStringField: NSTextField!
	@IBOutlet weak var openSelectionButton: NSButton!
	@IBOutlet weak var sectionPopup: NSPopUpButton!
	private var hasLoaded = false
	private var restoreData = [String: AnyObject]()
	var sections: [String] = [String]()
	var sectionRanges: [NSRange] = [NSRange]()
	
	var shortTitle = ""
	var copyURL: NSURL!
	var taskData: NSData?
	
	private var textView: ManTextView {
		return textScroll.contentView.documentView as! ManTextView
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
		let defaults = NSUserDefaults.standardUserDefaults()
		let sizeString = defaults.stringForKey("ManWindowSize")
		
		super.windowControllerDidLoadNib(aController)
		// Add any code here that needs to be executed once the windowController has loaded the document's window.
		
		if let sizeString = sizeString {
			let windowSize = NSSize(string: sizeString)
			let window = textView.window!
			var frame = window.frame
			
			if windowSize.width > 30.0 && windowSize.height > 30 {
				frame.size = windowSize
				window.setFrame(frame, display: false)
			}
		}
		
		titleStringField.stringValue = shortTitle
		textView.textStorage?.mutableString.setString(NSLocalizedString("Loading...", comment: "Before the man page is loaded"))
		textView.backgroundColor = defaults.manBackgroundColor
		textView.textColor = defaults.manTextColor
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue()) {
			self.showData()
		}
		
		textView.window?.makeFirstResponder(textView)
		textView.window?.delegate = self
	}
	
	override func readFromURL(url: NSURL, ofType typeName: String) throws {
		switch typeName {
		case "man":
			loadManFile(url.path!, isGzip: false)
			
		case "mangz":
			loadManFile(url.path!, isGzip: true)
			
		case "cat":
			loadCatFile(url.path!, isGzip: false)
			
		case "catgz":
			loadCatFile(url.path!, isGzip: true)
			
		default:
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Invalid document type", comment:"Invalid document type")])
			
		}
		
		// strip extension twice in case it is a e.g. "1.gz" filename
		self.shortTitle = (((url.path! as NSString).lastPathComponent as NSString).stringByDeletingPathExtension as NSString).stringByDeletingPathExtension
		copyURL = url;
		
		restoreData = [
			RestoreFileURL: url,
			RestoreFileType: typeName];
		
		if taskData == nil {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Could not read manual data", comment: "Could not read manual data")])
		}
	}
	
	
	/// Standard NSDocument method.  We only want to override if we aren't
	/// representing an actual file.
	override var displayName: String {
		return fileURL != nil ? super.displayName : shortTitle
	}
	
	override init() {
		super.init()
	}
	
	convenience init?(name: String, section: String?, manPath: String?, title: String) {
		self.init()
		loadDocumentWithName(name, section: section, manPath: manPath, title: title)
	}
	
	private func loadDocumentWithName(name: String, section: String?, manPath: String?, title: String) {
		let docController = ManDocumentController.sharedDocumentController() as! ManDocumentController
		var command = docController.manCommandWithManPath(manPath)
		fileType = "man"
		shortTitle = title
		
		if let section = section where section.characters.count > 0 {
			command += " " + section.lowercaseString
			copyURL = NSURL(string: URL_SCHEME_PREFIX + "//\(section)/\(title)")
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
		let docController = ManDocumentController.sharedDocumentController() as! ManDocumentController
		let fullCommand = "\(command) | \(filterCommand)"
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
		} else if let taskData = taskData {
			storage = NSTextStorage(HTML: taskData, documentAttributes: nil)
		}
		
		if storage == nil {
			storage = NSTextStorage()
		}
		
		if storage?.string.rangeOfCharacterFromSet(NSCharacterSet.letterCharacterSet()) == nil {
			storage?.mutableString.setString(NSLocalizedString("\nNo manual entry.", comment: "'No manual entry', preceeded by a newline"))
		}
		
		sections.removeAll()
		sectionRanges.removeAll()
		
		if let aStorage = storage {
			let manager = NSFontManager.sharedFontManager()
			let family = manFont.familyName ?? manFont.fontName
			let size = manFont.pointSize
			var currIndex = 0
			
			tryCatchBlock({ () -> Void in
				aStorage.beginEditing()
				
				while currIndex < aStorage.length {
					var currRange = NSRange(location: 0, length: 0)
					var attribs = aStorage.attributesAtIndex(currIndex, effectiveRange: &currRange)
					var font = attribs[NSFontAttributeName] as? NSFont
					var isLink = false
					
					if font != nil && font!.familyName != "Courier" {
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
						aStorage.addAttribute(NSFontAttributeName, value: font!, range: currRange)
					}
					
					/*
					* Starting in 10.3, there is a -setLinkTextAttributes: method to set these, without having to
					* determine the ranges ourselves.  However, since we are already iterating all the ranges
					* for other reasons, may as well keep the old way.
					*/
					if isLink {
						aStorage.addAttribute(NSForegroundColorAttributeName, value: linkColor, range: currRange)
					} else {
						aStorage.addAttribute(NSForegroundColorAttributeName, value: textColor, range: currRange)
					}
					
					currIndex = currRange.max
				}
				
				aStorage.endEditing()
				}, { (localException) -> Void in
					print("Exception during formatting: \(localException)")
			})
			
			textView.layoutManager?.replaceTextStorage(aStorage)
			textView.window?.invalidateCursorRectsForView(textView)
		}
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
		if header.rangeOfCharacterFromSet(NSCharacterSet.uppercaseLetterCharacterSet()) != nil &&
			header.rangeOfCharacterFromSet(NSCharacterSet.uppercaseLetterCharacterSet()) != nil {
				var label = header
				var count = 1
				
				/* Check for dups (e.g. lesskey(1) ) */
				while sections.contains(label) {
					count++
					label = "\(header) [\(count)]"
				}
				sections.append(label)
				sectionRanges.append(range)
		}
	}
	
	func loadManFile(filename: String, isGzip: Bool = false) {
		let defaults = NSUserDefaults.standardUserDefaults()
		var nroffFormat = defaults.stringForKey(kNroffCommand)!
		var nroffCommand: String
		let hasQuote = nroffFormat.rangeOfString("'%@'") != nil
		
		/* If Gzip, change the command into a filter of the output of gzcat.  I'm
		getting the feeling that the customizable nroff command is more trouble
		than it's worth, especially now that OSX uses the good version of gnroff */
		if isGzip {
			let repl = hasQuote ? "'%@'" : "%@"
			if let replRange = nroffFormat.rangeOfString(repl) {
				var formatCopy = nroffFormat
				formatCopy.replaceRange(replRange, with: "")
				nroffFormat = "/usr/bin/gzip -dc \(repl) | \(formatCopy)"
			}
		}
		
		nroffCommand = String(format: nroffFormat, EscapePath(filename, addSurroundingQuotes: !hasQuote))
		loadCommand(nroffCommand)
	}
	
	func loadCatFile(filename: String, isGzip: Bool = false) {
		let binary = isGzip ? "/usr/bin/gzip -dc" : "/bin/cat"
		loadCommand("\(binary) '\(EscapePath(filename, addSurroundingQuotes: false))'")
	}
	
	@IBAction func saveCurrentWindowSize(sender: AnyObject?) {
		let size = textView.window!.frame.size
		NSUserDefaults.standardUserDefaults().setObject(size.stringValue, forKey: "ManWindowSize")
	}
	
	@IBAction func openSelection(sender: AnyObject?) {
		let selectedRange = textView.selectedRange()
		
		if selectedRange.length > 0 {
			let selectedString = (textView.string! as NSString).substringWithRange(selectedRange)
			(ManDocumentController.sharedDocumentController() as! ManDocumentController).openString(selectedString)
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
		if let aCopyURL = copyURL {
			let pb = NSPasteboard.generalPasteboard()
			var types = [String]()
			
			types.append(NSURLPboardType)
			if aCopyURL.fileURL {
				types.append(NSFilenamesPboardType)
			}
			types.append(NSStringPboardType)
			pb.declareTypes(types, owner: nil)
			
			aCopyURL.writeToPasteboard(pb)
			pb.setString("<\(aCopyURL.absoluteString)>", forType: NSStringPboardType)
			if aCopyURL.fileURL {
				pb.setPropertyList([aCopyURL.path!], forType: NSFilenamesPboardType)
			}
		}
	}
	
	override func runPageLayout(sender: AnyObject?) {
		NSApplication.sharedApplication().runPageLayout(sender)
	}
	
	override func printOperationWithSettings(printSettings: [String : AnyObject]) throws -> NSPrintOperation {
		let operation = NSPrintOperation(view: textView, printInfo: NSPrintInfo(dictionary: printSettings))
		let printInfo = operation.printInfo
		printInfo.verticallyCentered = false
		printInfo.horizontallyCentered = true
		printInfo.horizontalPagination = .FitPagination
		
		return operation
	}
	
	override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
		if menuItem.action == "copyURL:" {
			return copyURL != nil
		}
		
		return super.validateMenuItem(menuItem)
	}
	
	// MARK: NSWindowRestoration functions
	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)
		coder.encodeObject(restoreData, forKey: RestoreWindowDict)
	}
	
	override func restoreStateWithCoder(coder: NSCoder) {
		super.restoreStateWithCoder(coder)
		
		if !coder.containsValueForKey(RestoreWindowDict) {
			return
		}
		
		if let restoreInfo = coder.decodeObjectForKey(RestoreWindowDict) as? [String: AnyObject] {
			if let aRestoreName = restoreInfo[RestoreName] as? String {
				let section = restoreInfo[RestoreSection] as? String
				let title = restoreInfo[RestoreTitle] as! String
				let manPath = NSUserDefaults.standardUserDefaults().manPath
				
				loadDocumentWithName(aRestoreName, section: section, manPath: manPath, title: title)
				/* Usually, URL-backed documents have been automatically restored already
				(the copyURL would be set), but just in case... */
			} else if restoreInfo[RestoreFileURL] != nil && copyURL == nil {
				let url = restoreInfo[RestoreFileURL] as! NSURL
				let type = restoreInfo[RestoreFileType] as! String
				
				do {
					try readFromURL(url, ofType: type)
				} catch _ {
				}
			}
			
			titleStringField.stringValue = shortTitle
			
			for vc in windowControllers {
				vc.synchronizeWindowTitleWithDocumentName()
			}
		}
	}
}
