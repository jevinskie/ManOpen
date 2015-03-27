//
//  AproposDocument.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

import Cocoa
import SwiftAdditions

private let restoreSearchString = "SearchString"
private let restoreTitle = "Title"

class AproposDocument: NSDocument, NSTableViewDataSource {
	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var titleColumn: NSTableColumn!
	
	var title: String = ""
	var searchString: String = ""
	private var aproposItems: [(title: String, description: String)] = []
	
	override class func canConcurrentlyReadDocumentsOfType(typeName: String) -> Bool {
		return true
	}
	
	override var displayName: String {
		return title
	}
	
    override var windowNibName: String {
        return "Apropos"
    }

	func parseOutput(output: String!) {
		if output == nil {
			return
		}
		
		let lines: [String] = {
			var aLines = output.componentsSeparatedByString("\n")
			
			aLines.sort { (lhs, rhs) -> Bool in
				let toRet = lhs.caseInsensitiveCompare(rhs)
				return toRet == .OrderedAscending
			}
			return aLines
			}()
		
		if lines.count == 0 {
			return
		}
		
		for line in lines {
			if count(line) == 0 {
				continue
			}
			
			var dashRange = line.rangeOfString("\t\t- ") //OPENSTEP
			if dashRange == nil {
				dashRange = line.rangeOfString("\t- ") //OPENSTEP
			}
			if dashRange == nil {
				dashRange = line.rangeOfString("\t-", options: .BackwardsSearch | .AnchoredSearch)
			}
			if dashRange == nil {
				dashRange = line.rangeOfString(" - ") //MacOSX
			}
			if dashRange == nil {
				dashRange = line.rangeOfString(" -", options: .BackwardsSearch | .AnchoredSearch)
			}
			
			if let aDashRange = dashRange {
				let title = line[line.startIndex ..< aDashRange.startIndex]
				let adescription = line[aDashRange.endIndex ..< line.endIndex]
				aproposItems.append((title: title, description: adescription))
			}
		}
	}
	
    override func windowControllerDidLoadNib(aController: NSWindowController) {
		var aSizeString = NSUserDefaults.standardUserDefaults().stringForKey("AproposWindowSize")

        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
		if let sizeString = aSizeString {
			var windowSize = NSSize(string: sizeString)
			var window = tableView.window
			var frame = window!.frame
			
			if windowSize.width > 30.0 && windowSize.height > 30.0 {
				frame.size = windowSize
				window!.setFrame(frame, display: false)
			}
		}
		
		tableView.target = self
		tableView.doubleAction = "openManPages:"
		tableView.sizeLastColumnToFit()
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

	private func loadWithString(apropos: String, manPath: String, title aTitle: String) {
		var aapropos = apropos
		let docController = ManDocumentController.sharedDocumentController() as! ManDocumentController
		var command = docController.manCommandWithManPath(manPath)
		
		title = aTitle
		fileType = "apropos"
		
		/* Searching for a blank string doesn't work anymore... use a catchall regex */
		if count(apropos) == 0 {
			aapropos = "."
		}
		searchString = aapropos

		/*
		* Starting on Tiger, man -k doesn't quite work the same as apropos directly.
		* Use apropos then, even on Panther.  Panther/Tiger no longer accept the -M
		* argument, so don't try... we set the MANPATH environment variable, which
		* gives a warning on Panther (stderr; ignored) but not on Tiger.
		*/
		// [command appendString:@" -k"];
		command = "/usr/bin/apropos"

		command += " \(EscapePath(aapropos, addSurroundingQuotes: true))"
		let output = docController.dataByExecutingCommand(command, manPath: manPath)!
		/* The whatis database appears to not be UTF8 -- at least, UTF8 can fail, even on 10.7 */
		var outString = NSString(data: output, encoding: NSUTF8StringEncoding) as? String
		if outString == nil {
			outString = NSString(data: output, encoding: NSMacOSRomanStringEncoding) as? String
		}
		parseOutput(outString)
	}

	override func printOperationWithSettings(printSettings: [NSObject : AnyObject], error outError: NSErrorPointer) -> NSPrintOperation? {
		let op = NSPrintOperation(view: tableView, printInfo: NSPrintInfo(dictionary: printSettings))
		return op
	}
	
	@IBAction func openManPages(sender: NSTableView?) {
		if sender?.clickedRow >= 0 {
			let manPage = aproposItems[sender!.clickedRow].title
			(ManDocumentController.sharedDocumentController() as! ManDocumentController).openString(manPage, oneWordOnly: true)
		}
	}
	
	@IBAction func saveCurrentWindowSize(sender: AnyObject?) {
		let size = tableView.window!.frame.size
		NSUserDefaults.standardUserDefaults()["AproposWindowSize"] = size.stringValue
	}

	override init() {
		super.init()
	}
	
	init?(string apropos: String, manPath: String, title aTitle: String) {
		super.init()
		loadWithString(apropos, manPath: manPath, title: aTitle)
		
		if aproposItems.count == 0 {
			let anAlert = NSAlert()
			anAlert.messageText = NSLocalizedString("Nothing found", comment: "Nothing found")
			anAlert.informativeText = String(format: NSLocalizedString("No pages related to '%@' found", comment: "When a page couldn't be found"), apropos)
			anAlert.runModal()
			return nil;
		}
	}
	
	// MARK: NSTableView data sources
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return aproposItems.count
	}
	
	func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
		var item = aproposItems[row]
		var toRet = (tableColumn === titleColumn) ? item.title : item.description
		return toRet
	}
	
	// MARK: Document restoration
	override func encodeRestorableStateWithCoder(coder: NSCoder) {
		super.encodeRestorableStateWithCoder(coder)
		coder.encodeObject(searchString, forKey: restoreSearchString)
		coder.encodeObject(title, forKey: restoreTitle)
	}
	
	override func restoreStateWithCoder(coder: NSCoder) {
		super.restoreStateWithCoder(coder)
		
		if !coder.containsValueForKey(restoreSearchString) {
			return
		}
		
		var search: String = coder.decodeObjectForKey(restoreSearchString) as! String
		var theTitle = coder.decodeObjectForKey(restoreTitle) as! String
		var manPath = NSUserDefaults.standardUserDefaults().manPath
		
		loadWithString(search, manPath: manPath, title: theTitle)
		
		(windowControllers as! [NSWindowController]).map({vc in vc.synchronizeWindowTitleWithDocumentName()})
		tableView.reloadData()
	}
}
