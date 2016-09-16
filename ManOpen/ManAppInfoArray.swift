//
//  ManAppInfoArray.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/10/14.
//
//

import Cocoa

private func GenerateManInfos() -> [ManAppInfo] {
	var anAppInfo = [ManAppInfo]()
	let allBundleIDs = LSCopyAllHandlersForURLScheme(URL_SCHEME as CFString)?.takeRetainedValue() as? [String]
	
	if let allBundleIDs = allBundleIDs {
		for bundleID in allBundleIDs {
			anAppInfo.append(ManAppInfo(bundleID: bundleID))
		}
	}
	return anAppInfo
}

final class ManAppInfoArray: NSObject, Sequence {
	fileprivate(set) var allManViewerApps = GenerateManInfos()
	override init() {
		super.init()
		
		sortApps()
	}
	
	var count: Int {
		return allManViewerApps.count
	}
	
	func makeIterator() -> IndexingIterator<[ManAppInfo]> {
		return allManViewerApps.makeIterator();
	}
	
	subscript(location: Int) -> ManAppInfo {
		return allManViewerApps[location]
	}
	
	func addApp(ID id: String, shouldResort sort: Bool = false) {
		let info = ManAppInfo(bundleID: id)
		let contains = allManViewerApps.filter { (anObj) -> Bool in
			return anObj == info
		}
		if contains.count == 0 {
			allManViewerApps.append(info)
			if sort {
				sortApps()
			}
		}
	}
	
	func sortApps() {
		allManViewerApps.sort { (lhs, rhs) -> Bool in
			let toRet = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
			return ComparisonResult.orderedAscending == toRet
		}
	}
	
	func indexOfBundleID(_ bundleID: String!) -> Int? {
		if bundleID == nil {
			return nil;
		}
		
		for (i, obj) in allManViewerApps.enumerated() {
			if obj == bundleID {
				return i
			}
		}
		
		return nil
	}
}
