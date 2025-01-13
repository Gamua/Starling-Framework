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
    import flash.geom.Point;
    import flash.geom.Vector3D;

    import starling.unit.UnitTest;
    import starling.utils.MathUtil;

    public class MathUtilTest extends UnitTest
    {
        private static const E:Number = 0.0001;

        public function testNormalizeAngle():void
        {
            assertEquivalent(MathUtil.normalizeAngle(-5 * Math.PI), -Math.PI);
            assertEquivalent(MathUtil.normalizeAngle(-3 * Math.PI), -Math.PI);
            assertEquivalent(MathUtil.normalizeAngle(-2 * Math.PI), 0);
            assertEquivalent(MathUtil.normalizeAngle(-1 * Math.PI), -Math.PI);
            assertEquivalent(MathUtil.normalizeAngle( 0 * Math.PI), 0);
            assertEquivalent(MathUtil.normalizeAngle( 1 * Math.PI), Math.PI);
            assertEquivalent(MathUtil.normalizeAngle( 2 * Math.PI), 0);
            assertEquivalent(MathUtil.normalizeAngle( 3 * Math.PI), Math.PI);
            assertEquivalent(MathUtil.normalizeAngle( 5 * Math.PI), Math.PI);
        }

        public function testIntersectLineWithXYPlane():void
        {
            var pointA:Vector3D = new Vector3D(6, 8, 6);
            var pointB:Vector3D = new Vector3D(18, 23, 24);
            var result:Point = MathUtil.intersectLineWithXYPlane(pointA, pointB);
            assertEquivalent(result.x, 2);
            assertEquivalent(result.y, 3);
        }

        public function testGetNextPowerOfTwo():void
        {
            assertEqual(1,   MathUtil.getNextPowerOfTwo(0));
            assertEqual(1,   MathUtil.getNextPowerOfTwo(1));
            assertEqual(2,   MathUtil.getNextPowerOfTwo(2));
            assertEqual(4,   MathUtil.getNextPowerOfTwo(3));
            assertEqual(4,   MathUtil.getNextPowerOfTwo(4));
            assertEqual(8,   MathUtil.getNextPowerOfTwo(6));
            assertEqual(32,  MathUtil.getNextPowerOfTwo(17));
            assertEqual(64,  MathUtil.getNextPowerOfTwo(63));
            assertEqual(256, MathUtil.getNextPowerOfTwo(129));
            assertEqual(256, MathUtil.getNextPowerOfTwo(255));
            assertEqual(256, MathUtil.getNextPowerOfTwo(256));
        }
    }
}