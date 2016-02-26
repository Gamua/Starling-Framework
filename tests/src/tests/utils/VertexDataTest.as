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
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.hamcrest.number.closeTo;
    
    import starling.utils.Color;
    import starling.utils.VertexData;
    import tests.Helpers;
    
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
        
        [Test(expects="Error")]
        public function testBoundsLow():void
        {
            var vd:VertexData = new VertexData(3);
            vd.getColor(-1);
        }
        
        [Test(expects="Error")]
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
            
            var alpha:Number = 0.8;
            var red:int   = 80;
            var green:int = 60;
            var blue:int  = 40;
            var rgb:uint = Color.rgb(red, green, blue);
            
            vd.setColor(2, rgb);
            vd.setAlpha(2, alpha);
            Assert.assertEquals(rgb, vd.getColor(2));
            Assert.assertEquals(1.0, vd.getAlpha(1));
            Assert.assertEquals(alpha, vd.getAlpha(2));
            
            var data:Vector.<Number> = vd.rawData;
            var offset:int = VertexData.ELEMENTS_PER_VERTEX * 2 + VertexData.COLOR_OFFSET;
            
            assertThat(data[offset  ], closeTo(red   / 255.0 * alpha, E));
            assertThat(data[offset+1], closeTo(green / 255.0 * alpha, E));
            assertThat(data[offset+2], closeTo(blue  / 255.0 * alpha, E));
            
            // changing the pma setting should update contents
            
            vd.setPremultipliedAlpha(false, true);
            Assert.assertFalse(vd.premultipliedAlpha);
            
            Assert.assertEquals(0xffaabb, vd.getColor(0));
            Assert.assertEquals(0x112233, vd.getColor(1));
            Assert.assertEquals(1.0, vd.getAlpha(0));
            
            vd.setColor(2, rgb);
            vd.setAlpha(2, alpha);
            Assert.assertEquals(rgb, vd.getColor(2));
            Assert.assertEquals(alpha, vd.getAlpha(2));
            
            assertThat(data[offset  ], closeTo(red   / 255.0, E));
            assertThat(data[offset+1], closeTo(green / 255.0, E));
            assertThat(data[offset+2], closeTo(blue  / 255.0, E));
        }
        
        [Test]
        public function testTexCoords():void
        {
            var vd:VertexData = new VertexData(2);
            vd.setTexCoords(0, 0.25, 0.75);
            vd.setTexCoords(1, 0.33, 0.66);
            
            var texCoords:Point = new Point();
            
            vd.getTexCoords(0, texCoords);
            assertThat(texCoords.x, closeTo(0.25, E));
            assertThat(texCoords.y, closeTo(0.75, E));
            
            vd.getTexCoords(1, texCoords);
            assertThat(texCoords.x, closeTo(0.33, E));
            assertThat(texCoords.y, closeTo(0.66, E));
        }
        
        [Test]
        public function testGetBounds():void
        {
            var vd:VertexData = new VertexData(0);
            var bounds:Rectangle = vd.getBounds();
            var expectedBounds:Rectangle = new Rectangle();
            
            Helpers.compareRectangles(expectedBounds, bounds);
            
            vd.numVertices = 2;
            vd.setPosition(0, -10, -5);
            vd.setPosition(1, 10, 5);
            
            bounds = vd.getBounds();
            expectedBounds = new Rectangle(-10, -5, 20, 10);
            
            Helpers.compareRectangles(expectedBounds, bounds);
            
            var matrix:Matrix = new Matrix();
            matrix.translate(10, 5);
            bounds = vd.getBounds(matrix);
            expectedBounds = new Rectangle(0, 0, 20, 10);
            
            Helpers.compareRectangles(expectedBounds, bounds);
        }
        
        [Test]
        public function testCopyTo():void
        {
            var vd1:VertexData = new VertexData(2, false);
            vd1.setPosition(0, 1, 2);
            vd1.setColor(0, 0xaabbcc);
            vd1.setTexCoords(0, 0.1, 0.2);
            vd1.setPosition(1, 3, 4);
            vd1.setColor(1, 0x334455);
            vd1.setTexCoords(1, 0.3, 0.4);
            
            var vd2:VertexData = new VertexData(2, false);
            vd1.copyTo(vd2);
            
            Helpers.compareVectorsOfNumbers(vd1.rawData, vd2.rawData);
            assertEquals(vd1.numVertices, vd2.numVertices);
            
            vd2.numVertices = 4;
            vd1.copyTo(vd2, 2);
            assertEquals(4, vd2.numVertices);
            
            for (var i:int=0; i<2; ++i)
                for (var j:int=0; j<VertexData.ELEMENTS_PER_VERTEX; ++j)
                    assertEquals(
                        vd1.rawData[   i  * VertexData.ELEMENTS_PER_VERTEX + j], 
                        vd2.rawData[(2+i) * VertexData.ELEMENTS_PER_VERTEX + j]);
        }
        
        [Test]
        public function testTransformVertex():void
        {
            var vd:VertexData = new VertexData(2);
            vd.setPosition(0, 10, 20);
            vd.setPosition(1, 30, 40);
            
            var matrix:Matrix = new Matrix();
            matrix.translate(5, 6);

            var position:Point = new Point();
            vd.transformVertex(0, matrix, 1);
            vd.getPosition(0, position);
            Helpers.comparePoints(position, new Point(15, 26));
            vd.getPosition(1, position);
            Helpers.comparePoints(position, new Point(30, 40));
            
            matrix.identity();
            matrix.scale(0.5, 0.25);
            vd.transformVertex(1, matrix, 1);
            vd.getPosition(0, position);
            Helpers.comparePoints(position, new Point(15, 26));
            vd.getPosition(1, position);
            Helpers.comparePoints(position, new Point(15, 10));
        }
        
        [Test]
        public function testAppend():void
        {
            var vd1:VertexData = new VertexData(2);
            vd1.setPosition(0, 0, 1);
            vd1.setTexCoords(0, 0.0, 0.1);
            vd1.setColor(0, 0xf);
            vd1.setPosition(1, 2, 3);
            vd1.setTexCoords(1, 0.2, 0.3);
            vd1.setColor(1, 0xf0);
            
            var vd2:VertexData = new VertexData(1);
            vd2.setPosition(0, 4, 5);
            vd2.setTexCoords(0, 0.4, 0.5);
            vd2.setColor(0, 0xf00);
            
            vd1.append(vd2);
            
            for (var i:int=0; i<3; ++i)
            {
                var expectedPosition:Point = new Point(i*2, i*2+1);
                var position:Point = new Point();
                vd1.getPosition(i, position);
                Helpers.comparePoints(expectedPosition, position);
                
                var expectedTexCoords:Point = new Point(i*0.2, i*0.2+0.1);
                var texCoords:Point = new Point();
                vd1.getTexCoords(i, texCoords);
                Helpers.comparePoints(expectedTexCoords, texCoords);
                
                var expectedColor:uint = 0xf << (i*4);
                var color:uint = vd1.getColor(i);
                
                assertEquals(color, vd1.getColor(i));
            }
        }
    }
}