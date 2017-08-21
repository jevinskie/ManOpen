//
//  PrefPanelController.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/8/14.
//
//

import Cocoa
import CoreServices


let ManPathIndexSetPboardType = NSPasteboard.PasteboardType(rawValue: "org.clindberg.ManOpen.ManPathIndexSetType")
let ManPathArrayKey = "manPathArray"

let URL_SCHEME = "x-man-page"
let URL_SCHEME_PREFIX = URL_SCHEME + ":"

let kUseItalics			= "UseItalics"
let kUseBold			= "UseBold"
let kKeepPanelsOpen		= "KeepPanelsOpen"
let kQuitWhenLastClosed	= "QuitWhenLastClosed"
let kNroffCommand		= "NroffCommand"


class PrefPanelController: NSWindowController, NSTableViewDataSource {

	static let shared: PrefPanelController = {
		let toRet = PrefPanelController(windowNibName: NSNib.Name(rawValue: "PrefPanel"))
		toRet.shouldCascadeWindows = false
		NSFontManager.shared.delegate = toRet
		
		return toRet
	}()
	
	let appInfos = ManAppInfoArray()
	fileprivate var manPathArrayPriv = [String]()
	@objc dynamic var manPathArray: [String] {
		get {
			if manPathArrayPriv.count == 0 {
				let path = UserDefaults.standard.manPath
				manPathArrayPriv = path.components(separatedBy: ":")
			}
			return manPathArrayPriv
		}
		set {
			manPathArrayPriv = newValue
			saveManPath()
		}
	}
	fileprivate var currentAppID = ""
	@IBOutlet weak var manPathController: NSArrayController!
	@IBOutlet weak var manPathTableView: NSTableView!
	@IBOutlet weak var fontField: NSTextField!
	@IBOutlet weak var generalSwitchMatrix: NSMatrix!
	@IBOutlet weak var appPopup: NSPopUpButton!
	
	class func registerManDefaults() {
		let userDefaults = UserDefaults.standard
		let manager = FileManager.default
		let nroff = "nroff -mandoc '%@'"
		var manpath = "/usr/local/man:/usr/local/share/man:/usr/share/man"
		
		
		if manager.fileExists(atPath: "/sw/share/man") { // fink
			manpath = "/sw/share/man:" + manpath
		}
		if manager.fileExists(atPath: "/opt/local/share/man") {  //macports
			manpath = "/opt/local/share/man:" + manpath
		}
		if manager.fileExists(atPath: "/opt/X11/share/man") {
			manpath += ":/opt/X11/share/man"
		} else if manager.fileExists(atPath: "/usr/X11/share/man") {
			manpath += ":/usr/X11/share/man"
		} else if manager.fileExists(atPath: "/usr/X11R6/man") {
			manpath += ":/usr/X11R6/man"
		}

		
		let linkDefaultColor = dataForColor(NSColor(srgbRed: 0.10, green: 0.10, blue: 1.0, alpha: 1.0))
		let textDefaultColor = dataForColor(NSColor.textColor)
		let bgDefaultColor = dataForColor(NSColor.textBackgroundColor)
		
		let someDefaults: [String : Any] = [kQuitWhenLastClosed:	false,
		                                    kUseItalics:			false,
		                                    kUseBold:				true,
		                                    kNroffCommand:			nroff,
		                                    manPathKey:				manpath,
		                                    kKeepPanelsOpen:		false,
		                                    manTextColorKey:		textDefaultColor,
		                                    manLinkColorKey:		linkDefaultColor,
		                                    manBackgroundColorKey:	bgDefaultColor,
		                                    "NSQuitAlwaysKeepsWindows":	true]
		
		userDefaults.register(defaults: someDefaults)
		NSUserDefaultsController.shared.initialValues = someDefaults
	}
	
