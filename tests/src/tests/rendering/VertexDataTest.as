// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.rendering
{
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;

    import starling.rendering.VertexData;
    import starling.rendering.VertexDataFormat;
    import starling.unit.UnitTest;
    import starling.utils.Color;

    public class VertexDataTest extends UnitTest
    {
        private static const E:Number = 0.001;
        private static const STD_FORMAT:String = "position:float2, texCoords:float2, color:bytes4";

        public function testNumVertices():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT);
            assertEqual(0, vd.numVertices);

            vd.setPoint(0, "position", 1, 2);
            vd.setPoint(0, "texCoords", 0.1, 0.2)
            assertEqual(1, vd.numVertices);
            assertEqual(1.0, vd.getAlpha(0));
            assertEqual(0xffffff, vd.getColor(0));
            assertEqualPoints(new Point(1, 2), vd.getPoint(0, "position"));
            assertEqualPoints(new Point(0.1, 0.2), vd.getPoint(0, "texCoords"));

            vd.setAlpha(2, "color", 0.5);
            assertEqual(3, vd.numVertices);
            assertEqual(1.0, vd.getAlpha(1));
            assertEqual(0xffffff, vd.getColor(1));
            assertEquivalent(vd.getAlpha(2), 0.5, 0.003);

            vd.numVertices = 0;
            assertEqual(0, vd.numVertices);

            vd.numVertices = 10;
            assertEqual(10, vd.numVertices);

            for (var i:int=0; i<10; ++i)
            {
                assertEqual(1.0, vd.getAlpha(i));
                assertEqual(0xffffff, vd.getColor(i));
                assertEqualPoints(vd.getPoint(i, "position"), new Point());
                assertEqualPoints(vd.getPoint(i, "texCoords"), new Point());
            }
        }

        public function testBoundsLow():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT);
            vd.numVertices = 3;
            assertThrows(function():void { vd.getColor(-1, "color"); });
        }

        public function testBoundsHigh():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT);
            vd.numVertices = 3;
            assertThrows(function():void { vd.getColor(3, "color"); });
        }

        public function testWriteAndReadSimpleAttributes():void
        {
            var vd:VertexData = new VertexData("pos1D:float1, pos2D:float2, pos3D:float3, pos4D:float4");
            vd.numVertices = 3;

            vd.setFloat(1, "pos1D", 0.5);
            assertEquivalent(0.0, vd.getFloat(0, "pos1D"), E);
            assertEquivalent(0.5, vd.getFloat(1, "pos1D"), E);
            assertEquivalent(0.0, vd.getFloat(2, "pos1D"), E);

            var origin:Point = new Point();
            var point:Point = new Point(20, 40);
            vd.setPoint(1, "pos2D", point.x, point.y);
            assertEqualPoints(origin, vd.getPoint(0, "pos2D"));
            assertEqualPoints(point,  vd.getPoint(1, "pos2D"));
            assertEqualPoints(origin, vd.getPoint(2, "pos2D"));

            var origin3D:Vector3D = new Vector3D();
            var vector3D:Vector3D = new Vector3D(1.0, 2.0, 3.0);
            vd.setPoint3D(1, "pos3D", vector3D.x, vector3D.y, vector3D.z);
            assertEqualVector3Ds(origin3D, vd.getPoint3D(0, "pos3D"));
            assertEqualVector3Ds(vector3D, vd.getPoint3D(1, "pos3D"));
            assertEqualVector3Ds(origin3D, vd.getPoint3D(2, "pos3D"));

            var origin4D:Vector3D = new Vector3D();
            var vector4D:Vector3D = new Vector3D(1.0, 2.0, 3.0, 4.0);
            vd.setPoint4D(1, "pos4D", vector4D.x, vector4D.y, vector4D.z, vector4D.w);
            assertEqualVector3Ds(origin4D, vd.getPoint4D(0, "pos4D"));
            assertEqualVector3Ds(vector4D, vd.getPoint4D(1, "pos4D"));
            assertEqualVector3Ds(origin4D, vd.getPoint4D(2, "pos4D"));
        }

        public function testColor():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT);
            vd.numVertices = 3;
            vd.premultipliedAlpha = true;

            assertEqual(3, vd.numVertices);
            assertTrue(vd.premultipliedAlpha);

            // per default, colors must be white with full alpha
            for (var i:int=0; i<3; ++i)
            {
                assertEqual(1.0, vd.getAlpha(i));
                assertEqual(0xffffff, vd.getColor(i));
            }

            vd.setColor(0, "color", 0xffaabb);
            vd.setColor(1, "color", 0x112233);

            assertEqual(0xffaabb, vd.getColor(0, "color"));
            assertEqual(0x112233, vd.getColor(1, "color"));
            assertEqual(1.0, vd.getAlpha(0, "color"));

            // check premultiplied alpha

            var alpha:Number = 0.8;
            var red:int   = 80;
            var green:int = 60;
            var blue:int  = 40;
            var rgb:uint = Color.rgb(red, green, blue);

            vd.setColor(2, "color", rgb);
            vd.setAlpha(2, "color", alpha);
            assertEqual(rgb, vd.getColor(2, "color"));
            assertEqual(1.0, vd.getAlpha(1, "color"));
            assertEqual(alpha, vd.getAlpha(2, "color"));

            var data:ByteArray = vd.rawData;
            var offset:int = (vd.vertexSize * 2 + vd.getOffset("color"));

            assertEqual(data[offset  ], int(red   * alpha));
            assertEqual(data[offset+1], int(green * alpha));
            assertEqual(data[offset+2], int(blue  * alpha));

            // changing the pma setting should update contents

            vd.setPremultipliedAlpha(false, true);
            assertFalse(vd.premultipliedAlpha);

            assertEqual(0xffaabb, vd.getColor(0, "color"));
            assertEqual(0x112233, vd.getColor(1, "color"));
            assertEqual(1.0, vd.getAlpha(0, "color"));

            vd.setColor(2, "color", rgb);
            vd.setAlpha(2, "color", alpha);
            assertEqual(rgb, vd.getColor(2, "color"));
            assertEqual(alpha, vd.getAlpha(2, "color"));

            assertEqual(data[offset  ], red);
            assertEqual(data[offset+1], green);
            assertEqual(data[offset+2], blue);
        }

        public function testScaleAlpha():void
        {
            makeTest(true);
            makeTest(false);

            function makeTest(pma:Boolean):void
            {
                var i:int;
                var vd:VertexData = new VertexData(STD_FORMAT);
                vd.numVertices = 3;
                vd.premultipliedAlpha = pma;
                vd.colorize("color", 0xffffff, 0.9);
                vd.scaleAlphas("color", 0.9);

                for (i=0; i<3; ++i)
                {
                    assertEquivalent(vd.getAlpha(i), 0.81, 0.005);
                    assertEqual(0xffffff, vd.getColor(i));
                }
            }
        }

        public function testTranslatePoint():void
        {
            var vd:VertexData = new VertexData("pos:float2");
            vd.setPoint(0, "pos", 10, 20);
            vd.setPoint(1, "pos", 30, 40);
            vd.translatePoints("pos", 5, 6, 0, -1);
            assertEqualPoints(new Point(15, 26), vd.getPoint(0, "pos"));
            assertEqualPoints(new Point(35, 46), vd.getPoint(1, "pos"));
        }

        public function testGetBounds():void
        {
            var vd:VertexData = new VertexData("position:float2");
            var bounds:Rectangle = vd.getBounds();
            var expectedBounds:Rectangle = new Rectangle();

            assertEqualRectangles(expectedBounds, bounds);

            vd.numVertices = 2;
            vd.setPoint(0, "position", -10, -5);
            vd.setPoint(1, "position", 10, 5);

            bounds = vd.getBounds();
            expectedBounds = new Rectangle(-10, -5, 20, 10);

            assertEqualRectangles(expectedBounds, bounds);

            var matrix:Matrix = new Matrix();
            matrix.translate(10, 5);
            bounds = vd.getBounds("position", matrix);
            expectedBounds = new Rectangle(0, 0, 20, 10);

            assertEqualRectangles(expectedBounds, bounds);
        }

        public function testGetBoundsProjected():void
        {
            var camPos:Vector3D = new Vector3D(0, 0, 10);
            var vd:VertexData = new VertexData("pos:float2");
            var bounds:Rectangle = vd.getBoundsProjected("pos", null, camPos);
            var expectedBounds:Rectangle = new Rectangle();

            assertEqualRectangles(expectedBounds, bounds);

            var matrix3D:Matrix3D = new Matrix3D();
            matrix3D.appendTranslation(0, 0, 5);

            vd.numVertices = 3;
            vd.setPoint(0, "pos", 0, 0);
            vd.setPoint(1, "pos", 5, 0);
            vd.setPoint(2, "pos", 0, 5);
            bounds = vd.getBoundsProjected("pos", matrix3D, camPos);
            expectedBounds.setTo(0, 0, 10, 10);

            assertEqualRectangles(expectedBounds, bounds);
        }

        public function testClone():void
        {
            var vd1:VertexData = new VertexData(STD_FORMAT, 2);
            vd1.setPoint(0, "position", 1, 2);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(0, "texCoords", 0.1, 0.2);
            vd1.setPoint(1, "position", 3, 4);
            vd1.setColor(1, "color", 0x334455);
            vd1.setPoint(1, "texCoords", 0.3, 0.4);

            var clone:VertexData = vd1.clone();
            assertEqual(vd1.numVertices, clone.numVertices);
            assertEqualByteArrays(vd1.rawData, clone.rawData);
        }

        public function testCopyToWithIdenticalFormats():void
        {
            var vd1:VertexData = new VertexData(STD_FORMAT, 2);
            vd1.setPoint(0, "position", 1, 2);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(0, "texCoords", 0.1, 0.2);
            vd1.setPoint(1, "position", 3, 4);
            vd1.setColor(1, "color", 0x334455);
            vd1.setPoint(1, "texCoords", 0.3, 0.4);

            var vd2:VertexData = new VertexData(STD_FORMAT, 2);
            vd1.copyTo(vd2);

            assertEqualByteArrays(vd1.rawData, vd2.rawData);
            assertEqual(vd1.numVertices, vd2.numVertices);

            vd1.copyTo(vd2, 2);
            assertEqual(4, vd2.numVertices);

            vd1.rawData.position = 0;
            vd2.rawData.position = vd2.vertexSize * 2;

            for (var i:int=0; i<2; ++i)
                for (var j:int=0; j<vd2.vertexSizeIn32Bits; ++j)
                    assertEqual(vd1.rawData.readUnsignedInt(), vd2.rawData.readUnsignedInt());
        }

        public function testCopyToWithDifferentFormats():void
        {
            var vd1:VertexData = new VertexData(STD_FORMAT);
            vd1.setPoint(0, "position", 1, 2);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(0, "texCoords", 0.1, 0.2);
            vd1.setPoint(1, "position", 3, 4);
            vd1.setColor(1, "color", 0x334455);
            vd1.setPoint(1, "texCoords", 0.3, 0.4);

            var vd2:VertexData = new VertexData("texCoords:float2");
            vd1.copyTo(vd2);

            assertEqual(2, vd2.numVertices);
            assertEqualPoints(vd1.getPoint(0, "texCoords"), vd2.getPoint(0, "texCoords"));
            assertEqualPoints(vd1.getPoint(1, "texCoords"), vd2.getPoint(1, "texCoords"));

            var origin:Point = new Point();
            var vd3:VertexData = new VertexData(STD_FORMAT);
            vd2.copyTo(vd3);

            assertEqual(2, vd3.numVertices);
            assertEqualPoints(vd1.getPoint(0, "texCoords"), vd3.getPoint(0, "texCoords"));
            assertEqualPoints(vd1.getPoint(1, "texCoords"), vd3.getPoint(1, "texCoords"));
            assertEqualPoints(origin, vd3.getPoint(0, "position"));
            assertEqualPoints(origin, vd3.getPoint(1, "position"));
            assertEqual(0xffffff, vd3.getColor(0, "color"));
            assertEqual(0xffffff, vd3.getColor(1, "color"));
            assertEqual(1.0, vd3.getAlpha(0, "color"));
            assertEqual(1.0, vd3.getAlpha(1, "color"));
        }

        public function testCopyToTransformedWithIdenticalFormats():void
        {
            var format:String = "pos:float2, color:bytes4";
            var vd1:VertexData = new VertexData(format);
            vd1.setPoint(0, "pos", 10, 20);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(1, "pos", 30, 40);
            vd1.setColor(1, "color", 0x334455);

            var matrix:Matrix = new Matrix();
            matrix.translate(5, 6);

            var vd2:VertexData = new VertexData(format);
            vd1.copyTo(vd2, 0, matrix);

            assertEqual(0xaabbcc, vd2.getColor(0, "color"));
            assertEqual(0x334455, vd2.getColor(1, "color"));

            var p1:Point = new Point(15, 26);
            var p2:Point = new Point(35, 46);

            assertEqualPoints(p1, vd2.getPoint(0, "pos"));
            assertEqualPoints(p2, vd2.getPoint(1, "pos"));
        }

        public function testCopyToTransformedWithDifferentFormats():void
        {
            var format:String = "color:bytes4, position:float2";
            var vd1:VertexData = new VertexData(format);
            vd1.setPoint(0, "position", 10, 20);
            vd1.setColor(0, "color", 0xaabbcc);
            vd1.setPoint(1, "position", 30, 40);
            vd1.setColor(1, "color", 0x334455);

            var matrix:Matrix = new Matrix();
            matrix.translate(5, 6);

            var vd2:VertexData = new VertexData("position:float2, flavor:float1");
            vd1.copyTo(vd2, 0, matrix);

            assertEqual(0.0, vd2.getFloat(0, "flavor"));
            assertEqual(0.0, vd2.getFloat(1, "flavor"));

            var p1:Point = new Point(15, 26);
            var p2:Point = new Point(35, 46);

            assertEqualPoints(p1, vd2.getPoint(0, "position"));
            assertEqualPoints(p2, vd2.getPoint(1, "position"));
        }

        public function testTransformPoints():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT);
            vd.setPoint(0, "position", 10, 20);
            vd.setPoint(1, "position", 30, 40);

            var matrix:Matrix = new Matrix();
            matrix.translate(5, 6);

            var position:Point = new Point();
            vd.transformPoints("position", matrix, 0, 1);
            vd.getPoint(0, "position", position);
            assertEqualPoints(position, new Point(15, 26));
            vd.getPoint(1, "position", position);
            assertEqualPoints(position, new Point(30, 40));

            matrix.identity();
            matrix.scale(0.5, 0.25);
            vd.transformPoints("position", matrix, 1, 1);
            vd.getPoint(0, "position", position);
            assertEqualPoints(position, new Point(15, 26));
            vd.getPoint(1, "position", position);
            assertEqualPoints(position, new Point(15, 10));
        }

        public function testTinted():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT);
            assertFalse(vd.tinted);

            vd.numVertices = 1;
            assertEqual(1.0, vd.getAlpha(0));
            assertEqual(0xffffff, vd.getColor(0));
            assertFalse(vd.tinted);

            vd.setColor(0, "color", 0xff0000);
            assertTrue(vd.tinted);

            vd.colorize();
            assertFalse(vd.tinted);

            vd.setAlpha(0, "color", 0.5);
            assertTrue(vd.tinted);

            vd.colorize();
            assertFalse(vd.tinted);

            var vd2:VertexData = new VertexData(STD_FORMAT);
            vd2.numVertices = 1;
            vd2.colorize("color", 0xff00ff, 0.8);
            assertTrue(vd2.tinted);

            vd2.copyTo(vd, 1);
            assertEqual(2, vd.numVertices);
            assertTrue(vd.tinted);

            vd.colorize();
            assertFalse(vd.tinted);

            vd.scaleAlphas("color", 0.5);
            assertTrue(vd.tinted);
        }

        public function testChangeFormat():void
        {
            var vd:VertexData = new VertexData(STD_FORMAT);
            var p0:Point = new Point(10, 20);
            var p1:Point = new Point(30, 40);
            vd.setPoint(0, "position", p0.x, p0.y);
            vd.setPoint(1, "position", p1.x, p1.y);

            vd.format = VertexDataFormat.fromString(
                    "newCoords:float2, position:float2, newColor:bytes4");

            assertEqualPoints(p0, vd.getPoint(0, "position"));
            assertEqualPoints(p1, vd.getPoint(1, "position"));
            assertEqualPoints(new Point(), vd.getPoint(0, "newCoords"));
            assertEqualPoints(new Point(), vd.getPoint(1, "newCoords"));
            assertEqual(0xffffff, vd.getColor(0, "newColor"));
            assertEqual(0xffffff, vd.getColor(1, "newColor"));
            assertEqual(1.0, vd.getAlpha(0, "newColor"));
            assertEqual(1.0, vd.getAlpha(1, "newColor"));
        }
    }
}
