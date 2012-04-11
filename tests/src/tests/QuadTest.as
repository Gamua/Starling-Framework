// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests
{
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.utils.Color;

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
            
            var parent:Sprite = new Sprite();
            parent.addChild(quad);
            
            Helpers.compareRectangles(parent.bounds, quad.bounds);
        }
    }
}