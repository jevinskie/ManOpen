//
//  AppInfo.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/10/14.
//
//

import Cocoa

func ==(lhs: ManAppInfo, rhs: ManAppInfo) -> Bool {
	var toRet = lhs.bundleID.caseInsensitiveCompare(rhs.bundleID)
	return toRet == NSComparisonResult.OrderedSame
}

func ==(lhs: ManAppInfo, rhs: String) -> Bool {
	var toRet = lhs.bundleID.caseInsensitiveCompare(rhs)
	return toRet == NSComparisonResult.OrderedSame
}

class ManAppInfo: NSObject, Hashable {
	private var internalDisplayName: String? = nil
	private var internalAppURL: NSURL? = nil
	let bundleID: String
	var displayName: String {
		get {
			if internalDisplayName == nil {
				let url = appURL
				var infoDict = CFBundleCopyInfoDictionaryForURL(url) as NSDictionary?
				var appVersion: String?
				var niceName: String?
				
				if (infoDict == nil) {
					infoDict = NSBundle(URL: url).infoDictionary
				}
				
				niceName = MODisplayNameForURL(url)
				if (niceName == nil) {
					niceName = url.lastPathComponent
				}
				
				if let adict = infoDict {
					appVersion = adict["CFBundleShortVersionString"] as? String
				}
				if appVersion != nil {
					niceName = "\(niceName) (\(appVersion))"
				}
				
				internalDisplayName = niceName;
			}
			return internalDisplayName!
		}
	}
	var appURL: NSURL {
		get {
			if internalAppURL == nil {
				let workSpace = NSWorkspace.sharedWorkspace()
				var path = workSpace.absolutePathForAppBundleWithIdentifier(bundleID) as String?
				if (path != nil) {
					internalAppURL = NSURL(fileURLWithPath: path!)
				}
			}
			return internalAppURL!
		}
	}
	
	override func isEqual(other: AnyObject!) -> Bool {
		if let isAppInfo = other as? ManAppInfo {
			return self == isAppInfo
		} else {
			return false
		}
	}
	
	init(bundleID aBundleID: String) {
		bundleID = aBundleID
		super.init()
	}
	
	override var hashValue: Int {
		get {
			return bundleID.lowercaseString.hashValue
		}
	}
	
	override var hash: Int {
		get {
			return hashValue
		}
	}
}

