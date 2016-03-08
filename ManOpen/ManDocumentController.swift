//
//  ManDocumentController.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa
import SwiftAdditions

private let MAN_BINARY = "/usr/bin/man"
//#define MANPATH_FORMAT @" -m '%@'"  // There's a bug in man(1) on OSX and OSXS
private let MANPATH_FORMAT = " -M '%@'"

func EscapePath(path: String, addSurroundingQuotes: Bool = false) -> String {
	var modPath = path
	if path.rangeOfString("'") != nil {
		var newString = ""
		let scanner = NSScanner(string: path)
		
		scanner.charactersToBeSkipped = nil
		
		while !scanner.atEnd {
			var betweenString: NSString? = nil
			if scanner.scanUpToString("'", intoString: &betweenString) {
				if let aBetweenString = betweenString {
					newString += aBetweenString as String
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

@NSApplicationMain
class ManDocumentController: NSDocumentController, ManOpen, NSApplicationDelegate {
	@IBOutlet weak var helpScrollView: NSScrollView!
	@IBOutlet weak var openTextPanel: NSPanel!
	@IBOutlet weak var aproposPanel: NSPanel!
	@IBOutlet weak var helpPanel: NSPanel!
	@IBOutlet weak var aproposField: NSTextField!
	@IBOutlet weak var openTextField: NSTextField!
	@IBOutlet weak var openSectionPopup: NSPopUpButton!
	var startedUp = false
	private var nibObjects = [AnyObject]()
	
	func ensureActive() {
		if !NSApplication.sharedApplication().active {
			NSApplication.sharedApplication().activateIgnoringOtherApps(true)
		}
	}
	
	//@objc(openName:section:manPath:forceToFront:) func open(name name: String, section: String? = nil, manPath: String? = nil, forceToFront force: Bool = true)
	@objc func openName(name: String, section: String? = nil, manPath: String? = nil, forceToFront force: Bool = true) {
		if force {
			ensureActive()
		}
		openDocumentWithName(name, section: section, manPath: manPath ?? NSUserDefaults.standardUserDefaults().manPath)
	}
	
	@objc func openApropos(apropos: String, manPath: String? = nil, forceToFront force: Bool = true) {
		if force {
			ensureActive()
		}
		
		openAproposDocument(apropos, manPath: manPath ?? NSUserDefaults.standardUserDefaults().manPath)
	}
	
	@objc func openFile(filename: String, forceToFront force: Bool = true) {
		if force {
			ensureActive()
		}
		
		openDocumentWithContentsOfURL(NSURL(fileURLWithPath: filename), display: true) { (doc, wasOpened, error) -> Void in
			//What to do??
		}
	}
	
	var useModalPanels: Bool {
		return !NSUserDefaults.standardUserDefaults().boolForKey(kKeepPanelsOpen)
	}
	
	func applicationDidFinishLaunching(notification: NSNotification) {
		NSApp.servicesProvider = self
		openTextPanel.setFrameUsingName("OpenTitlePanel")
		openTextPanel.setFrameAutosaveName("OpenTitlePanel")
		aproposPanel.setFrameUsingName("AproposPanel")
		aproposPanel.setFrameAutosaveName("AproposPanel")
		
		startedUp = true
	}
	
	func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
		if startedUp {
			return NSUserDefaults.standardUserDefaults().boolForKey("OpenPanelWhenNoWindows")
		} else {
			return NSUserDefaults.standardUserDefaults().boolForKey("OpenPanelOnStartup")
		}
	}
	
	func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
		if applicationShouldOpenUntitledFile(sender) {
			if !openTextPanel.visible {
				openSectionPopup.selectItemAtIndex(0)
			}
			openTextField.selectText(self)
			dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
				usleep(0)
				dispatch_sync(dispatch_get_main_queue(), { () -> Void in
					self.openTextPanel.makeKeyAndOrderFront(self)
				})
			})
			return true
		}
		return false
	}
	
	override func removeDocument(document: NSDocument) {
		let autoQuit = NSUserDefaults.standardUserDefaults().boolForKey(kQuitWhenLastClosed)
		
		super.removeDocument(document)
		
		if documents.count == 0 && autoQuit {
			dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
				usleep(0)
				dispatch_sync(dispatch_get_main_queue(), { () -> Void in
					NSApplication.sharedApplication().terminate(self)
				})
			})
			
		}
	}
	
	func manCommandWithManPath(manPath: String?) -> String {
		var command = MAN_BINARY
		
		if let manPath = manPath where !manPath.isEmpty {
			command += " -M '\(EscapePath(manPath))'"
		}
		
		return command
	}
	
	func dataByExecutingCommand(command: String, maxLength: Int = 0, extraEnv: Dictionary<String, String>? = nil) -> NSData? {
		let pipe = NSPipe()
		let task = NSTask()
		var output: NSData?
		
		if let anExtraEnv = extraEnv {
			var environment = NSProcessInfo.processInfo().environment
			environment += anExtraEnv
			task.environment = environment
		}
		
		task.launchPath = "/bin/sh"
		task.arguments = ["-c", command]
		task.standardOutput = pipe
		task.standardError = NSFileHandle.fileHandleWithNullDevice()
		task.launch()
		
		if maxLength > 0 {
			output = pipe.fileHandleForReading.readDataOfLength(maxLength)
			task.terminate()
		} else {
			output = try? pipe.fileHandleForReading.readDataToEndOfFileIgnoreInterrupt()
		}
		task.waitUntilExit()
		
		return output
	}
	
	func dataByExecutingCommand(command: String, manPath: String) -> NSData? {
		return dataByExecutingCommand(command, extraEnv: ["MANPATH" : manPath])
	}
	
	func manFileForName(name: String, section: String? = nil, manPath: String? = nil) -> String? {
		var command = manCommandWithManPath(manPath)
		let spaceString = ""
		command += " -w \(section ?? spaceString) \(name)"
		if let data = dataByExecutingCommand(command) {
			if data.length <= 0 {
				return nil
			}
			
			let manager = NSFileManager.defaultManager()
			var len = data.length
			let ptr = data.bytes
			
			let newlinePtr = memchr(ptr, 0x0A, len) // 0A is == '\n'
			
			if newlinePtr != nil {
				len = ptr.distanceTo(newlinePtr)
			}
			
			let filename = manager.stringWithFileSystemRepresentation(UnsafePointer<Int8>(ptr), length: len)
			if manager.fileExistsAtPath(filename) {
				return filename
			}
		}
		return nil
	}
	
	func typeFromURL(url: NSURL) -> String? {
		let manager = NSFileManager.defaultManager()
		var catType = "cat"
		var manType = "man"
		let attributes = try? manager.attributesOfItemAtPath((url.path! as NSString).stringByResolvingSymlinksInPath)
		var len: UInt64
		if let anAttrib = attributes {
			if let tmplen = anAttrib[NSFileSize] as? NSNumber {
				len = tmplen.unsignedLongLongValue
			} else {
				len = 0
			}
		} else {
			len = 0
		}
		let maxLength = min(150, len)
		
		if maxLength == 0 {
			return catType
		}
		
		if let handle = try? NSFileHandle(forReadingFromURL: url) {
			var fileHeader = handle.readDataOfLength(Int(maxLength))
			
			if len > 1000000 {
				return nil
			}
			
			if fileHeader.gzipData {
				let command = "/usr/bin/gzip -dc '\(EscapePath(url.path!))'"
				fileHeader = dataByExecutingCommand(command, maxLength: Int(maxLength))!
				manType = "mangz"
				catType = "catgz"
			}
			
			if fileHeader.binaryData {
				return nil
			}
			
			return fileHeader.nroffData ? manType : catType
		} else {
			return catType
		}
	}
	
	override func openDocumentWithContentsOfURL(url: NSURL, display displayDocument: Bool, completionHandler: ((NSDocument?, Bool, NSError?) -> Void)) {
		let standardizedURL = url.standardizedURL!
		var error: NSError? = nil
		let numDocuments = documents.count
		
		var document = documentForURL(standardizedURL)
		if document == nil {
			if let type = typeFromURL(standardizedURL) {
				do {
					document = try makeDocumentWithContentsOfURL(standardizedURL, ofType: type)
					document!.makeWindowControllers()
					addDocument(document!)
				} catch let anErr as NSError {
					error = anErr
				}
			}
		}
		
		let docAdded = numDocuments < documents.count
		
		if displayDocument {
			document?.showWindows()
		}
		
		completionHandler(document, !docAdded, error)
	}
	
	override func reopenDocumentForURL(urlOrNil: NSURL!, withContentsOfURL contentsURL: NSURL, display displayDocument: Bool, completionHandler: ((NSDocument?, Bool, NSError?) -> Void)) {
		openDocumentWithContentsOfURL(urlOrNil, display: displayDocument, completionHandler: completionHandler)
	}
	
	override func runModalOpenPanel(openPanel: NSOpenPanel, forTypes types: [String]?) -> Int {
		return openPanel.runModal()
	}
	
	func documentForTitle(title: String) -> NSDocument? {
		for document in documents {
			if let manDoc = document as? ManDocument {
				if document.fileURL == nil && manDoc.shortTitle == title {
					return manDoc
				}
				continue
			}
			
			if let aproposDoc = document as? AproposDocument {
				if aproposDoc.displayName == title {
					return aproposDoc
				}
			}
		}
		return nil
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		var helpPath = NSBundle.mainBundle().URLForResource("Help", withExtension: "rtf")
		if helpPath == nil {
			helpPath = NSBundle.mainBundle().URLForResource("Help", withExtension: "rtfd")
			if helpPath == nil {
				return
			}
		}
		
		(helpScrollView.contentView.documentView as! NSTextView).readRTFDFromFile(helpPath!.path!)
	}
	
	func openDocumentWithName(name: String, section: String? = nil, manPath: String) -> ManDocument? {
		var title = name
		if (section != nil && section!.isEmpty == false) {
			title = "\(name)(\(section!))"
		}
		
		var document = documentForTitle(title) as? ManDocument
		if document == nil {
			document = ManDocument(name: name, section: section, manPath: manPath, title: title)
			
			if let filename = manFileForName(name, section: section, manPath: manPath) {
				let afn = (filename as NSString).stringByResolvingSymlinksInPath
				let fileURL = NSURL(fileURLWithPath: afn)
				noteNewRecentDocumentURL(fileURL)
				document?.fileURL = fileURL
			}
			
			addDocument(document!)
			document?.makeWindowControllers()
		}
		
		document?.showWindows()
		
		return document
	}
	
	func openAproposDocument(apropos: String, manPath: String) -> AproposDocument? {
		let title = "Apropos \(apropos)"
		var document = documentForTitle(title) as? AproposDocument
		
		if document == nil {
			document = AproposDocument(string: apropos, manPath: manPath, title: title)
			
			if document != nil {
				addDocument(document!)
			}
			document?.makeWindowControllers()
		}
		
		document?.showWindows()
		
		return document
	}
	
	func openWord(word: String) -> ManDocument? {
		var base = word
		var section: String? = nil
		let lparenRange = word.rangeOfString("(")
		let rparenRange = word.rangeOfString(")")
		
		if let lparenRange = lparenRange, rparenRange = rparenRange where lparenRange.startIndex < rparenRange.startIndex {
			var lp = lparenRange
			var rp = rparenRange
			
			base = word[word.startIndex ..< lp.startIndex]
			section = word[++lp.startIndex ..< --rp.endIndex]
		}
		
		return openDocumentWithName(base, section: section, manPath: NSUserDefaults.standardUserDefaults().manPath)
	}
	
	func openString(string: String) {
		let words = getWordArray(string)
		if words.count > 20 {
			let locCount = NSNumberFormatter.localizedStringFromNumber(words.count, numberStyle: .DecimalStyle)
			let alert = NSAlert()
			alert.messageText = NSLocalizedString("Warning", comment: "Warning")
			alert.informativeText = String(format: NSLocalizedString("This will open approximately %@ windows!", comment: "This will open approximately (the number of) windows!"), locCount)
			alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: "Cancel"))
			alert.addButtonWithTitle(NSLocalizedString("Continue", comment: "Continue"))
			let aNum = alert.runModal()
			if aNum != NSAlertSecondButtonReturn {
				return
			}
		}
		
		openString(string, oneWordOnly: false)
	}
	
	func openString(string: String, oneWordOnly oneOnly: Bool) {
		let scanner = NSScanner(string: string)
		let whitespaceSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
		let nonwhitespaceSet = whitespaceSet.invertedSet
		var aWord: NSString? = nil
		var lastWord: String! = nil
		
		scanner.charactersToBeSkipped = whitespaceSet
		
		while !scanner.atEnd {
			if scanner.scanCharactersFromSet(nonwhitespaceSet, intoString: &aWord) {
				if lastWord == nil {
					if let aWord = aWord {
						lastWord = aWord as String
					}
				} else if aWord!.hasPrefix("(") && aWord!.hasSuffix(")") {
					openWord(lastWord + (aWord! as String))
					lastWord = nil
					if oneOnly {
						break
					}
				}
			}
		}
		
		if (lastWord != nil) {
			if lastWord.hasSuffix(",") {
				var lastIndex = lastWord.endIndex
				lastWord = lastWord[lastWord.startIndex..<lastIndex--]
			}
			openWord(lastWord)
		}
		
	}
	
	@IBAction func orderFrontHelpPanel(sender: AnyObject!) {
		helpPanel.makeKeyAndOrderFront(sender)
	}
	
	@IBAction func orderFrontPreferencesPanel(sender: AnyObject?) {
		PrefPanelController.sharedInstance.showWindow(sender)
	}
	
	@IBAction func runPageLayout(sender: AnyObject!) {
		NSApp.runPageLayout(sender)
	}
	
	override init() {
		super.init()
		
		/*
		* Set ourselves up for DO connections.  I do it here so it's done as
		* early as possible.  If the command-line tool still has problems
		* connecting, we may be able to do this whole thing in main()...
		*/
		
		registerNameWithRootObject("ManOpenApp", self)
		
		PrefPanelController.registerManDefaults()
		var tmpNibArray: NSArray? = nil
		NSBundle.mainBundle().loadNibNamed("DocController", owner: self, topLevelObjects: &tmpNibArray)
		
		nibObjects = tmpNibArray! as [AnyObject]
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func openTitleFromPanel() {
		var aString = openTextField.stringValue
		var words = getWordArray(aString)
		
		/* If the string is of the form "3 printf", arrange it better for our parser.  Requested by Eskimo.  Also accept 'n' as a section */
		if words.count == 2 && aString.rangeOfString("(") == nil && IsSectionWord(words[0]) {
			aString = "\(words[1])(\(words[0]))"
		}
		
		/* Append the section if chosen in the popup and not explicity defined in the string */
		if aString.characters.count > 0 && openSectionPopup.indexOfSelectedItem > 0 && aString.rangeOfString("(") == nil {
			aString += "(\(openSectionPopup.indexOfSelectedItem))"
		}
		openString(aString)
		openTextField.selectText(self)
	}
	
	@IBAction func openSection(sender: AnyObject!) {
		let aTag = sender.tag()
		if aTag == 0 {
			openApropos("") // all pages
		} else if aTag == 20 {
			openApropos("(n)")
		} else {
			openApropos("(\(aTag))")
		}
	}
	
	@IBAction func openTextPanel(sender: AnyObject!) {
		if !openTextPanel.visible {
			openSectionPopup.selectItemAtIndex(0)
		}
		openTextField.selectText(self)
		
		if useModalPanels {
			if NSApp.runModalForWindow(openTextPanel) == NSModalResponseOK {
				openTitleFromPanel()
			}
		} else {
			openTextPanel.makeKeyAndOrderFront(self)
		}
	}
	
	func openAproposFromPanel() {
		openApropos(aproposField.stringValue)
		aproposField.selectText(self)
	}
	
	@IBAction func openAproposPanel(sender: NSView!) {
		aproposField.selectText(self)
		
		if useModalPanels {
			if NSApp.runModalForWindow(aproposPanel) == NSModalResponseOK {
				openAproposFromPanel()
			}
		} else {
			aproposPanel.makeKeyAndOrderFront(self)
		}
	}
	
	@IBAction func okApropos(sender: NSView!) {
		if useModalPanels {
			sender.window?.orderOut(self)
		}
		
		if sender.window!.level == NSModalPanelWindowLevel {
			NSApp.stopModalWithCode(NSModalResponseOK)
		} else {
			openAproposFromPanel()
		}
	}
	
	@IBAction func okText(sender: NSView!) {
		if useModalPanels {
			sender.window?.orderOut(self)
		}
		
		if sender.window!.level == NSModalPanelWindowLevel {
			NSApp.stopModalWithCode(NSModalResponseOK)
		} else {
			openTitleFromPanel()
		}
	}
	
	@IBAction func cancelText(sender: NSView!) {
		sender.window?.orderOut(self)
		if sender.window!.level == NSModalPanelWindowLevel {
			NSApp.stopModalWithCode(NSModalResponseCancel)
		}
	}
}

