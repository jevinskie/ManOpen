//
//  AproposDocument.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

import Cocoa

private let restoreSearchString = "SearchString"
private let restoreTitle = "Title"

class AproposDocument: NSDocument, NSTableViewDataSource {
	var title: String = ""
	var searchString: String = ""
	var titles = [String]()
	var descriptions = [String]()
	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var titleColumn: NSTableColumn!

	override class func canConcurrentlyReadDocumentsOfType(typeName: String) -> Bool {
		return true
	}
	
	override var displayName: String {
		return title
	}
	
    override var windowNibName: String {
        return "Apropos"
    }

	func parseOutput(output: String) {
		
	}
	
    override func windowControllerDidLoadNib(aController: NSWindowController?) {
		var aSizeString = NSUserDefaults.standardUserDefaults().stringForKey("AproposWindowSize")

        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
		if let sizeString = aSizeString {
			var windowSize = NSSizeFromString(sizeString)
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
		let docController = ManDocumentController.sharedDocumentController() as ManDocumentController
		var command = docController.manCommandWithManPath(manPath)
		
		title = aTitle
		self.fileType = "apropos"
	}

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
		
		var search: String = coder.decodeObjectForKey(restoreSearchString) as NSString
		var theTitle = coder.decodeObjectForKey(restoreTitle) as NSString
		var manPath = NSUserDefaults.standardUserDefaults().manPath
		
		loadWithString(search, manPath: manPath, title: theTitle)
		
		//(self.windowControllers).makeObjectsPerformSelector("synchronizeWindowTitleWithDocumentName")
		for controller in self.windowControllers as [NSWindowController] {
			controller.synchronizeWindowTitleWithDocumentName()
		}
		tableView.reloadData()
	}
	
	init?(string apropos: String, manPath: String, title: String) {
		super.init()
		return nil
	}
}