	fileprivate var fontFieldFont: NSFont! {
		get {
			return fontField.font
		}
		set {
			if newValue == nil {
				return;
			}
			fontField.font = newValue
			fontField.stringValue = String(format: "%@ %.1f", newValue.familyName!, newValue.pointSize)
		}
	}
	
	fileprivate func setUpDefaultManViewerApp() {
		resetCurrentApp()
	}
	
    override func windowDidLoad() {
		self.shouldCascadeWindows = false
		NSFontManager.shared.delegate = self
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		
		setUpDefaultManViewerApp()
		setUpManPathUI()
		fontFieldFont = UserDefaults.standard.manFont
    }

	@IBAction func openFontPanel(_ sender: AnyObject!) {
		self.window?.makeFirstResponder(nil)
		NSFontManager.shared.setSelectedFont(fontField.font!, isMultiple: false)
		NSFontPanel.shared.orderFront(sender)
	}
	
	override func fontManager(_ sender: Any, willIncludeFont fontName: String) -> Bool {
		return (sender as! NSFontManager).fontNamed(fontName, hasTraits: .fixedPitchFontMask)
	}
	
	override func changeFont(_ sender: Any!) {
		var font = fontFieldFont
		//NSString *fontString;
		
		font = (sender as! NSFontManager).convert(font!)
		self.fontFieldFont = font
		if let font = font {
			let fontString = "\(font.pointSize) \(font.fontName)"
			UserDefaults.standard[manFontKey] = fontString
		}
	}
	
	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		let action = menuItem.action
		if ((action == #selector(PrefPanelController.cut(_:))) || (action == #selector(PrefPanelController.copy(_:))) || (action == #selector(PrefPanelController.delete(_:)))) {
			return manPathController.canRemove
		}
		
		if action == #selector(PrefPanelController.paste(_:)) {
			let types = NSPasteboard.general.types!
			return manPathController.canInsert &&
				(types.contains(ourFile) || types.contains(.string))
		}
		
