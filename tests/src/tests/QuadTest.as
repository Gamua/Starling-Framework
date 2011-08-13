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
    import flexunit.framework.Assert;
    
    import starling.display.Quad;
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
    }
}