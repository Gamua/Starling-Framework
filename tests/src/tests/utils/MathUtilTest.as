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

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.hamcrest.number.closeTo;

    import starling.utils.MathUtil;

    public class MathUtilTest
    {
        private static const E:Number = 0.0001;

        [Test]
        public function testNormalizeAngle():void
        {
            assertThat(MathUtil.normalizeAngle(-5 * Math.PI), closeTo(-Math.PI, E));
            assertThat(MathUtil.normalizeAngle(-3 * Math.PI), closeTo(-Math.PI, E));
            assertThat(MathUtil.normalizeAngle(-2 * Math.PI), closeTo(0, E));
            assertThat(MathUtil.normalizeAngle(-1 * Math.PI), closeTo(-Math.PI, E));
            assertThat(MathUtil.normalizeAngle( 0 * Math.PI), closeTo(0, E));
            assertThat(MathUtil.normalizeAngle( 1 * Math.PI), closeTo(Math.PI, E));
            assertThat(MathUtil.normalizeAngle( 2 * Math.PI), closeTo(0, E));
            assertThat(MathUtil.normalizeAngle( 3 * Math.PI), closeTo(Math.PI, E));
            assertThat(MathUtil.normalizeAngle( 5 * Math.PI), closeTo(Math.PI, E));
        }

        [Test]
        public function testIntersectLineWithXYPlane():void
        {
            var pointA:Vector3D = new Vector3D(6, 8, 6);
            var pointB:Vector3D = new Vector3D(18, 23, 24);
            var result:Point = MathUtil.intersectLineWithXYPlane(pointA, pointB);
            assertThat(result.x, closeTo(2, E));
            assertThat(result.y, closeTo(3, E));
        }

        [Test]
        public function testGetNextPowerOfTwo():void
        {
            assertEquals(1,   MathUtil.getNextPowerOfTwo(0));
            assertEquals(1,   MathUtil.getNextPowerOfTwo(1));
            assertEquals(2,   MathUtil.getNextPowerOfTwo(2));
            assertEquals(4,   MathUtil.getNextPowerOfTwo(3));
            assertEquals(4,   MathUtil.getNextPowerOfTwo(4));
            assertEquals(8,   MathUtil.getNextPowerOfTwo(6));
            assertEquals(32,  MathUtil.getNextPowerOfTwo(17));
            assertEquals(64,  MathUtil.getNextPowerOfTwo(63));
            assertEquals(256, MathUtil.getNextPowerOfTwo(129));
            assertEquals(256, MathUtil.getNextPowerOfTwo(255));
            assertEquals(256, MathUtil.getNextPowerOfTwo(256));
        }
    }
}