		/* The menu on our app popup may call this validate method ;-) */
		if action == #selector(PrefPanelController.chooseNewApp(_:)) {
			return true;
		}

		return false
	}
	
	// MARK: DefaultManApp
	
	func setAppPopupToCurrent() {
		let currIndex = appInfos.index(bundleID: currentAppID) ?? 0
		
		if currIndex < appPopup.numberOfItems {
			appPopup.selectItem(at: currIndex)
		}
	}
	
	func resetAppPopup()  {
		let apps = appInfos.allManViewerApps
		let workspace = NSWorkspace.shared
		//var i = 0
		
		appPopup.removeAllItems()
		appPopup.image = nil
		
		for (i, info) in appInfos.enumerated() {
			let image = workspace.icon(forFile: info.appURL.path).copy() as! NSImage
			let niceName = info.displayName
			let displayName = niceName
			//var num = 2
			
			appPopup.addItem(withTitle: displayName)
			
			image.size = NSSize(width: 16, height: 16)
			appPopup.item(at: i)?.image = image
		}
	
		if apps.count > 0 {
			appPopup.menu?.addItem(NSMenuItem.separator())
		}
		appPopup.addItem(withTitle: NSLocalizedString("Select...", comment: "Select..."))
		setAppPopupToCurrent()
	}

	func resetCurrentApp() {
		var currSetID: String? = {
			if let aSetID = LSCopyDefaultHandlerForURLScheme(URL_SCHEME as NSString)?.takeRetainedValue() {
				return aSetID as String
			}
			
			return nil
		}()
		
		if currSetID == nil {
			currSetID = appInfos[0].bundleID
		}
		
		if let currSetID = currSetID {
			var resetPopup: Bool = (currentAppID == "") //first time
			
			currentAppID = currSetID
			
			if appInfos.index(bundleID: currSetID) == nil {
				appInfos.addApp(identifier: currSetID, shouldResort: true)
				resetPopup = true
			}
			if resetPopup {
				resetAppPopup()
			} else {
				setAppPopupToCurrent()
			}
		}
	}
	
	func setManPageViewer(_ bundleID: String) {
		let error = LSSetDefaultHandlerForURLScheme(URL_SCHEME as NSString, bundleID as NSString)
		
		if (error != noErr) {
			print("Could not set default \(URL_SCHEME_PREFIX) app: Launch Services error \(error)")
		}
		
		resetCurrentApp()
	}
	
	@IBAction func chooseNewApp(_ sender: AnyObject!) {
		_ = appInfos.allManViewerApps
		let choice = appPopup.indexOfSelectedItem
		
		if choice >= 0 && choice < appInfos.count {
			let info = appInfos[choice]
			if info.bundleID != currentAppID {
				setManPageViewer(info.bundleID)
			}
		} else {
			let panel = NSOpenPanel()
			panel.treatsFilePackagesAsDirectories = false
			panel.allowsMultipleSelection = false
			panel.resolvesAliases = true
			panel.canChooseFiles = true
			panel.allowedFileTypes = [kUTTypeApplicationBundle as String]
			panel.beginSheetModal(for: appPopup.window!) { (result) -> Void in
				if result == .OK,
					let appURL = panel.url,
					let appID = Bundle(url: appURL)?.bundleIdentifier {
					self.setManPageViewer(appID)
				}
				self.setAppPopupToCurrent()
			}
		}
	}
	
	// MARK: man paths

	func setUpManPathUI() {
		manPathTableView.registerForDraggedTypes([ourFile, .string, ManPathIndexSetPboardType])
		manPathTableView.verticalMotionCanBeginDrag = true
		// XXX NSDragOperationDelete -- not sure the "poof" drag can show that
		manPathTableView.setDraggingSourceOperationMask(.copy, forLocal: false)
		manPathTableView.setDraggingSourceOperationMask([.copy, .move, .private], forLocal: true)
	}

	func saveManPath() {
		if manPathArray.count > 0 {
			UserDefaults.standard[manPathKey] = manPathArray.joined(separator: ":")
		}
	}
	
	func addPathDirectories(_ directories: [String], atIndex: Int, removeFirst removeIndexes: IndexSet?) {
		
		func insertObject(_ anObj: String, atIndex: Int) {
			let hasObject = manPathArrayPriv.filter { (otherObj) -> Bool in
				return anObj == otherObj
			}
			if hasObject.count == 0 {
				manPathArrayPriv.insert(anObj, at: atIndex)
			}
		}
		
		var insertIndex = atIndex
		
		self.willChangeValue(forKey: ManPathArrayKey)
		if let removeIndexesUn = removeIndexes {
			var numBeforeInsertion = 0
			
			for i in (0..<manPathArrayPriv.count).reversed() {
				if removeIndexesUn.contains(i) {
					manPathArrayPriv.remove(at: i)
					if i <= insertIndex {
						numBeforeInsertion += 1
					}
				}
			}
			insertIndex -= numBeforeInsertion
		}
		
		for directory in directories {
			var path = (directory as NSString).expandingTildeInPath
			path = path.replacingOccurrences(of: ":", with: "")
			
			insertObject(path, atIndex: insertIndex)
			insertIndex += 1
		}
		
		self.didChangeValue(forKey: ManPathArrayKey)
		saveManPath()
	}
	
	@IBAction func addPathFromPanel(_ sender: AnyObject!) {
		let panel = NSOpenPanel()
		
		panel.allowsMultipleSelection = true
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		
		panel.beginSheetModal(for: window!, completionHandler: { (result) -> Void in
			if result == .OK {
				let urls = panel.urls 
				let paths = urls.map({$0.path})
				
				var insertionIndex = self.manPathController.selectionIndex
				if insertionIndex == NSNotFound {
					insertionIndex = self.manPathArrayPriv.count
				}
				
				self.addPathDirectories(paths, atIndex: insertionIndex, removeFirst: nil)
			}
		})
	}
	
	func pathsAtIndexes(_ set: IndexSet) -> [String] {
		var paths = [String]()
		
		for i in set {
			paths.append(manPathArrayPriv[i])
		}
		
		return paths
	}
	
	@discardableResult
	func writePaths(_ paths: [String], toPasteboard pb: NSPasteboard) -> Bool {
		pb.declareTypes([.string], owner: nil)
		
		/* This causes an NSLog if one of the paths does not exist. Hm.  May not be worth it. Might let folks drag to Trash etc. as well. */
		//[pb setPropertyList:paths forType:NSFilenamesPboardType];
		return pb.setString(paths.joined(separator: ":"), forType: .string)
	}
	
	func writeIndexSet(_ set: IndexSet, toPasteboard pb: NSPasteboard) -> Bool {
		let files = pathsAtIndexes(set)
		
		if writePaths(files, toPasteboard: pb) {
			pb.addTypes([ManPathIndexSetPboardType], owner: nil)
			return pb.setData(NSArchiver.archivedData(withRootObject: set), forType: ManPathIndexSetPboardType)
		}
		
		return false
	}
	
	func paths(from pb: NSPasteboard) -> [String]? {
		let bestType = pb.availableType(from: [ourFile, .string])
		
		if bestType == ourFile {
			return pb.propertyList(forType: ourFile) as! [String]!
		}
		
		if bestType == .string {
			if let aVar = pb.string(forType: .string) {
				return aVar.components(separatedBy: ":")
			}
		}
		
		return nil
	}
	
	@IBAction func copy(_ sender: AnyObject!) {
		let files = pathsAtIndexes(manPathController.selectionIndexes)
		writePaths(files, toPasteboard: .general)
	}
	
	
	@IBAction func delete(_ sender: AnyObject!) {
		manPathController.remove(sender)
	}
	
	@IBAction func cut(_ sender: AnyObject!) {
		copy(sender)
		delete(sender)
	}
	
	@IBAction func paste(_ sender: AnyObject!) {
		let paths = self.paths(from: NSPasteboard.general)
		var insertionIndex = manPathController.selectionIndex
		if insertionIndex == NSNotFound {
			insertionIndex = manPathArrayPriv.count //add it on the end
		}
		
		addPathDirectories(paths!, atIndex: insertionIndex, removeFirst: nil)
	}
	
	// MARK: drag and drop
	
	func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
		return writeIndexSet(rowIndexes, toPasteboard: pboard)
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		let pb = info.draggingPasteboard()
		
		/* We only drop between rows */
		if dropOperation == .above {
			return NSDragOperation()
		}
		
		/* If this is a dragging operation in the table itself, show the move icon */
		if let pbtypes = pb.types, pbtypes.contains(ManPathIndexSetPboardType) && ((info.draggingSource() as AnyObject?) === manPathTableView) {
			return .move;
		}
		
		if let paths = self.paths(from: pb) {
			for path in paths {
				if manPathArrayPriv.contains(path) {
					return .copy
				}
			}
		}
		
		return NSDragOperation()
	}
	
	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
		let pb = info.draggingPasteboard()
		let dragOp = info.draggingSourceOperationMask()
		var pathsToAdd: [String]? = [String]()
		var removeSet: IndexSet? = nil
		
		if let pbtypes = pb.types, pbtypes.contains(ManPathIndexSetPboardType) {
			let indexData = pb.data(forType: ManPathIndexSetPboardType)
			if let indexData = indexData, (dragOp.intersection(.move) == .move), let removeSet2 = NSUnarchiver.unarchiveObject(with: indexData) as? IndexSet {
				removeSet = removeSet2
				pathsToAdd = pathsAtIndexes(removeSet!)
			}
		} else {
			pathsToAdd = paths(from: pb)
		}
		
		if let pathsToAdd = pathsToAdd, pathsToAdd.count > 0 {
			addPathDirectories(pathsToAdd, atIndex: row, removeFirst: removeSet)
			return true
		}
		
		return false;
	}
}
