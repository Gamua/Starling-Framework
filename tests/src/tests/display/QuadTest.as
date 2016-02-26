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

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertNull;
    import org.hamcrest.number.closeTo;

    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.utils.Color;

    import tests.Helpers;
    import tests.utils.MockTexture;

    public class QuadTest
    {
        private static const E:Number = 0.0001;

        [Test]
        public function testQuad():void
        {
            var quad:Quad = new Quad(100, 200, Color.AQUA);            
            assertEquals(Color.AQUA, quad.color);
        }
        
        [Test]
        public function testColors():void
        {
            var quad:Quad = new Quad(100, 100);            
            quad.setVertexColor(0, Color.AQUA);
            quad.setVertexColor(1, Color.BLACK);
            quad.setVertexColor(2, Color.BLUE);
            quad.setVertexColor(3, Color.FUCHSIA);
            
            assertEquals(Color.AQUA,    quad.getVertexColor(0));
            assertEquals(Color.BLACK,   quad.getVertexColor(1));
            assertEquals(Color.BLUE,    quad.getVertexColor(2));
            assertEquals(Color.FUCHSIA, quad.getVertexColor(3));
        }

        [Test]
        public function testBounds():void
        {
            var quad:Quad = new Quad(100, 200);
            Helpers.compareRectangles(new Rectangle(0, 0, 100, 200), quad.bounds);
            
            quad.pivotX = 50;
            Helpers.compareRectangles(new Rectangle(-50, 0, 100, 200), quad.bounds);
            
            quad.pivotY = 60;
            Helpers.compareRectangles(new Rectangle(-50, -60, 100, 200), quad.bounds);
            
            quad.scaleX = 2;
            Helpers.compareRectangles(new Rectangle(-100, -60, 200, 200), quad.bounds);
            
            quad.scaleY = 0.5;
            Helpers.compareRectangles(new Rectangle(-100, -30, 200, 100), quad.bounds);
            
            quad.x = 10;
            Helpers.compareRectangles(new Rectangle(-90, -30, 200, 100), quad.bounds);
            
            quad.y = 20;
            Helpers.compareRectangles(new Rectangle(-90, -10, 200, 100), quad.bounds);
            
            var parent:Sprite = new Sprite();
            parent.addChild(quad);
            
            Helpers.compareRectangles(parent.bounds, quad.bounds);
        }
        
        [Test]
        public function testWidthAndHeight():void
        {
            var quad:Quad = new Quad(100, 50);
            assertEquals(100, quad.width);
            assertEquals(50,  quad.height);
            
            quad.scaleX = -1;
            assertEquals(100, quad.width);
            
            quad.pivotX = 100;
            assertEquals(100, quad.width);
            
            quad.pivotX = -10;
            assertEquals(100, quad.width);
            
            quad.scaleY = -1;
            assertEquals(50, quad.height);
            
            quad.pivotY = 20;
            assertEquals(50, quad.height);
        }

        [Test]
        public function testHitTest():void
        {
            var quad:Quad = new Quad(100, 50);
            assertEquals(quad, quad.hitTest(new Point(0.1, 0.1)));
            assertEquals(quad, quad.hitTest(new Point(99.9, 49.9)));
            assertNull(quad.hitTest(new Point(-0.1, -0.1)));
            assertNull(quad.hitTest(new Point(100.1, 25)));
            assertNull(quad.hitTest(new Point(50, 50.1)));
            assertNull(quad.hitTest(new Point(100.1, 50.1)));
        }

        [Test]
        public function testReadjustSize():void
        {
            var texture:Texture = new MockTexture(100, 50);
            var quad:Quad = new Quad(10, 20);
            quad.texture = texture;

            assertThat(quad.width, closeTo(10, E));
            assertThat(quad.height, closeTo(20, E));
            assertEquals(texture, quad.texture);

            quad.readjustSize();

            assertThat(quad.width, closeTo(texture.frameWidth, E));
            assertThat(quad.height, closeTo(texture.frameHeight, E));

            var newWidth:Number  = 64;
            var newHeight:Number = 32;

            quad.readjustSize(newWidth, newHeight);

            assertThat(quad.width, closeTo(newWidth, E));
            assertThat(quad.height, closeTo(newHeight, E));

            quad.texture = null;
            quad.readjustSize(); // shouldn't change anything

            assertThat(quad.width, closeTo(newWidth, E));
            assertThat(quad.height, closeTo(newHeight, E));
        }
    }
}