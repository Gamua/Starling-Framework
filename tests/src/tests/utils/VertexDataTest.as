// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;
    import org.hamcrest.number.closeTo;

    import starling.utils.Color;
    import starling.utils.VertexData;

    import tests.Helpers;

    public class VertexDataTest
    {
        private static const E:Number = 0.001;
        private static const STD_FORMAT:String = "position(float2), color(bytes4), texCoords(float2)";

        [Test]
        public function testFormatParsing():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT, 0);

            assertEquals(2, vd.getSizeIn32Bits("position"));
            assertEquals(8, vd.getSizeInBytes("position"));
            assertEquals(1, vd.getSizeIn32Bits("color"));
            assertEquals(4, vd.getSizeInBytes("color"));
            assertEquals(2, vd.getSizeIn32Bits("texCoords"));
            assertEquals(8, vd.getSizeInBytes("texCoords"));

            assertEquals(0, vd.numVertices);
            assertEquals(5, vd.vertexSizeIn32Bits);
            assertEquals(20, vd.vertexSizeInBytes);

            assertEquals("float2", vd.getFormat("position"));
            assertEquals("bytes4", vd.getFormat("color"));
            assertEquals("float2", vd.getFormat("texCoords"));

            assertEquals(0, vd.getOffsetIn32Bits("position"));
            assertEquals(0, vd.getOffsetInBytes("position"));
            assertEquals(2, vd.getOffsetIn32Bits("color"));
            assertEquals(8, vd.getOffsetInBytes("color"));
            assertEquals(3, vd.getOffsetIn32Bits("texCoords"));
            assertEquals(12, vd.getOffsetInBytes("texCoords"));

            assertEquals(STD_FORMAT, vd.format);
        }

        [Test(expects="Error")]
        public function testEmptyFormatString():void
        {
            new VertexData("", 3);
        }

        [Test(expects="Error")]
        public function testInvalidFormatString():void
        {
            new VertexData("color(double2)", 1);
        }

        [Test(expects="Error")]
        public function testInvalidFormatString2():void
        {
            new VertexData("color.float4", 1);
        }

        [Test]
        public function testNormalizeFormat():void
        {
            var format:String = " flavor (float1) , direction( float2 ),count(bytes4)  ";
            var vd:VertexData = new VertexData(format, 0);

            assertEquals("flavor(float1), direction(float2), count(bytes4)", vd.format);
        }

        [Test]
        public function testGetNumVertices():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT, 4);
            assertEquals(4, vd.numVertices);
        }

        [Test(expects="Error")]
        public function testBoundsLow():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT, 3);
            vd.getColor(-1, "color");
        }

        [Test(expects="Error")]
        public function testBoundsHigh():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT, 3);
            vd.getColor(3, "color");
        }

        [Test]
        public function testWriteAndReadSimpleAttributes():void
        {
            var vd:VertexData = new VertexData(
                "pos1D(float1), pos2D(float2), pos3D(float3), pos4D(float4)", 3);

            vd.setFloat(1, "pos1D", 0.5);
            assertThat(0.0, closeTo(vd.getFloat(0, "pos1D"), E));
            assertThat(0.5, closeTo(vd.getFloat(1, "pos1D"), E));
            assertThat(0.0, closeTo(vd.getFloat(2, "pos1D"), E));

            var origin:Point = new Point();
            var point:Point = new Point(20, 40);
            vd.setPoint(1, "pos2D", point.x, point.y);
            Helpers.comparePoints(origin, vd.getPoint(0, "pos2D"));
            Helpers.comparePoints(point,  vd.getPoint(1, "pos2D"));
            Helpers.comparePoints(origin, vd.getPoint(2, "pos2D"));

            var origin3D:Vector3D = new Vector3D();
            var vector3D:Vector3D = new Vector3D(1.0, 2.0, 3.0);
            vd.setPoint3D(1, "pos3D", vector3D.x, vector3D.y, vector3D.z);
            Helpers.compareVector3Ds(origin3D, vd.getPoint3D(0, "pos3D"));
            Helpers.compareVector3Ds(vector3D, vd.getPoint3D(1, "pos3D"));
            Helpers.compareVector3Ds(origin3D, vd.getPoint3D(2, "pos3D"));

            var origin4D:Vector3D = new Vector3D();
            var vector4D:Vector3D = new Vector3D(1.0, 2.0, 3.0, 4.0);
            vd.setPoint4D(1, "pos4D", vector4D.x, vector4D.y, vector4D.z, vector4D.w);
            Helpers.compareVector3Ds(origin4D, vd.getPoint4D(0, "pos4D"));
            Helpers.compareVector3Ds(vector4D, vd.getPoint4D(1, "pos4D"));
            Helpers.compareVector3Ds(origin4D, vd.getPoint4D(2, "pos4D"));
        }

        [Test]
        public function testColor():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT, 3);
            vd.setPremultipliedAlpha("color");

            assertEquals(3, vd.numVertices);
            assertTrue(vd.getPremultipliedAlpha("color"));

            // per default, all alpha values should be '1.0'
            assertEquals(1.0, vd.getAlpha(0, "color"));
            assertEquals(1.0, vd.getAlpha(1, "color"));
            assertEquals(1.0, vd.getAlpha(2, "color"));

            vd.setColor(0, "color", 0xffaabb);
            vd.setColor(1, "color", 0x112233);

            assertEquals(0xffaabb, vd.getColor(0, "color"));
            assertEquals(0x112233, vd.getColor(1, "color"));
            assertEquals(1.0, vd.getAlpha(0, "color"));

            // check premultiplied alpha

            var alpha:Number = 0.8;
            var red:int   = 80;
            var green:int = 60;
            var blue:int  = 40;
            var rgb:uint = Color.rgb(red, green, blue);

            vd.setColor(2, "color", rgb);
            vd.setAlpha(2, "color", alpha);
            assertEquals(rgb, vd.getColor(2, "color"));
            assertEquals(1.0, vd.getAlpha(1, "color"));
            assertEquals(alpha, vd.getAlpha(2, "color"));

            var data:ByteArray = vd.rawData;
            var offset:int = (vd.vertexSizeInBytes * 2 + vd.getOffsetInBytes("color"));

            assertEquals(data[offset  ], int(red   * alpha));
            assertEquals(data[offset+1], int(green * alpha));
            assertEquals(data[offset+2], int(blue  * alpha));

            // changing the pma setting should update contents

            vd.setPremultipliedAlpha("color", false);
            assertFalse(vd.getPremultipliedAlpha("color"));

            assertEquals(0xffaabb, vd.getColor(0, "color"));
            assertEquals(0x112233, vd.getColor(1, "color"));
            assertEquals(1.0, vd.getAlpha(0, "color"));

            vd.setColor(2, "color", rgb);
            vd.setAlpha(2, "color", alpha);
            assertEquals(rgb, vd.getColor(2, "color"));
            assertEquals(alpha, vd.getAlpha(2, "color"));

            assertEquals(data[offset  ], red);
            assertEquals(data[offset+1], green);
            assertEquals(data[offset+2], blue);
        }

        [Test]
        public function testSetUniformColorAndAlpha():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT, 3);
            vd.setUniformColorAndAlpha("color", 0x7f7f7f, 0.5);

            for (var i:int=0; i<3; ++i)
            {
                assertThat(vd.getAlpha(i), closeTo(0.5, 0.005));
                assertEquals(0x7f7f7f, vd.getColor(i));
            }
        }

        [Test]
        public function testScaleAlpha():void
        {
            makeTest(true);
            makeTest(false);

            function makeTest(pma:Boolean):void
            {
                var vd:VertexData = new VertexData(STD_FORMAT, 3);
                vd.setPremultipliedAlpha("color", pma);
                vd.setUniformColorAndAlpha("color", 0xffffff, 0.9);
                vd.scaleAlphas("color", 0.9);

                for (var i:int=0; i<3; ++i)
                {
                    assertThat(vd.getAlpha(i), closeTo(0.81, 0.005));
                    assertEquals(0xffffff, vd.getColor(i));
                }
            }
        }

        [Test]
        public function testTranslatePoint():void
        {
            var vd:VertexData = new VertexData("pos(float2)", 2);
            vd.setPoint(0, "pos", 10, 20);
            vd.setPoint(1, "pos", 30, 40);
            vd.translatePoint(0, "pos", 5, 6);
            vd.translatePoint(1, "pos", 7, 8);
            Helpers.comparePoints(new Point(15, 26), vd.getPoint(0, "pos"));
            Helpers.comparePoints(new Point(37, 48), vd.getPoint(1, "pos"));
        }

        [Test]
        public function testGetBounds():void
        {
            var vd:VertexData = new VertexData("position(float2)", 0);
            var bounds:Rectangle = vd.getBounds();
            var expectedBounds:Rectangle = new Rectangle();

            Helpers.compareRectangles(expectedBounds, bounds);

            vd.numVertices = 2;
            vd.setPoint(0, "position", -10, -5);
            vd.setPoint(1, "position", 10, 5);

            bounds = vd.getBounds();
            expectedBounds = new Rectangle(-10, -5, 20, 10);

            Helpers.compareRectangles(expectedBounds, bounds);

            var matrix:Matrix = new Matrix();
            matrix.translate(10, 5);
            bounds = vd.getBounds("position", matrix);
            expectedBounds = new Rectangle(0, 0, 20, 10);

            Helpers.compareRectangles(expectedBounds, bounds);
        }

        [Test]
        public function testGetBoundsProjected():void
        {
            var camPos:Vector3D = new Vector3D(0, 0, 10);
            var vd:VertexData = new VertexData("pos(float2)", 0);
            var bounds:Rectangle = vd.getBoundsProjected("pos", null, camPos);
            var expectedBounds:Rectangle = new Rectangle();

            Helpers.compareRectangles(expectedBounds, bounds);

            var matrix3D:Matrix3D = new Matrix3D();
            matrix3D.appendTranslation(0, 0, 5);

            vd.numVertices = 3;
            vd.setPoint(0, "pos", 0, 0);
            vd.setPoint(1, "pos", 5, 0);
            vd.setPoint(2, "pos", 0, 5);
            bounds = vd.getBoundsProjected("pos", matrix3D, camPos);
            expectedBounds.setTo(0, 0, 10, 10);

            Helpers.compareRectangles(expectedBounds, bounds);
        }

        [Test]
        public function testCopyToWithIdenticalFormats():void
        {
            var vd1:VertexData = new VertexData(STD_FORMAT, 2);
            vd1.setPoint(0, "position", 1, 2);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(0, "texCoords", 0.1, 0.2);
            vd1.setPoint(1, "position", 3, 4);
            vd1.setColor(1, "color", 0x334455);
            vd1.setPoint(1, "texCoords", 0.3, 0.4);

            var vd2:VertexData = new VertexData(STD_FORMAT, 0);
            vd1.copyTo(vd2);

            Helpers.compareByteArrays(vd1.rawData, vd2.rawData);
            assertEquals(vd1.numVertices, vd2.numVertices);

            vd1.copyTo(vd2, 2);
            assertEquals(4, vd2.numVertices);

            vd1.rawData.position = 0;
            vd2.rawData.position = vd2.vertexSizeInBytes * 2;

            for (var i:int=0; i<2; ++i)
                for (var j:int=0; j<vd2.vertexSizeIn32Bits; ++j)
                    assertEquals(vd1.rawData.readUnsignedInt(), vd2.rawData.readUnsignedInt());
        }

        [Test]
        public function testCopyToWithDifferentFormats():void
        {
            var vd1:VertexData = new VertexData(STD_FORMAT, 2);
            vd1.setPoint(0, "position", 1, 2);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(0, "texCoords", 0.1, 0.2);
            vd1.setPoint(1, "position", 3, 4);
            vd1.setColor(1, "color", 0x334455);
            vd1.setPoint(1, "texCoords", 0.3, 0.4);

            var vd2:VertexData = new VertexData("texCoords(float2)", 0);
            vd1.copyTo(vd2);

            assertEquals(2, vd2.numVertices);
            Helpers.comparePoints(vd1.getPoint(0, "texCoords"), vd2.getPoint(0, "texCoords"));
            Helpers.comparePoints(vd1.getPoint(1, "texCoords"), vd2.getPoint(1, "texCoords"));

            var origin:Point = new Point();
            var vd3:VertexData = new VertexData(STD_FORMAT, 0);
            vd2.copyTo(vd3);

            assertEquals(2, vd3.numVertices);
            Helpers.comparePoints(vd1.getPoint(0, "texCoords"), vd3.getPoint(0, "texCoords"));
            Helpers.comparePoints(vd1.getPoint(1, "texCoords"), vd3.getPoint(1, "texCoords"));
            Helpers.comparePoints(origin, vd3.getPoint(0, "position"));
            Helpers.comparePoints(origin, vd3.getPoint(1, "position"));
            assertEquals(0x0, vd3.getColor(0, "color"));
            assertEquals(0x0, vd3.getColor(1, "color"));
            assertEquals(1.0, vd3.getAlpha(0, "color"));
            assertEquals(1.0, vd3.getAlpha(1, "color"));
        }

        [Test]
        public function testCopyToTransformedWithIdenticalFormats():void
        {
            var format:String = "pos(float2), color(bytes4)";
            var vd1:VertexData = new VertexData(format, 2);
            vd1.setPoint(0, "pos", 10, 20);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(1, "pos", 30, 40);
            vd1.setColor(1, "color", 0x334455);

            var matrix:Matrix = new Matrix();
            matrix.translate(5, 6);

            var vd2:VertexData = new VertexData(format, 2);
            vd1.copyToTransformed(vd2, 0, matrix);

            assertEquals(0xaabbcc, vd2.getColor(0, "color"));
            assertEquals(0x334455, vd2.getColor(1, "color"));

            var p1:Point = new Point(15, 26);
            var p2:Point = new Point(35, 46);

            Helpers.comparePoints(p1, vd2.getPoint(0, "pos"));
            Helpers.comparePoints(p2, vd2.getPoint(1, "pos"));
        }

        [Test]
        public function testCopyToTransformedWithDifferentFormats():void
        {
            var format:String = "color(bytes4), position(float2)";
            var vd1:VertexData = new VertexData(format, 2);
            vd1.setPoint(0, "position", 10, 20);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(1, "position", 30, 40);
            vd1.setColor(1, "color", 0x334455);

            var matrix:Matrix = new Matrix();
            matrix.translate(5, 6);

            var vd2:VertexData = new VertexData("position(float2), flavor(float1)", 2);
            vd1.copyToTransformed(vd2, 0, matrix);

            assertEquals(0.0, vd2.getFloat(0, "flavor"));
            assertEquals(0.0, vd2.getFloat(1, "flavor"));

            var p1:Point = new Point(15, 26);
            var p2:Point = new Point(35, 46);

            Helpers.comparePoints(p1, vd2.getPoint(0, "position"));
            Helpers.comparePoints(p2, vd2.getPoint(1, "position"));
        }

        [Test]
        public function testTransformPoints():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT, 2);
            vd.setPoint(0, "position", 10, 20);
            vd.setPoint(1, "position", 30, 40);

            var matrix:Matrix = new Matrix();
            matrix.translate(5, 6);

            var position:Point = new Point();
            vd.transformPoints("position", matrix, 0, 1);
            vd.getPoint(0, "position", position);
            Helpers.comparePoints(position, new Point(15, 26));
            vd.getPoint(1, "position", position);
            Helpers.comparePoints(position, new Point(30, 40));

            matrix.identity();
            matrix.scale(0.5, 0.25);
            vd.transformPoints("position", matrix, 1, 1);
            vd.getPoint(0, "position", position);
            Helpers.comparePoints(position, new Point(15, 26));
            vd.getPoint(1, "position", position);
            Helpers.comparePoints(position, new Point(15, 10));
        }
    }
}
