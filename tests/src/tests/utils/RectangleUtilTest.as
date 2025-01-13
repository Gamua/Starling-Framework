// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    import starling.unit.UnitTest;
    import starling.utils.RectangleUtil;
    import starling.utils.ScaleMode;

    public class RectangleUtilTest extends UnitTest
    {
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
            assertEqualRectangles(expectedRect,
                RectangleUtil.intersect(rect, overlapRect));

            expectedRect = rect;
            assertEqualRectangles(expectedRect,
                RectangleUtil.intersect(rect, identRect));

            expectedRect = new Rectangle();
            assertEqualRectangles(expectedRect,
                RectangleUtil.intersect(rect, outsideRect));

            expectedRect = new Rectangle(5, 0, 0, 10);
            assertEqualRectangles(expectedRect,
                RectangleUtil.intersect(rect, touchingRect));

            expectedRect = insideRect;
            assertEqualRectangles(expectedRect,
                RectangleUtil.intersect(rect, insideRect));
        }

        public function testFit():void
        {
            var into:Rectangle = new Rectangle(50, 50, 200, 100);

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 200, 100), into),
                new Rectangle(50, 50, 200, 100));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 50, 50), into, ScaleMode.NONE),
                new Rectangle(125, 75, 50, 50));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 400, 200), into, ScaleMode.NONE),
                new Rectangle(-50, 0, 400, 200));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 50, 50), into, ScaleMode.SHOW_ALL),
                new Rectangle(100, 50, 100, 100));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 400, 200), into, ScaleMode.SHOW_ALL),
                new Rectangle(50, 50, 200, 100));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 800, 400), into, ScaleMode.SHOW_ALL),
                new Rectangle(50, 50, 200, 100));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 400, 200), into, ScaleMode.NO_BORDER),
                new Rectangle(50, 50, 200, 100));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 200, 200), into, ScaleMode.NO_BORDER),
                new Rectangle(50, 0, 200, 200));

            assertEqualRectangles(
                RectangleUtil.fit(new Rectangle(0, 0, 800, 800), into, ScaleMode.NO_BORDER),
                new Rectangle(50, 0, 200, 200));
        }

        public function testNormalize():void
        {
            var rect:Rectangle = new Rectangle(50, 100, -50, -100);
            RectangleUtil.normalize(rect);

            assertEqualRectangles(rect, new Rectangle(0, 0, 50, 100));

            rect = new Rectangle(1, 2, 3, 4);
            RectangleUtil.normalize(rect);

            assertEqualRectangles(rect, new Rectangle(1, 2, 3, 4));
        }

        public function testCompare():void
        {
            var rect:Rectangle = new Rectangle(1, 2, 3, 4);
            var rect2:Rectangle = new Rectangle(2, 3, 4, 5);

            assertTrue(RectangleUtil.compare(rect, rect));
            assertTrue(RectangleUtil.compare(null, null));
            assertFalse(RectangleUtil.compare(rect, null));
            assertFalse(RectangleUtil.compare(null, rect));
            assertFalse(RectangleUtil.compare(rect, rect2));
        }

        public function testGetBoundsProjected():void
        {
            var camPos:Vector3D = new Vector3D(0, 0, 10);
            var bounds:Rectangle, expected:Rectangle;

            var matrix3D:Matrix3D = new Matrix3D();
            matrix3D.appendTranslation(0, 0, 5);

            var rectangle:Rectangle = new Rectangle(0, 0, 5, 5);
            bounds = RectangleUtil.getBoundsProjected(rectangle, matrix3D, camPos);
            expected = new Rectangle(0, 0, 10, 10);

            assertEqualRectangles(expected, bounds);
        }
    }
}