//
//  Data+Utils.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/15/16.
//
//

import Foundation

extension Data {
	public var isNroffData: Bool {
		return (self as NSData).isNroffData
	}
	
	public var isRTFData: Bool {
		return (self as NSData).isRTFData
	}
	
	public var isGzipData: Bool {
		return (self as NSData).isGzipData
	}
	
	public var isBinaryData: Bool {
		return (self as NSData).isBinaryData
	}
}
