//
//  PrefPanelController.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa
import CoreServices

let ManPathIndexSetPboardType = "org.clindberg.ManOpen.ManPathIndexSetType"
let ManPathArrayKey = "manPathArray"

let manTextColorKey = "ManTextColor"
let manLinkColorKey = "ManLinkColor"
let manBackgroundColorKey = "ManBackgroundColor"
let manFontKey = "ManFont"
let manPathKey = "ManPath"

private let URL_SCHEME = "x-man-page"
private let URL_SCHEME_PREFIX = URL_SCHEME + ":"

private func StringToCFString(string: String) -> CFString {
	return string as NSString as CFString
}

private func CFStringToString(cfString: CFString) -> String {
	return cfString as NSString as String
}

private func CFStringToString(cfString: CFString?) -> String? {
	return cfString as NSString? as String?
}

private func dataForColor(color: NSColor) -> NSData {
	return NSArchiver.archivedDataWithRootObject(color)
}

func ==(lhs: PrefPanelController.AppInfo, rhs: PrefPanelController.AppInfo) -> Bool {
	var toRet = lhs.bundleID.caseInsensitiveCompare(rhs.bundleID)
	return toRet == NSComparisonResult.OrderedSame
}

func ==(lhs: PrefPanelController.AppInfo, rhs: String) -> Bool {
	var toRet = lhs.bundleID.caseInsensitiveCompare(rhs)
	return toRet == NSComparisonResult.OrderedSame
}

private var allApps: [PrefPanelController.AppInfo] = []

class PrefPanelController: NSWindowController {

	class AppInfo: Hashable, SequenceType {
		private var internalDisplayName: String!
		private var internalAppURL: NSURL!
		@objc let bundleID: String
		@objc var displayName: String {
			get {
				if internalDisplayName == nil {
					let url = appURL
					var infoDict = CFBundleCopyInfoDictionaryForURL(url) as NSDictionary!
					var appVersion: String!
					var niceName: String!
					
					if (infoDict == nil) {
						infoDict = NSBundle(URL: url).infoDictionary
					}
					
					var niceNameRef: Unmanaged<CFString>? = nil
					LSCopyDisplayNameForURL(url, &niceNameRef);
					niceName = niceNameRef?.takeRetainedValue()
					if (niceName == nil) {
						niceName = url.lastPathComponent
					}
					
					appVersion = infoDict["CFBundleShortVersionString"] as? NSString as String
					if (appVersion != nil) {
						niceName = "\(niceName) (\(appVersion))"
					}
					
					internalDisplayName = niceName;
				}
				return internalDisplayName
			}
		}
		var appURL: NSURL {
			get {
				if internalAppURL == nil {
					var path = NSWorkspace.sharedWorkspace().absolutePathForAppBundleWithIdentifier(bundleID)
					if (path != nil) {
						internalAppURL = NSURL(fileURLWithPath: path)
					}
				}
				return internalAppURL
			}
		}

		@objc func isEqual(other: AnyObject) -> Bool {
			if let isAppInfo = other as? AppInfo {
				return self == isAppInfo
			} else {
				return false
			}
		}
		
		func generate() -> IndexingGenerator<[PrefPanelController.AppInfo]> {
			return allApps.generate()
		}
		
		init(bundleID aBundleID: String) {
			bundleID = aBundleID
		}
		
		var hashValue: Int {
			get {
				return bundleID.lowercaseString.hashValue
			}
		}
		
		@objc var hash: Int {
			get {
				return hashValue
			}
		}
		
		class var allManViewerApps: [AppInfo] {
			get {
				if (allApps.count == 0) {
					/* Ensure our app is registered
					let url = NSBundle.mainBundle().bundleURL
					LSRegisterURL(url, 0) */
					
					let allBundleIDs = LSCopyAllHandlersForURLScheme(StringToCFString(URL_SCHEME)).takeRetainedValue() as NSArray as [String]
					
					//allApps = [[NSMutableArray alloc] initWithCapacity:[allBundleIDs count]];
					for bundleID in allBundleIDs {
						addApp(ID: bundleID)
					}
					sortApps()
				}
				
				return allApps;
			}
		}
		
		class func addApp(ID id: String, sort shouldResort: Bool = false) {
			let info = AppInfo(bundleID: id)
			let contains = allApps.filter { (anObj) -> Bool in
				return anObj == info
			}
			if contains.count == 0 {
				allApps.append(info)
				if shouldResort {
					sortApps()
				}
			}
		}
		