private func IsSectionWord(word: String) -> Bool
{
	if word.isEmpty {
		return false
	}
	if NSCharacterSet.decimalDigitCharacterSet().characterIsMember((word as NSString).characterAtIndex(0)) {
		return true
	}
	if word == "n" {
		return true
	}
	return false
}

private func getWordArray(string: String) -> [String] {
	let spaceSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
	let nonspaceSet = spaceSet.invertedSet
	var wordArray = [String]()
	let scanner = NSScanner(string: string)
	
	scanner.charactersToBeSkipped = spaceSet
	
	while !scanner.atEnd {
		var aWord: NSString? = nil
		if scanner.scanCharactersFromSet(nonspaceSet, intoString: &aWord) {
			wordArray.append(aWord! as String)
		}
	}
	
	return wordArray
}

@objc(ManOpenURLHandlerCommand) class ManOpenURLHandlerCommand : NSScriptCommand {
	override func performDefaultImplementation() -> AnyObject? {
		if directParameter == nil {
			return nil
		}
		let param = directParameter as! String
		var section: String? = nil
		
		//var aTex: NSStringCompareOptions = .CaseInsensitiveSearch | .AnchoredSearch
		
		let paramRange = param.rangeOfString(URL_SCHEME_PREFIX, options: [.CaseInsensitiveSearch, .AnchoredSearch])
		var pageNames = [String]()
		
		if let aRange = paramRange {
			let path = param.substringFromIndex(aRange.endIndex)
			let components = (path as NSString).pathComponents
			
			for name in components {
				if name.characters.count == 0 || name == "" {
					continue
				}
				if IsSectionWord(name) {
					section = name
				} else {
					pageNames.append(name)
					if section != nil {
						pageNames.append("(\(section))")
						section = nil
					}
				}
			}
			
			if pageNames.count > 0 {
				(ManDocumentController.sharedDocumentController() as! ManDocumentController).openString(pageNames.joinWithSeparator(" "))
			}
		}
		
		return nil
	}
}
