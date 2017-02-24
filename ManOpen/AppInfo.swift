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
	return toRet == ComparisonResult.orderedSame
}

func ==(lhs: ManAppInfo, rhs: String) -> Bool {
	let toRet = lhs.bundleID.caseInsensitiveCompare(rhs)
	return toRet == ComparisonResult.orderedSame
}

final class ManAppInfo: Hashable {
	let bundleID: String
	private(set) lazy var displayName: String = {
		let url = self.appURL
		var infoDict: NSDictionary? = CFBundleCopyInfoDictionaryForURL(url as NSURL)
		
		if infoDict == nil {
			infoDict = Bundle(url: url)!.infoDictionary as NSDictionary?
		}
		
		var niceName: String = {
			do {
				let resVals = try url.resourceValues(forKeys: [.localizedNameKey])
				if let aNiceStr = resVals.localizedName {
					return aNiceStr
				}
			} catch _ {}
			
			return url.lastPathComponent
			}()
		
		if let adict = infoDict, let appVersion = adict["CFBundleShortVersionString"] as? String {
			niceName = "\(niceName) (\(appVersion))"
		}
		
		return niceName
		}()
	
	private(set) lazy var appURL: URL = {
		let workSpace = NSWorkspace.shared()
		let path = workSpace.absolutePathForApplication(withBundleIdentifier: self.bundleID)!
		return URL(fileURLWithPath: path)
		}()
	
	func isEqual(_ other: AnyObject!) -> Bool {
		if let isAppInfo = other as? ManAppInfo {
			return self == isAppInfo
		} else if let isString = other as? String {
			return self == isString
		} else {
			return false
		}
	}
	
	init?(bundleID aBundleID: String) {
		bundleID = aBundleID
		
		let workSpace = NSWorkspace.shared()
		if workSpace.absolutePathForApplication(withBundleIdentifier: aBundleID) == nil {
			return nil
		}
	}
	
	var hashValue: Int {
		return bundleID.lowercased().hashValue
	}
	
	var hash: Int {
		return self.hashValue
	}
	
	func compare(_ string: ManAppInfo) -> ComparisonResult {
		return displayName.compare(string.displayName, options: [.caseInsensitive, .numeric])
	}
	
	func localizedStandardCompare(_ string: ManAppInfo) -> ComparisonResult {
		return displayName.localizedStandardCompare(string.displayName)
	}
}
