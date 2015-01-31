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
	var shortTitle = ""
	private var restoreData = [String: AnyObject]()
	var copyURL: NSURL!
	var taskData: NSData?
	
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
		
	}
	
	@IBAction func saveCurrentWindowSize(sender: AnyObject?) {

	}

	@IBAction func openSelection(sender: AnyObject?) {

	}

	@IBAction func displaySection(sender: AnyObject?) {

	}

	@IBAction func copyURL(sender: AnyObject?) {

	}
}
