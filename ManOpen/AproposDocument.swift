//
//  AproposDocument.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

import Cocoa
import SwiftAdditions
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


private let restoreSearchString = "SearchString"
private let restoreTitle = "Title"

class AproposDocument: NSDocument, NSTableViewDataSource {
	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var titleColumn: NSTableColumn!
	
	var title: String = ""
	var searchString: String = ""
	fileprivate var aproposItems: [(title: String, desc: String)] = []
	
	override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
		return true
	}
	
	override var displayName: String! {
		get {
			return title
		}
		set {
			//do nothing
		}
	}
	
	override var windowNibName: String {
		return "Apropos"
	}
	
	func parseOutput(_ output: String!) {
		if output == nil {
			return
		}
		
		let lines: [String] = {
			var aLines = output.components(separatedBy: "\n")
			
			aLines.sort { (lhs, rhs) -> Bool in
				let toRet = lhs.caseInsensitiveCompare(rhs)
				return toRet == .orderedAscending
			}
			return aLines
			}()
		
		if lines.count == 0 {
			return
		}
		
		for line in lines {
			if line.characters.count == 0 {
				continue
			}
			
			var dashRange = line.range(of: "\t\t- ") //OPENSTEP
			if dashRange == nil {
				dashRange = line.range(of: "\t- ") //OPENSTEP
			}
			if dashRange == nil {
				dashRange = line.range(of: "\t-", options: [.backwards, .anchored])
			}
			if dashRange == nil {
				dashRange = line.range(of: " - ") //MacOSX
			}
			if dashRange == nil {
				dashRange = line.range(of: " -", options: [.backwards, .anchored])
			}
			
			if let aDashRange = dashRange {
				let title = line[line.startIndex ..< aDashRange.lowerBound].trimmingCharacters(in: CharacterSet.whitespaces)
				let adescription = line[aDashRange.upperBound ..< line.endIndex]
				aproposItems.append((title: title, desc: adescription))
			}
		}
	}
	
	override func windowControllerDidLoadNib(_ aController: NSWindowController) {
		let aSizeString = UserDefaults.standard.string(forKey: "AproposWindowSize")
		
		super.windowControllerDidLoadNib(aController)
		// Add any code here that needs to be executed once the windowController has loaded the document's window.
		if let sizeString = aSizeString {
			let windowSize = NSSize(string: sizeString)
			let window = tableView.window
			var frame = window!.frame
			
			if windowSize.width > 30.0 && windowSize.height > 30.0 {
				frame.size = windowSize
				window!.setFrame(frame, display: false)
			}
		}
		
		tableView.target = self
		tableView.doubleAction = #selector(AproposDocument.openManPages(_:))
		tableView.sizeLastColumnToFit()
	}
	
	override func data(ofType typeName: String?) throws -> Data {
		// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
		// You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}
	
	override func read(from data: Data, ofType typeName: String?) throws {
		// Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
		// You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
		// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}
	
	fileprivate func loadWithString(_ apropos: String, manPath: String, title aTitle: String) {
		var aapropos = apropos
		let docController = ManDocumentController.shared() as! ManDocumentController
		var command = docController.manCommandWithManPath(manPath)
		
		title = aTitle
		fileType = "apropos"
		
		/* Searching for a blank string doesn't work anymore... use a catchall regex */
		if apropos.characters.count == 0 {
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
		guard let output = docController.dataByExecutingCommand(command, manPath: manPath) else {
			parseOutput("")

			return
		}
		/* The whatis database appears to not be UTF8 -- at least, UTF8 can fail, even on 10.7 */
		var outString = String(data: output, encoding: String.Encoding.utf8)
		if outString == nil {
			outString = String(data: output, encoding: String.Encoding.macOSRoman)
		}
		parseOutput(outString)
	}
	
	override func printOperation(withSettings printSettings: [String : Any]) throws -> NSPrintOperation {
		let op = NSPrintOperation(view: tableView, printInfo: NSPrintInfo(dictionary: printSettings))
		return op
	}
	
	@IBAction func openManPages(_ sender: NSTableView?) {
		if sender?.clickedRow >= 0 {
			let manPage = aproposItems[sender!.clickedRow].title
			(ManDocumentController.shared() as! ManDocumentController).openString(manPage, oneWordOnly: true)
		}
	}
	
	@IBAction func saveCurrentWindowSize(_ sender: AnyObject?) {
		let size = tableView.window!.frame.size
		UserDefaults.standard["AproposWindowSize"] = size.stringValue
	}
	
	override init() {
		super.init()
	}
	
	convenience init?(string apropos: String, manPath: String, title aTitle: String) {
		self.init()
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
	func numberOfRows(in tableView: NSTableView) -> Int {
		return aproposItems.count
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		let item = aproposItems[row]
		let toRet = (tableColumn === titleColumn) ? item.title : item.desc
		return toRet
	}
	
	// MARK: Document restoration
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		coder.encode(searchString, forKey: restoreSearchString)
		coder.encode(title, forKey: restoreTitle)
	}
	
	override func restoreState(with coder: NSCoder) {
		super.restoreState(with: coder)
		
		if !coder.containsValue(forKey: restoreSearchString) {
			return
		}
		
		let search: String = coder.decodeObject(forKey: restoreSearchString) as! String
		let theTitle = coder.decodeObject(forKey: restoreTitle) as! String
		let manPath = UserDefaults.standard.manPath
		
		loadWithString(search, manPath: manPath, title: theTitle)
		
		for wc in windowControllers {
			wc.synchronizeWindowTitleWithDocumentName()
		}
		tableView.reloadData()
	}
}
