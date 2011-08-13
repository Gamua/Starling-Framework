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
    
    import starling.utils.VertexData;
    
    public class VertexDataTest
    {
        [Test]
        public function testGetNumVertices():void
        {
            var vd:VertexData = new VertexData(4);
            Assert.assertEquals(4, vd.numVertices);
        }
        
        [Test(expects="RangeError")]
        public function testBoundsLow():void
        {
            var vd:VertexData = new VertexData(3);
            vd.getColor(-1);
        }
        
        [Test(expects="RangeError")]
        public function testBoundsHigh():void
        {
            var vd:VertexData = new VertexData(3);
            vd.getColor(3);
        }
        
        [Test]
        public function testPosition():void
        {
            var vd:VertexData = new VertexData(4);            
            vd.setPosition(0, 1, 2, 3);
            vd.setPosition(1, 4, 5, 6);
            
            Assert.assertEquals(1, vd.getPosition(0).x);
            Assert.assertEquals(2, vd.getPosition(0).y);
            Assert.assertEquals(3, vd.getPosition(0).z);
            
            Assert.assertEquals(4, vd.getPosition(1).x);
            Assert.assertEquals(5, vd.getPosition(1).y);
            Assert.assertEquals(6, vd.getPosition(1).z);
        }
        
        [Test]
        public function testColor():void
        {
            var vd:VertexData = new VertexData(3);
            vd.setColor(0, 0xffaabb);
            vd.setColor(1, 0x112233);
            
            Assert.assertEquals(0xffaabb, vd.getColor(0));
            Assert.assertEquals(0x112233, vd.getColor(1));            
        }
        
        [Test]
        public function testTexCoords():void
        {
            var vd:VertexData = new VertexData(2);
            vd.setTexCoords(0, 0.25, 0.75);
            vd.setTexCoords(1, 0.33, 0.66);
            
            Assert.assertEquals(0.25, vd.getTexCoords(0).x);
            Assert.assertEquals(0.75, vd.getTexCoords(0).y);
            Assert.assertEquals(0.33, vd.getTexCoords(1).x);
            Assert.assertEquals(0.66, vd.getTexCoords(1).y);
        }
    }
}