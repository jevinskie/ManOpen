//
//  PrefPanelController.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa
import CoreServices

let ManPathIndexSetPboardType = "org.clindberg.ManOpen.ManPathIndexSetType";
let ManPathArrayKey = "manPathArray";

let manTextColor = "ManTextColor"
let manLinkColor = "ManLinkColor"
let manBackgroundColor = "ManBackgroundColor"
let manFont = "ManFont"
let manPath = "ManPath"

private let URL_SCHEME = "x-man-page"
private let URL_SCHEME_PREFIX = URL_SCHEME + ":"


func ==(lhs: PrefPanelController.AppInfo, rhs: PrefPanelController.AppInfo) -> Bool {
	var toRet = lhs.bundleID.caseInsensitiveCompare(rhs.bundleID)
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
		NSURL *url = [[NSBundle mainBundle] bundleURL];
		LSRegisterURL(BRIDGE(CFURLRef,url), false); */
		
		let allBundleIDs = LSCopyAllHandlersForURLScheme(URL_SCHEME as NSString as CFString).takeRetainedValue() as NSArray as [String]
		
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
	}
	
	dynamic var manPathArray = [String]()
	private var currentAppID = ""
	@IBOutlet weak var manPathController: NSArrayController!
	@IBOutlet weak var manPathTableView: NSTableView!
	@IBOutlet weak var fontField: NSTextField!
	@IBOutlet weak var generalSwitchMatrix: NSMatrix!
	@IBOutlet weak var appPopup: NSPopUpButton!
	
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
		NSUserDefaults.standardUserDefaults().setObject(fontString, forKey: manFont)
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
}
