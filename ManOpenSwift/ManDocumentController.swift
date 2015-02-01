//
//  ManDocumentController.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa

private let MAN_BINARY = "/usr/bin/man"
//#define MANPATH_FORMAT @" -m '%@'"  // There's a bug in man(1) on OSX and OSXS
private let MANPATH_FORMAT = " -M '%@'"

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
		if NSApplication.sharedApplication().active {
			NSApplication.sharedApplication().activateIgnoringOtherApps(true)
		}
	}
	
	func openName(name: String!, section: String? = nil, manPath: String! = NSUserDefaults.standardUserDefaults().manPath, forceToFront force: Bool = true) {
		if force {
			ensureActive()
		}
		openDocumentWithName(name, section: section, manPath: manPath)
	}
	
	func openApropos(apropos: String!, manPath: String! = NSUserDefaults.standardUserDefaults().manPath, forceToFront force: Bool = true) {
		if force {
			ensureActive()
		}

		openAproposDocument(apropos, manPath: manPath)
	}
	
	@objc func openFile(filename: String!, forceToFront force: Bool = true) {
		if force {
			ensureActive()
		}
		
		openDocumentWithContentsOfURL(NSURL(fileURLWithPath: filename)!, display: true) { (doc, wasOpened, error) -> Void in
			//What to do??
		}
	}
	
	func applicationDidFinishLaunching(notification: NSNotification!) {
		(NSApp as NSApplication).servicesProvider = self
		openTextPanel.setFrameUsingName("OpenTitlePanel")
		openTextPanel.setFrameAutosaveName("OpenTitlePanel")
		aproposPanel.setFrameUsingName("AproposPanel")
		aproposPanel.setFrameAutosaveName("AproposPanel")
		
		startedUp = true
	}
	
	func applicationShouldOpenUntitledFile(sender: NSApplication!) -> Bool {
		if startedUp {
			return NSUserDefaults.standardUserDefaults().boolForKey("OpenPanelWhenNoWindows")
		} else {
			return NSUserDefaults.standardUserDefaults().boolForKey("OpenPanelOnStartup")
		}
	}
	
	func applicationOpenUntitledFile(sender: NSApplication!) -> Bool {
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
		var autoQuit = NSUserDefaults.standardUserDefaults().boolForKey("QuitWhenLastClosed")
		
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
		
		if (manPath != nil && !(manPath!.isEmpty)) {
			command += " -M '\(EscapePath(manPath!))'"
		}
		
		return command
	}
	
	func dataByExecutingCommand(command: String, maxLength: Int = 0, extraEnv: NSDictionary? = nil) -> NSData? {
		var pipe = NSPipe()
		var task = NSTask()
		var output: NSData
		
		if extraEnv != nil {
			var environment = NSProcessInfo.processInfo().environment
			environment += extraEnv!
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
			output = pipe.fileHandleForReading.readDataToEndOfFileIgnoreInterrupt()
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
		var data = dataByExecutingCommand(command)
		if data != nil && data?.length > 0 {
			let manager = NSFileManager.defaultManager()
			var len = data!.length
			let ptr = data!.bytes
			var tmpNewline = "\n"
			var tmpnewnewline: [CChar] = tmpNewline.cStringUsingEncoding(NSASCIIStringEncoding)!
			var tmpanotherNewline: Int8 = tmpnewnewline[0]
			
			var newlinePtr = memchr(ptr, Int32(tmpanotherNewline), UInt(len))
			
			if newlinePtr != nil {
				len = ptr.distanceTo(newlinePtr)
			}
			
			var filename = manager.stringWithFileSystemRepresentation(UnsafePointer<Int8>(ptr), length: len)
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
		var attributes = manager.attributesOfItemAtPath(url.path!.stringByResolvingSymlinksInPath, error: nil)
		var len: UInt64
		if let anAttrib = attributes {
			let tmplen: AnyObject? = anAttrib[NSFileSize]
			if let aTmp: AnyObject = tmplen {
				len = (aTmp as NSNumber).unsignedLongLongValue
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
		
		if let handle = NSFileHandle(forReadingFromURL: url, error: nil) {
			var fileHeader = handle.readDataOfLength(Int(maxLength))
			
			if len > 1000000 {
				return nil
			}
			
			if fileHeader.gzipData {
				var command = "/usr/bin/gzip -dc '\(EscapePath(url.path!))'"
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
	
	override func openDocumentWithContentsOfURL(url: NSURL, display displayDocument: Bool, completionHandler: ((NSDocument!, Bool, NSError!) -> Void)) {
		let standardizedURL = url.standardizedURL!
		var error: NSError? = nil
		let numDocuments = documents.count
		
		var document = documentForURL(standardizedURL) as NSDocument?
		if document == nil {
			var atype = typeFromURL(standardizedURL)
			if let type = atype {
				document = makeDocumentWithContentsOfURL(standardizedURL, ofType: type, error: &error) as NSDocument?
				document?.makeWindowControllers()
				addDocument(document!)
			}
		}
		
		let docAdded = numDocuments < documents.count

		completionHandler(document, !docAdded, error)
	}
	
	override func reopenDocumentForURL(urlOrNil: NSURL!, withContentsOfURL contentsURL: NSURL, display displayDocument: Bool, completionHandler: ((NSDocument!, Bool, NSError!) -> Void)) {
		openDocumentWithContentsOfURL(urlOrNil, display: displayDocument, completionHandler: completionHandler)
	}
	
	override func runModalOpenPanel(openPanel: NSOpenPanel, forTypes types: [AnyObject]) -> Int {
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
		
		(helpScrollView.contentView.documentView as NSTextView).readRTFDFromFile(helpPath!.path!)
	}
	
	func openDocumentWithName(name: String, section: String? = nil, manPath: String) -> ManDocument? {
		var document: ManDocument? = nil
		var title = name
		if (section != nil && section!.isEmpty == false) {
			title = "\(name)(\(section!))"
		}
		
		document = documentForTitle(title) as? ManDocument
		if document == nil {
			
			document = ManDocument(name: name, section: section, manPath: manPath, title: title)
			
			if let filename = manFileForName(name, section: section, manPath: manPath) {
				let fileURL = NSURL(fileURLWithPath: filename)!
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
		var title = "Apropos \(apropos)"
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
		var document: ManDocument? = nil
		
		/*
		if (lparenRange.length != 0 && rparenRange.length != 0 &&
			lparenRange.location < rparenRange.location)
		{
			NSRange sectionRange;
			
			sectionRange.location = NSMaxRange(lparenRange);
			sectionRange.length = rparenRange.location - sectionRange.location;
			
			base = [word substringToIndex:lparenRange.location];
			section = [word substringWithRange:sectionRange];
		}
*/
		
		document = openDocumentWithName(base, section: section, manPath: NSUserDefaults.standardUserDefaults().manPath)
		
		return document
	}
	
	func openString(string: String) {
		var words = GetWordArray(string)
		if words.count > 20 {
			let alert = NSAlert()
			
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
					lastWord = aWord
				} else if aWord!.hasPrefix("(") && aWord!.hasSuffix(")") {
					openWord(lastWord + aWord!)
					lastWord = nil
					if oneOnly {
						break
					}
				}
			}
		}
	}

	@IBAction func orderFrontHelpPanel(sender: AnyObject!) {
		helpPanel.makeKeyAndOrderFront(sender)
	}
	
	@IBAction func orderFrontPreferencesPanel(sender: AnyObject?) {
		PrefPanelController.sharedInstance.showWindow(sender)
	}

	@IBAction func runPageLayout(sender: AnyObject!) {
		(NSApp as NSApplication).runPageLayout(sender)
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
		
		nibObjects = tmpNibArray!
	}

	required init(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	class func escapePath(path: String, addSurroundingQuotes addQuotes: Bool) -> String {
		return EscapePath(path, addSurroundingQuotes: addQuotes)
	}
	
	@IBAction func openSection(sender: AnyObject!) {
		
	}
	
	@IBAction func openTextPanel(sender: AnyObject!) {
		
	}
	
	@IBAction func openAproposPanel(sender: AnyObject!) {
		
	}
	
	@IBAction func okApropos(sender: AnyObject!) {
		
	}
	
	@IBAction func okText(sender: AnyObject!) {
		
	}
	
	@IBAction func cancelText(sender: AnyObject!) {
		
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

private func GetWordArray(string: String) -> [String] {
	let spaceSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
	let nonspaceSet = spaceSet.invertedSet
	var wordArray = [String]()
	let scanner = NSScanner(string: string)
	
	scanner.charactersToBeSkipped = spaceSet
	
	while !scanner.atEnd {
		var aWord: NSString? = nil
		if scanner.scanCharactersFromSet(nonspaceSet, intoString: &aWord) {
			wordArray.append(aWord!)
		}
	}
	
	return wordArray
}

@objc(ManOpenURLHandlerCommand) class ManOpenURLHandlerCommand : NSScriptCommand {
	override func performDefaultImplementation() -> AnyObject? {
		if directParameter == nil {
			return nil
		}
		let param = directParameter as String
		var section: String? = nil
		
		//var aTex: NSStringCompareOptions = .CaseInsensitiveSearch | .AnchoredSearch
		
		var paramRange = param.rangeOfString(URL_SCHEME_PREFIX, options: .CaseInsensitiveSearch | .AnchoredSearch)
		var pageNames = [String]()
		
		if let aRange = paramRange {
			let path = param.substringFromIndex(aRange.endIndex)
			var components = path.pathComponents
			
			for name in components {
				if countElements(name) == 0 || name == "" {
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
				(ManDocumentController.sharedDocumentController() as ManDocumentController).openString(join(" ", pageNames))
			}
		}
		
		return nil
	}
}
