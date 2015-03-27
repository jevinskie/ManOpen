//
//  AppInfo.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/10/14.
//
//

import Cocoa

func ==(lhs: ManAppInfo, rhs: ManAppInfo) -> Bool {
	let toRet = lhs.bundleID.caseInsensitiveCompare(rhs.bundleID)
	return toRet == NSComparisonResult.OrderedSame
}

func ==(lhs: ManAppInfo, rhs: String) -> Bool {
	let toRet = lhs.bundleID.caseInsensitiveCompare(rhs)
	return toRet == NSComparisonResult.OrderedSame
}

class ManAppInfo: Hashable {
	let bundleID: String
	lazy var displayName: String = {
		let url = self.appURL
		var infoDict: NSDictionary? = CFBundleCopyInfoDictionaryForURL(url)
		var preNiceName: Unmanaged<CFString>? = nil
		
		if (infoDict == nil) {
			infoDict = NSBundle(URL: url)!.infoDictionary
		}
		
		LSCopyDisplayNameForURL(url, &preNiceName)
		var niceName: String? = {
			if let aName = preNiceName?.takeRetainedValue() {
				return aName as String
			}
			
			return nil
		}()
		if (niceName == nil) {
			niceName = url.lastPathComponent
		}
		
		if let adict = infoDict {
			if let appVersion = adict["CFBundleShortVersionString"] as? String {
				niceName = "\(niceName!) (\(appVersion))"
			}
		}
		
		return niceName!
	}()
	
	lazy var appURL: NSURL = {
		let workSpace = NSWorkspace.sharedWorkspace()
		if let path = workSpace.absolutePathForAppBundleWithIdentifier(self.bundleID) {
			return NSURL(fileURLWithPath: path)!
		}
		return NSURL()
	}()
	
	func isEqual(other: AnyObject!) -> Bool {
		if let isAppInfo = other as? ManAppInfo {
			return self == isAppInfo
		} else {
			return false
		}
	}
	
	init(bundleID aBundleID: String) {
		bundleID = aBundleID
		//super.init()
	}
	
	var hashValue: Int {
		return bundleID.lowercaseString.hashValue
	}
	
	var hash: Int {
		return self.hashValue
	}
	
	func compare(string: ManAppInfo) -> NSComparisonResult {
		return displayName.compare(string.displayName, options: .CaseInsensitiveSearch | .NumericSearch)
	}
	
	func localizedStandardCompare(string: ManAppInfo) -> NSComparisonResult {
		return displayName.localizedStandardCompare(string.displayName)
	}

}