		class func sortApps() {
			allApps.sort { (lhs, rhs) -> Bool in
				let toRet = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
				return NSComparisonResult.OrderedAscending == toRet
			}
		}
		
		class func indexOfBundleID(bundleID: String!) -> Int? {
			if bundleID == nil {
				return nil;
			}
			
			for (i, obj) in enumerate(allApps) {
				if obj == bundleID {
					return i
				}
			}
			
			return nil
		}

	}
	
	private var manPathArrayPriv = [String]()
	dynamic var manPathArray: [String] {
		get {
			if manPathArrayPriv.count == 0 {
				var path = NSUserDefaults.standardUserDefaults().manPath
				manPathArrayPriv = path.componentsSeparatedByString(":")
			}
			return manPathArrayPriv
		}
		set {
			manPathArrayPriv = newValue
			saveManPath()
		}
	}
	private var currentAppID = ""
	@IBOutlet weak var manPathController: NSArrayController!
	@IBOutlet weak var manPathTableView: NSTableView!
	@IBOutlet weak var fontField: NSTextField!
	@IBOutlet weak var generalSwitchMatrix: NSMatrix!
	@IBOutlet weak var appPopup: NSPopUpButton!
	
	class func registerManDefaults() {
		let userDefaults = NSUserDefaults.standardUserDefaults()
		let manager = NSFileManager.defaultManager()
		let nroff = "nroff -mandoc '%@'"
		var manpath = "/usr/local/man:/usr/share/man"
		
		
		if manager.fileExistsAtPath("/sw/share/man") { // fink
			manpath = "/sw/share/man:" + manpath
	}
		if manager.fileExistsAtPath("/opt/local/share/man") {  //macports
			manpath = "/opt/local/share/man:" + manpath
		}
		if manager.fileExistsAtPath("/opt/X11/share/man") {
			manpath += ":/opt/X11/share/man"
		} else if manager.fileExistsAtPath("/usr/X11/share/man") {
			manpath += ":/usr/X11/share/man"
		} else if manager.fileExistsAtPath("/usr/X11R6/man") {
		manpath += ":/usr/X11R6/man"
		}

		
		let linkDefaultColor = dataForColor(NSColor(SRGBRed: 0.10, green: 0.10, blue: 1.0, alpha: 1.0))
		let textDefaultColor = dataForColor(NSColor.textColor())
		let bgDefaultColor = dataForColor(NSColor.textBackgroundColor())
		
		let someDefaults = ["QuitWhenLastClosed": false,
		"UseItalics": false,
		"UseBold": true,
		"NroffCommand": nroff,
		manPathKey: manpath,
		"KeepPanelsOpen": false,
		manTextColorKey: textDefaultColor,
		manLinkColorKey: linkDefaultColor,
		manBackgroundColorKey: bgDefaultColor,
		"NSQuitAlwaysKeepsWindows": true]
		
		userDefaults.registerDefaults(someDefaults)
	}
	
	private var fontFieldFont: NSFont! {
		get {
			return fontField.font
		}
		set {
			if newValue == nil {
				return;
			}
			fontField.font = newValue
			fontField.stringValue = String(format: "%@ %.1f", newValue.familyName, Double(newValue.pointSize))
		}
	}
	
