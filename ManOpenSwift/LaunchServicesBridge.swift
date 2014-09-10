//
//  LaunchServicesBridge.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

import Cocoa
import CoreFoundation
import CoreServices

func StringToCFString(string: String) -> CFString {
	return string as NSString as CFString
}

func CFStringToString(cfString: CFString) -> String {
	return cfString as NSString as String
}

func CFStringToString(cfString: CFString?) -> String? {
	return cfString as NSString? as String?
}
