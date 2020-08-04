//
//  ManAppInfoArray.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/10/14.
//
//

import Cocoa

private func generateManInfos() -> [ManAppInfo] {
	var anAppInfo = [ManAppInfo]()
	guard let allBundleIDs = LSCopyAllHandlersForURLScheme(URL_SCHEME as NSString)?.takeRetainedValue() as? [String] else {
		return []
	}
	anAppInfo.reserveCapacity(allBundleIDs.count)
	
	for bundleID in allBundleIDs {
		if let mai = ManAppInfo(bundleID: bundleID) {
			anAppInfo.append(mai)
		}
	}
	
	return anAppInfo
}

final class ManAppInfoArray: Sequence {
	private(set) var allManViewerApps = generateManInfos()
	
	init() {
		sortApps()
	}
	
	var count: Int {
		return allManViewerApps.count
	}
	
	func makeIterator() -> IndexingIterator<[ManAppInfo]> {
		return allManViewerApps.makeIterator()
	}
	
	subscript(location: Int) -> ManAppInfo {
		return allManViewerApps[location]
	}
	
	func addApp(identifier id: String, shouldResort sort: Bool = false) {
		guard let info = ManAppInfo(bundleID: id) else {
			//NSBeep()
			//return
			fatalError("Could not find application with bundle identifier \"\(id)\"")
		}
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
	
	private func sortApps() {
		allManViewerApps.sort { (lhs, rhs) -> Bool in
			let toRet = lhs.localizedCaseInsensitiveCompare(rhs)
			return toRet == .orderedAscending
		}
	}
	
	func index(bundleID: String?) -> Int? {
		guard let bundleID = bundleID else {
			return nil
		}
		
		for (i, obj) in allManViewerApps.enumerated() {
			if obj == bundleID {
				return i
			}
		}
		
		return nil
	}
}
