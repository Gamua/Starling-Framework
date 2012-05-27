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
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    import flexunit.framework.Assert;
    
    import org.flexunit.assertThat;
    import org.hamcrest.number.closeTo;
    
    import starling.utils.VertexData;
    
    public class VertexDataTest
    {
        private static const E:Number = 0.001;
        
        [Test]
        public function testInit():void
        {
            var numVertices:int = 3;
            var vd:VertexData = new VertexData(numVertices);
            var position:Point = new Point();
            var texCoords:Point = new Point();
            
            for (var i:int=0; i<numVertices; ++i)
            {
                vd.getPosition(i, position);
                vd.getTexCoords(i, texCoords);
                
                Helpers.comparePoints(position, new Point());
                Helpers.comparePoints(texCoords, new Point());
                Assert.assertEquals(0x0, vd.getColor(i));
                Assert.assertEquals(1.0, vd.getAlpha(i));
            }
        }
        
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
            vd.setPosition(0, 1, 2);
            vd.setPosition(1, 4, 5);
            
            var position:Point = new Point();
            
            vd.getPosition(0, position);
            Assert.assertEquals(1, position.x);
            Assert.assertEquals(2, position.y);
            
            vd.getPosition(1, position);            
            Assert.assertEquals(4, position.x);
            Assert.assertEquals(5, position.y);
        }
        
        [Test]
        public function testColor():void
        {
            var vd:VertexData = new VertexData(3, true);
            Assert.assertEquals(3, vd.numVertices);
            Assert.assertTrue(vd.premultipliedAlpha);
            
            vd.setColor(0, 0xffaabb);
            vd.setColor(1, 0x112233);
            
            Assert.assertEquals(0xffaabb, vd.getColor(0));
            Assert.assertEquals(0x112233, vd.getColor(1));
            Assert.assertEquals(1.0, vd.getAlpha(0));
            
            // check premultiplied alpha
            
            var alpha:Number = 0.5;
            
            vd.setColor(2, 0x445566);
            vd.setAlpha(2, alpha);
            Assert.assertEquals(0x445566, vd.getColor(2));
            Assert.assertEquals(1.0, vd.getAlpha(1));
            Assert.assertEquals(alpha, vd.getAlpha(2));
            
            var data:Vector.<Number> = vd.rawData;
            var red:Number   = 0x44 / 255.0;
            var green:Number = 0x55 / 255.0;
            var blue:Number  = 0x66 / 255.0;
            var offset:int = VertexData.ELEMENTS_PER_VERTEX * 2 + VertexData.COLOR_OFFSET;
            
            assertThat(data[offset  ], closeTo(red * alpha, E));
            assertThat(data[offset+1], closeTo(green * alpha, E));
            assertThat(data[offset+2], closeTo(blue * alpha, E));
            
            // changing the pma setting should update contents
            
            vd.setPremultipliedAlpha(false, true);
            Assert.assertFalse(vd.premultipliedAlpha);
            
            Assert.assertEquals(0xffaabb, vd.getColor(0));
            Assert.assertEquals(0x112233, vd.getColor(1));
            Assert.assertEquals(1.0, vd.getAlpha(0));
            
            vd.setColor(2, 0x445566);
            vd.setAlpha(2, 0.5);
            Assert.assertEquals(0x445566, vd.getColor(2));
            Assert.assertEquals(0.5, vd.getAlpha(2));
            
            assertThat(data[offset  ], closeTo(red, E));
            assertThat(data[offset+1], closeTo(green, E));
            assertThat(data[offset+2], closeTo(blue, E));
        }
        
        [Test]
        public function testTexCoords():void
        {
            var vd:VertexData = new VertexData(2);
            vd.setTexCoords(0, 0.25, 0.75);
            vd.setTexCoords(1, 0.33, 0.66);
            
            var texCoords:Point = new Point();
            
            vd.getTexCoords(0, texCoords);
            Assert.assertEquals(0.25, texCoords.x);
            Assert.assertEquals(0.75, texCoords.y);
            
            vd.getTexCoords(1, texCoords);
            Assert.assertEquals(0.33, texCoords.x);
            Assert.assertEquals(0.66, texCoords.y);
        }
    }
}