    override func windowDidLoad() {
		self.shouldCascadeWindows = false
		NSFontManager.sharedFontManager().delegate = self
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

	@IBAction func openFontPanel(sender: AnyObject!) {
		self.window.makeFirstResponder(nil)
		NSFontManager.sharedFontManager().setSelectedFont(fontField.font, isMultiple: false)
		NSFontPanel.sharedFontPanel().orderFront(sender)
	}
	
	override func fontManager(sender: AnyObject!, willIncludeFont fontName: String!) -> Bool {
		return sender.fontNamed(fontName, hasTraits: NSFontTraitMask.FixedPitchFontMask)
	}
	
	override func changeFont(sender: AnyObject!) {
		var font = fontFieldFont;
		//NSString *fontString;
		
		font = sender.convertFont(font)
		self.fontFieldFont = font
		let fontString = "\(font.pointSize) \(font.fontName)"
		NSUserDefaults.standardUserDefaults().setObject(fontString, forKey: manFontKey)
	}
	
	override func validateMenuItem(menuItem: NSMenuItem!) -> Bool {
		let action = menuItem.action
		if ((action == "cut:") || (action == "copy:") || (action == "delete:")) {
			return manPathController.canRemove
		}
		
		if action == "paste:" {
			let types: NSArray! = NSPasteboard.generalPasteboard().types
			return manPathController.canInsert &&
				(types.containsObject(NSFilenamesPboardType) || types.containsObject(NSStringPboardType));
		}
		
		/* The menu on our app popup may call this validate method ;-) */
		if action == "chooseNewApp" {
			return true;
		}

		return false
	}
	
	// MARK: DefaultManApp
	
	func setAppPopupToCurrent() {
		var currIndex = AppInfo.indexOfBundleID(currentAppID)
		
		if (currIndex == nil) {
			currIndex = 0;
		}
		
		if currIndex! < appPopup.numberOfItems {
			appPopup.selectItemAtIndex(currIndex!)
		}
	}
	
	func resetAppPopup()  {
		let apps = AppInfo.allManViewerApps
		let workspace = NSWorkspace.sharedWorkspace()
		var i = 0
		
		appPopup.removeAllItems()
		appPopup.image = nil
		
		for (i, info) in enumerate(allApps) {
			var image = workspace.iconForFile(info.appURL.path).copy() as NSImage
			var niceName = info.displayName
			var displayName = niceName
			var num = 2
			
			appPopup.addItemWithTitle(displayName)
			
			image.size = NSSize(width: 16, height: 16)
			appPopup.itemAtIndex(i).image = image
		}
	
		if apps.count > 0 {
			appPopup.menu.addItem(NSMenuItem.separatorItem())
		}
		appPopup.addItemWithTitle("Select…")
		setAppPopupToCurrent()
	}

	func resetCurrentApp() {
		var currSetID = CFStringToString((LSCopyDefaultHandlerForURLScheme(StringToCFString(URL_SCHEME)) as Unmanaged<CFString>?)?.takeRetainedValue())
		
		if (currSetID == nil) {
			currSetID = allApps[0].bundleID
		}
		
		if (currSetID != nil) {
			var resetPopup = (currentAppID == "") //first time
			
			currentAppID = currSetID!
			
			if AppInfo.indexOfBundleID(currSetID) == nil {
				AppInfo.addApp(ID: currSetID!, sort: true)
				resetPopup = true
			}
			if (resetPopup) {
				resetAppPopup()
			} else {
				setAppPopupToCurrent()
			}
		}
	}
	
	func setManPageViewer(bundleID: String) {
		let error = LSSetDefaultHandlerForURLScheme(StringToCFString(URL_SCHEME), StringToCFString(bundleID))
		
		if (error != noErr){
			println("Could not set default \(URL_SCHEME_PREFIX) app: Launch Services error \(error)")
		}
		
		resetCurrentApp()
	}
	
	@IBAction func chooseNewApp(sender: AnyObject!) {
		let apps = AppInfo.allManViewerApps
		let choice = appPopup.indexOfSelectedItem
		
		if choice >= 0 && choice < allApps.count {
			let info = allApps[choice]
			if info.bundleID != currentAppID {
				setManPageViewer(info.bundleID)
			}
		} else {
			let panel = NSOpenPanel()
			panel.treatsFilePackagesAsDirectories = false
			panel.allowsMultipleSelection = false
			panel.resolvesAliases = true
			panel.canChooseFiles = true
			panel.allowedFileTypes = [CFStringToString(kUTTypeApplicationBundle!)]
			panel.beginSheetModalForWindow(appPopup.window!) { (result) -> Void in
				if (result == NSOKButton) {
					let appURL = panel.URL
					var appID = NSBundle(URL: appURL).bundleIdentifier
					if (appID != nil) {
						self.setManPageViewer(appID!)
					}
				}
				self.setAppPopupToCurrent()
			}
		}
	}
	
	// MARK: man paths

	func setUpManPathUI() {
		manPathTableView.registerForDraggedTypes([NSFilenamesPboardType, NSStringPboardType, ManPathIndexSetPboardType])
		manPathTableView.verticalMotionCanBeginDrag = true
		// XXX NSDragOperationDelete -- not sure the "poof" drag can show that
		manPathTableView.setDraggingSourceOperationMask(.Copy, forLocal: false)
		manPathTableView.setDraggingSourceOperationMask(.Copy | .Move | .Private, forLocal: true)
	}

	func saveManPath() {
		if manPathArray.count > 0 {
			NSUserDefaults.standardUserDefaults().setObject((manPathArray as NSArray).componentsJoinedByString(":"), forKey: manPathKey)
		}
	}
	
	@IBAction func addPathFromPanel(sender: AnyObject!) {
		let panel = NSOpenPanel()
	}
	
}
