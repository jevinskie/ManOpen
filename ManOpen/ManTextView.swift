//
//  ManTextView.swift
//  ManOpen
//
//  Created by C.W. Betts on 1/30/15.
//
//

import Cocoa
import SwiftAdditions

class ManTextView: NSTextView {
	
	override func resetCursorRects() {
		let container = textContainer
		let layout = layoutManager
		let storage = textStorage
		let visible = visibleRect
		var currIndex = 0
		
		super.resetCursorRects()
		
		while currIndex < (storage?.length ?? 0) {
			var currRange = NSRange(location: 0, length: 0)
			var attribs = storage?.attributesAtIndex(currIndex, effectiveRange: &currRange)
			let isLinkSection = attribs?[NSLinkAttributeName] != nil
			if isLinkSection {
				let ignoreRange = NSRange.notFound
				var rectCount = 0
				
				let rects = layout?.rectArrayForCharacterRange(currRange, withinSelectedCharacterRange: ignoreRange, inTextContainer: container!, rectCount: &rectCount)
				
				for i in 0 ..< rectCount {
					if (NSIntersectsRect(visible, rects![i])) {
						addCursorRect(rects![i], cursor: NSCursor.pointingHandCursor())
					}
				}
			}
			currIndex = currRange.max;
		}
	}
	
	func scrollRangeToTop(charRange: NSRange) {
		let layout = layoutManager!
		let glyphRange = layout.glyphRangeForCharacterRange(charRange, actualCharacterRange: nil)
		var rect = layout.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer!)
		let height = visibleRect.height
		
		if height > 0 {
			rect.size.height = height
		}
		
		scrollRectToVisible(rect)
	}
	
	/// Make space page down (and shift/alt-space page up)
	override func keyDown(event: NSEvent) {
		if event.charactersIgnoringModifiers == " " {
			if (event.modifierFlags.intersect(.AlternateKeyMask)) == .AlternateKeyMask || (event.modifierFlags.intersect(.ShiftKeyMask)) == .ShiftKeyMask {
				pageUp(self)
			} else {
				pageDown(self)
			}
		} else {
			super.keyDown(event)
		}
	}
	
	/**
	* Draw page numbers when printing. Under early versions of MacOS X... the normal
	* NSString drawing methods don't work in the context of this method. So, I fell back on
	* CoreGraphics primitives, which did. However, I'm now just supporting Tiger (10.4) and up,
	* and it looks like the bugs have been fixed, so we can just use the higher-level
	* NSStringDrawing now, thankfully.
	*/
	override func drawPageBorderWithSize(borderSize: NSSize) {
		let font = NSUserDefaults.standardUserDefaults().manFont
		
		let currPage = NSPrintOperation.currentOperation()!.currentPage
		let pageString = "\(currPage)"
		let style = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
		var drawAttribs = [String: AnyObject]()
		let drawRect = NSRect(x: 0, y: 0, width: borderSize.width, height: 20 + font.ascender)
		
		style.alignment = .Center
		drawAttribs[NSParagraphStyleAttributeName] = style
		drawAttribs[NSFontAttributeName] = font
		
		(pageString as NSString).drawInRect(drawRect, withAttributes: drawAttribs)
		
		/*
CGFloat strWidth = [str sizeWithAttributes:attribs].width;
NSPoint point = NSMakePoint(size.width/2 - strWidth/2, 20.0f);
CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

CGContextSaveGState(context);
CGContextSetTextMatrix(context, CGAffineTransformIdentity);
CGContextSetTextDrawingMode(context, kCGTextFill);  //needed?
CGContextSetGrayFillColor(context, 0.0f, 1.0f);
CGContextSelectFont(context, [[font fontName] cStringUsingEncoding:NSMacOSRomanStringEncoding], [font pointSize], kCGEncodingMacRoman);
CGContextShowTextAtPoint(context, point.x, point.y, [str cStringUsingEncoding:NSMacOSRomanStringEncoding], [str lengthOfBytesUsingEncoding:NSMacOSRomanStringEncoding]);
CGContextRestoreGState(context);
*/
	}
}

