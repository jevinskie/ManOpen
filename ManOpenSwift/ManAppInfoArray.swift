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
	let allBundleIDs = LSCopyAllHandlersForURLScheme(URL_SCHEME).takeRetainedValue() as [String]

	for bundleID in allBundleIDs {
		anAppInfo.append(ManAppInfo(bundleID: bundleID))
	}
	return anAppInfo
}

class ManAppInfoArray: NSObject, SequenceType {
	private(set) var allManViewerApps = GenerateManInfos()
		
	override init() {
		super.init()
		
		sortApps()
	}
	
	var count: Int {
		return allManViewerApps.count
	}
	
	func generate() -> IndexingGenerator<[ManAppInfo]> {
		return allManViewerApps.generate();
	}

	subscript(location: Int) -> ManAppInfo {
		return allManViewerApps[location]
	}
		
	func addApp(ID id: String, sort shouldResort: Bool = false) {
		let info = ManAppInfo(bundleID: id)
		let contains = allManViewerApps.filter { (anObj) -> Bool in
			return anObj == info
		}
		if contains.count == 0 {
			allManViewerApps.append(info)
			if shouldResort {
				sortApps()
			}
		}
	}
	
	func sortApps() {
		allManViewerApps.sort { (lhs, rhs) -> Bool in
			let toRet = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
			return NSComparisonResult.OrderedAscending == toRet
		}
	}
	
	func indexOfBundleID(bundleID: String!) -> Int? {
		if bundleID == nil {
			return nil;
		}
		
		for (i, obj) in enumerate(allManViewerApps) {
			if obj == bundleID {
				return i
			}
		}
		
		return nil
	}
}
