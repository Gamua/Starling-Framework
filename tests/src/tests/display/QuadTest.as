// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.unit.UnitTest;
    import starling.utils.Color;

    import utils.MockTexture;

    public class QuadTest extends UnitTest
    {
        private static const E:Number = 0.0001;

        public function testQuad():void
        {
            var quad:Quad = new Quad(100, 200, Color.AQUA);
            assertEqual(Color.AQUA, quad.color);
        }

        public function testColors():void
        {
            var quad:Quad = new Quad(100, 100);
            quad.setVertexColor(0, Color.AQUA);
            quad.setVertexColor(1, Color.BLACK);
            quad.setVertexColor(2, Color.BLUE);
            quad.setVertexColor(3, Color.FUCHSIA);

            assertEqual(Color.AQUA,    quad.getVertexColor(0));
            assertEqual(Color.BLACK,   quad.getVertexColor(1));
            assertEqual(Color.BLUE,    quad.getVertexColor(2));
            assertEqual(Color.FUCHSIA, quad.getVertexColor(3));
        }

        public function testBounds():void
        {
            var quad:Quad = new Quad(100, 200);
            assertEqualRectangles(new Rectangle(0, 0, 100, 200), quad.bounds);

            quad.pivotX = 50;
            assertEqualRectangles(new Rectangle(-50, 0, 100, 200), quad.bounds);

            quad.pivotY = 60;
            assertEqualRectangles(new Rectangle(-50, -60, 100, 200), quad.bounds);

            quad.scaleX = 2;
            assertEqualRectangles(new Rectangle(-100, -60, 200, 200), quad.bounds);

            quad.scaleY = 0.5;
            assertEqualRectangles(new Rectangle(-100, -30, 200, 100), quad.bounds);

            quad.x = 10;
            assertEqualRectangles(new Rectangle(-90, -30, 200, 100), quad.bounds);

            quad.y = 20;
            assertEqualRectangles(new Rectangle(-90, -10, 200, 100), quad.bounds);

            var parent:Sprite = new Sprite();
            parent.addChild(quad);

            assertEqualRectangles(parent.bounds, quad.bounds);
        }

        public function testWidthAndHeight():void
        {
            var quad:Quad = new Quad(100, 50);
            assertEqual(100, quad.width);
            assertEqual(50,  quad.height);

            quad.scaleX = -1;
            assertEqual(100, quad.width);

            quad.pivotX = 100;
            assertEqual(100, quad.width);

            quad.pivotX = -10;
            assertEqual(100, quad.width);

            quad.scaleY = -1;
            assertEqual(50, quad.height);

            quad.pivotY = 20;
            assertEqual(50, quad.height);
        }

        public function testHitTest():void
        {
            var quad:Quad = new Quad(100, 50);
            assertEqual(quad, quad.hitTest(new Point(0.1, 0.1)));
            assertEqual(quad, quad.hitTest(new Point(99.9, 49.9)));
            assertNull(quad.hitTest(new Point(-0.1, -0.1)));
            assertNull(quad.hitTest(new Point(100.1, 25)));
            assertNull(quad.hitTest(new Point(50, 50.1)));
            assertNull(quad.hitTest(new Point(100.1, 50.1)));
        }

        public function testReadjustSize():void
        {
            var texture:Texture = new MockTexture(100, 50);
            var quad:Quad = new Quad(10, 20);
            quad.texture = texture;

            assertEquivalent(quad.width, 10);
            assertEquivalent(quad.height, 20);
            assertEqual(texture, quad.texture);

            quad.readjustSize();

            assertEquivalent(quad.width, texture.frameWidth);
            assertEquivalent(quad.height, texture.frameHeight);

            var newWidth:Number  = 64;
            var newHeight:Number = 32;

            quad.readjustSize(newWidth, newHeight);

            assertEquivalent(quad.width, newWidth);
            assertEquivalent(quad.height, newHeight);

            quad.texture = null;
            quad.readjustSize(); // shouldn't change anything

            assertEquivalent(quad.width, newWidth);
            assertEquivalent(quad.height, newHeight);
        }
    }
}