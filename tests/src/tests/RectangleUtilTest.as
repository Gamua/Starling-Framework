// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests
{
    import flash.geom.Rectangle;
    
    import starling.utils.RectangleUtil;

    public class RectangleUtilTest
    {
        [Test]
        public function testIntersection():void
        {
            var expectedRect:Rectangle;
            var rect:Rectangle = new Rectangle(-5, -10, 10, 20);
            
            var overlapRect:Rectangle = new Rectangle(-10, -15, 10, 10);
            var identRect:Rectangle = new Rectangle(-5, -10, 10, 20);
            var outsideRect:Rectangle = new Rectangle(10, 10, 10, 10);
            var touchingRect:Rectangle = new Rectangle(5, 0, 10, 10);
            var insideRect:Rectangle = new Rectangle(0, 0, 1, 2);
            
            expectedRect = new Rectangle(-5, -10, 5, 5);
            Helpers.compareRectangles(expectedRect,
                RectangleUtil.intersect(rect, overlapRect));
            
            expectedRect = rect;
            Helpers.compareRectangles(expectedRect,
                RectangleUtil.intersect(rect, identRect));
            
            expectedRect = new Rectangle();
            Helpers.compareRectangles(expectedRect,
                RectangleUtil.intersect(rect, outsideRect));
            
            expectedRect = new Rectangle(5, 0, 0, 10);
            Helpers.compareRectangles(expectedRect,
                RectangleUtil.intersect(rect, touchingRect));
            
            expectedRect = insideRect;
            Helpers.compareRectangles(expectedRect,
                RectangleUtil.intersect(rect, insideRect));
        }
    }
}