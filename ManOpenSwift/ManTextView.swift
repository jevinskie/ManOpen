//
//  ManTextView.swift
//  ManOpen
//
//  Created by C.W. Betts on 1/30/15.
//
//

import Cocoa

class ManTextView: NSTextView {
	
	override func resetCursorRects() {
		let container = textContainer
		let layout = layoutManager
		let storage = textStorage
		var visible = visibleRect
		var currIndex = 0
		
		super.resetCursorRects()
		
		while currIndex < (storage?.length ?? 0) {
			var currRange = NSRange(location: 0, length: 0)
			var attribs = storage?.attributesAtIndex(currIndex, effectiveRange: &currRange)
			var isLinkSection = attribs?[NSLinkAttributeName] != nil
			if isLinkSection {
				var ignoreRange = NSRange(location: NSNotFound, length: 0)
				var i = 0
				var rectCount = 0
				
				var rects = layout?.rectArrayForCharacterRange(currRange, withinSelectedCharacterRange: ignoreRange, inTextContainer: container!, rectCount: &rectCount)
				
				for (i=0; i<rectCount; i++) {
					if (NSIntersectsRect(visible, rects![i])) {
						addCursorRect(rects![i], cursor: NSCursor.pointingHandCursor())
					}
				}
			}
			currIndex = NSMaxRange(currRange);
		}
	}
	
	func scrollRangeToTop(charRange: NSRange) {
		let layout = layoutManager!
		var glyphRange = layout.glyphRangeForCharacterRange(charRange, actualCharacterRange: nil)
		var rect = layout.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer!)
		var height = visibleRect.height
		
		if height > 0 {
			rect.size.height = height
		}
		
		scrollRectToVisible(rect)
	}
	/*

- (void)scrollRangeToTop:(NSRange)charRange
{
NSLayoutManager *layout = [self layoutManager];
NSRange glyphRange = [layout glyphRangeForCharacterRange:charRange actualCharacterRange:NULL];
NSRect rect = [layout boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
CGFloat height = NSHeight([self visibleRect]);

if (height > 0)
rect.size.height = height;

[self scrollRectToVisible:rect];
}

/* Make space page down (and shift/alt-space page up) */
- (void)keyDown:(NSEvent *)event
{
if ([[event charactersIgnoringModifiers] isEqual:@" "])
{
if ([event modifierFlags] & (NSShiftKeyMask|NSAlternateKeyMask))
[self pageUp:self];
else
[self pageDown:self];
}
else
{
[super keyDown:event];
}
}

/*
* Draw page numbers when printing. Under early versions of MacOS X... the normal
* NSString drawing methods don't work in the context of this method. So, I fell back on
* CoreGraphics primitives, which did. However, I'm now just supporting Tiger (10.4) and up,
* and it looks like the bugs have been fixed, so we can just use the higher-level
* NSStringDrawing now, thankfully.
*/
- (void)drawPageBorderWithSize:(NSSize)size
{
NSFont *font = [[NSUserDefaults standardUserDefaults] manFont];

NSInteger currPage = [[NSPrintOperation currentOperation] currentPage];
NSString *pageString = [NSString stringWithFormat:@"%ld", (long)currPage];
NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
NSMutableDictionary *drawAttribs = [NSMutableDictionary dictionary];
NSRect drawRect = NSMakeRect(0.0f, 0.0f, size.width, 20.0f + [font ascender]);

[style setAlignment:NSCenterTextAlignment];
drawAttribs[NSParagraphStyleAttributeName] = style;
drawAttribs[NSFontAttributeName] = font;

[pageString drawInRect:drawRect withAttributes:drawAttribs];
#if 0
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
#endif
}
*/


}

