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

let ManTextColor = "ManTextColor"
let ManLinkColor = "ManLinkColor"
let ManBackgroundColor = "ManBackgroundColor"
let ManFont = "ManFont"
let ManPath = "ManPath"

private func ColorForKey(key: String, defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) -> NSColor? {
	let colorData = defaults.dataForKey(key)
	
	if (colorData == nil) {
		return nil;
	}
	
	return NSUnarchiver.unarchiveObjectWithData(colorData!) as NSColor?
}


func ==(lhs: PrefPanelController.AppInfo, rhs: PrefPanelController.AppInfo) -> Bool {
	var toRet = lhs.bundleID.caseInsensitiveCompare(rhs.bundleID)
	return toRet == NSComparisonResult.OrderedSame
}

class PrefPanelController: NSWindowController {

	class AppInfo: Hashable {
		private var internalDisplayName: String!
		private var internalAppURL: NSURL!
		var bundleID: String
		var displayName: String {
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

		init(bundleID aBundleID: String) {
			bundleID = aBundleID
		}
		
		var hashValue: Int {
			get {
				return bundleID.lowercaseString.hashValue
			}
		}
	}
	
	dynamic var manPathArray = [String]()
	@IBOutlet weak var manPathController: NSArrayController!
	@IBOutlet weak var manPathTableView: NSTableView!
	@IBOutlet weak var fontField: NSTextField!
	@IBOutlet weak var generalSwitchMatrix: NSMatrix!
	@IBOutlet weak var appPopup: NSPopUpButton!

	
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
