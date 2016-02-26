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
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    import flexunit.framework.Assert;
    
    import starling.utils.MatrixUtil;

    public class MatrixUtilTest
    {
        [Test]
        public function testConvertTo3D():void
        {
            var i:int;
            var matrix:Matrix = new Matrix(1, 2, 3, 4, 5, 6);
            var matrix3D:Matrix3D = MatrixUtil.convertTo3D(matrix);
            var rawData:Vector.<Number> = matrix3D.rawData;

            Assert.assertEquals(1, rawData[0]);
            Assert.assertEquals(2, rawData[1]);
            Assert.assertEquals(3, rawData[4]);
            Assert.assertEquals(4, rawData[5]);
            Assert.assertEquals(5, rawData[12]);
            Assert.assertEquals(6, rawData[13]);

            for each (i in [2, 3, 6, 7, 8, 9, 11, 14])
                Assert.assertEquals(0, rawData[i]);

            for each (i in [10, 15])
                Assert.assertEquals(1, rawData[i]);
        }

        [Test]
        public function testConvertTo2D():void
        {
            var matrix:Matrix;
            var matrix3D:Matrix3D = new Matrix3D();
            var rawData:Vector.<Number> = matrix3D.rawData;

            rawData[ 0] = 1;
            rawData[ 1] = 2;
            rawData[ 4] = 3;
            rawData[ 5] = 4;
            rawData[12] = 5;
            rawData[13] = 6;
            matrix3D.copyRawDataFrom(rawData);

            matrix = MatrixUtil.convertTo2D(matrix3D);
            Assert.assertEquals(1, matrix.a);
            Assert.assertEquals(2, matrix.b);
            Assert.assertEquals(3, matrix.c);
            Assert.assertEquals(4, matrix.d);
            Assert.assertEquals(5, matrix.tx);
            Assert.assertEquals(6, matrix.ty);
        }

        [Test]
        public function testTransformPoint():void
        {
            var point:Point = new Point(1, 2);
            var matrix:Matrix = new Matrix(1, 2, 3, 4, 5, 6);
            var result1:Point = matrix.transformPoint(point);
            var result2:Point = MatrixUtil.transformPoint(matrix, point);
            Assert.assertTrue(result1.equals(result2));
        }

        [Test]
        public function testTransformPoint3D():void
        {
            var point:Vector3D = new Vector3D(1, 2, 3);
            var matrix3D:Matrix3D = new Matrix3D();
            var rawData:Vector.<Number> = matrix3D.rawData;

            for (var i:int=0; i<16; ++i)
                rawData[i] = i+1;

            matrix3D.copyRawDataFrom(rawData);
            var result1:Vector3D = matrix3D.transformVector(point);
            var result2:Vector3D = MatrixUtil.transformPoint3D(matrix3D, point);
            Assert.assertTrue(result1.equals(result2));
        }
    }
}