// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import starling.core.starling_internal;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.utils.Color;
    import tests.Helpers;
    
    use namespace starling_internal;

    public class QuadTest
    {		
        [Test]
        public function testQuad():void
        {
            var quad:Quad = new Quad(100, 200, Color.AQUA);            
            Assert.assertEquals(Color.AQUA, quad.color);            
        }
        
        [Test]
        public function testColors():void
        {
            var quad:Quad = new Quad(100, 100);            
            quad.setVertexColor(0, Color.AQUA);
            quad.setVertexColor(1, Color.BLACK);
            quad.setVertexColor(2, Color.BLUE);
            quad.setVertexColor(3, Color.FUCHSIA);
            
            Assert.assertEquals(Color.AQUA,    quad.getVertexColor(0));
            Assert.assertEquals(Color.BLACK,   quad.getVertexColor(1));
            Assert.assertEquals(Color.BLUE,    quad.getVertexColor(2));
            Assert.assertEquals(Color.FUCHSIA, quad.getVertexColor(3));
        }
        
        [Test]
        public function testTinted():void
        {
            var quad:Quad = new Quad(100, 100);
            Assert.assertFalse(quad.tinted);
            
            quad.setVertexColor(2, 0xffffff);
            Assert.assertFalse(quad.tinted);
            
            quad.setVertexAlpha(2, 1.0);
            Assert.assertFalse(quad.tinted);
            
            quad.setVertexColor(3, 0xff0000);
            Assert.assertTrue(quad.tinted);
            
            quad.setVertexColor(3, 0xffffff);
            Assert.assertFalse(quad.tinted);
            
            quad.setVertexAlpha(3, 0.5);
            Assert.assertTrue(quad.tinted);
            
            quad.setVertexAlpha(3, 1.0);
            Assert.assertFalse(quad.tinted);
            
            quad.color = 0xff0000;
            Assert.assertTrue(quad.tinted);
            
            quad.color = 0xffffff;
            Assert.assertFalse(quad.tinted);
            
            quad.alpha = 0.5;
            Assert.assertTrue(quad.tinted);
            
            quad.alpha = 1.0;
            Assert.assertFalse(quad.tinted);
            
            quad.color = 0xff0000;
            quad.setVertexColor(0, 0xffffff);
            quad.setVertexColor(1, 0xffffff);
            quad.setVertexColor(2, 0xffffff);
            Assert.assertTrue(quad.tinted);
            quad.setVertexColor(3, 0xffffff);
            Assert.assertFalse(quad.tinted);
            
            quad.setVertexAlpha(0, 0.5);
            quad.setVertexAlpha(1, 0.5);
            quad.setVertexAlpha(2, 0.5);
            quad.setVertexAlpha(3, 0.5);
            Assert.assertTrue(quad.tinted);
            quad.setVertexAlpha(0, 1.0);
            quad.setVertexAlpha(1, 1.0);
            quad.setVertexAlpha(2, 1.0);
            Assert.assertTrue(quad.tinted);
            quad.setVertexAlpha(3, 1.0);
            Assert.assertFalse(quad.tinted);
            
            quad.setVertexAlpha(2, 0.5);
            quad.setVertexColor(2, 0xffffff);
            Assert.assertTrue(quad.tinted);
        }
        
        [Test]
        public function testTinted2():void
        {
            // https://github.com/PrimaryFeather/Starling-Framework/issues/123
            
            var quad:Quad = new Quad(100, 100);
            quad.color = 0xff0000;
            quad.alpha = 0.5;
            quad.color = 0xffffff;
            Assert.assertTrue(quad.tinted);
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
            Assert.assertEquals(100, quad.width);
            Assert.assertEquals(50,  quad.height);
            
            quad.scaleX = -1;
            Assert.assertEquals(100, quad.width);
            
            quad.pivotX = 100;
            Assert.assertEquals(100, quad.width);
            
            quad.pivotX = -10;
            Assert.assertEquals(100, quad.width);
            
            quad.scaleY = -1;
            Assert.assertEquals(50, quad.height);
            
            quad.pivotY = 20;
            Assert.assertEquals(50, quad.height);
        }
    }
}