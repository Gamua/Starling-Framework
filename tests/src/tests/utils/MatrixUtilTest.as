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

    import starling.unit.UnitTest;
    import starling.utils.MatrixUtil;

    public class MatrixUtilTest extends UnitTest
    {
        public function testConvertTo3D():void
        {
            var i:int;
            var matrix:Matrix = new Matrix(1, 2, 3, 4, 5, 6);
            var matrix3D:Matrix3D = MatrixUtil.convertTo3D(matrix);
            var rawData:Vector.<Number> = matrix3D.rawData;

            assertEqual(1, rawData[0]);
            assertEqual(2, rawData[1]);
            assertEqual(3, rawData[4]);
            assertEqual(4, rawData[5]);
            assertEqual(5, rawData[12]);
            assertEqual(6, rawData[13]);

            for each (i in [2, 3, 6, 7, 8, 9, 11, 14])
                assertEqual(0, rawData[i]);

            for each (i in [10, 15])
                assertEqual(1, rawData[i]);
        }

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
            assertEqual(1, matrix.a);
            assertEqual(2, matrix.b);
            assertEqual(3, matrix.c);
            assertEqual(4, matrix.d);
            assertEqual(5, matrix.tx);
            assertEqual(6, matrix.ty);
        }

        public function testTransformPoint():void
        {
            var point:Point = new Point(1, 2);
            var matrix:Matrix = new Matrix(1, 2, 3, 4, 5, 6);
            var result1:Point = matrix.transformPoint(point);
            var result2:Point = MatrixUtil.transformPoint(matrix, point);
            assertTrue(result1.equals(result2));
        }

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
            assertTrue(result1.equals(result2));
        }

        public function testIsIdentity():void
        {
            var matrix:Matrix = new Matrix();
            assertTrue(MatrixUtil.isIdentity(matrix));

            matrix.translate(10, 20);
            matrix.rotate(0.5);
            assertFalse(MatrixUtil.isIdentity(matrix));

            matrix.identity();
            assertTrue(MatrixUtil.isIdentity(matrix));
        }

        public function testIsIdentity3D():void
        {
            var matrix:Matrix3D = new Matrix3D();
            assertTrue(MatrixUtil.isIdentity3D(matrix));

            matrix.appendTranslation(10, 20, 30);
            matrix.appendRotation(0.5, Vector3D.X_AXIS);
            assertFalse(MatrixUtil.isIdentity3D(matrix));

            matrix.identity();
            assertTrue(MatrixUtil.isIdentity3D(matrix));
        }
    }
}