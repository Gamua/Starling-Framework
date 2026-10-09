// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.animation
{
    import starling.animation.BezierEasing;
    import starling.unit.UnitTest;

    public class BezierEasingTest extends UnitTest
    {
        private static const E:Number = 1e-12;

        // includes steep curves with a vertical tangent and curves that overshoot in y
        private static const CURVES:Array = [
            [0.25, 0.1, 0.25, 1.0], [0.42, 0.0, 1.0, 1.0], [0.0, 0.0, 0.58, 1.0],
            [0.4, 0.0, 0.2, 1.0], [1.0, 0.0, 0.0, 1.0], [0.0, 1.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0], [1.0, 0.0, 1.0, 1.0], [0.0, 0.0, 1.0, 1.0],
            [0.68, -0.6, 0.32, 1.6], [0.5, 2.0, 0.5, -1.0], [0.99, 0.01, 0.01, 0.99],
            [0.1, 0.9, 0.9, 0.1], [0.3, 0.0, 0.3, 0.0], [1.0, 1.0, 0.0, 0.0]
        ];

        public function testEndpoints():void
        {
            for each (var c:Array in CURVES)
            {
                var easing:Function = BezierEasing.create(c[0], c[1], c[2], c[3]);
                assertEqual(0, easing(0), "f(0) != 0 for " + c);
                assertEqual(1, easing(1), "f(1) != 1 for " + c);
            }
        }

        public function testLinear():void
        {
            var easing:Function = BezierEasing.create(0.3, 0.3, 0.7, 0.7);
            assertEqual(0.25, easing(0.25));
            assertEqual(0.8,  easing(0.8));
        }

        public function testInvalidArguments():void
        {
            assertThrows(function():void { BezierEasing.create(-0.1, 0, 0.5, 1); }, ArgumentError);
            assertThrows(function():void { BezierEasing.create(0.5, 0, 1.1, 1); }, ArgumentError);
        }

        public function testMatchesReference():void
        {
            for each (var c:Array in CURVES)
            {
                var easing:Function = BezierEasing.create(c[0], c[1], c[2], c[3]);

                // offset by half a step to skip x = 0.5: at a vertical tangent, the
                // reference itself is only accurate to about the cube root of epsilon
                for (var i:int = 0; i < 1000; ++i)
                {
                    var x:Number = (i + 0.5) / 1000;
                    var expected:Number = referenceEasing(x, c[0], c[1], c[2], c[3]);
                    var actual:Number = easing(x);
                    if (Math.abs(actual - expected) > E)
                    {
                        fail("f(" + x + ") = " + actual + ", expected " + expected + " for " + c);
                        return;
                    }
                }
                succeed("matches reference for " + c);
            }
        }

        public function testSteepCurveIsMonotonic():void
        {
            var easing:Function = BezierEasing.create(1, 0, 0, 1);
            var last:Number = 0;

            for (var i:int = 1; i <= 10000; ++i)
            {
                var y:Number = easing(i / 10000);
                if (y < last)
                {
                    fail("not monotonic at x = " + (i / 10000) + ": " + y + " < " + last);
                    return;
                }
                last = y;
            }
            succeed("monotonic");
        }

        public function testSteepCurveNearCenter():void
        {
            var easing:Function = BezierEasing.create(1, 0, 0, 1);
            assertEquivalent(referenceEasing(0.4996, 1, 0, 0, 1), easing(0.4996), E);
            assertEqual(0.5, easing(0.5)); // the curve is point-symmetric
        }

        public function testRatioOutOfRangeSaturates():void
        {
            var easing:Function = BezierEasing.create(0.25, 0.1, 0.25, 1.0);
            assertEqual(0, easing(-0.5));
            assertEqual(1, easing(1.5));
            assertTrue(isNaN(easing(NaN)));
        }

        // Independent ground truth: x(t) is monotonic for x1, x2 in [0, 1], so plain
        // bisection is slow but cannot fail.
        private static function referenceEasing(x:Number, x1:Number, y1:Number,
                                                x2:Number, y2:Number):Number
        {
            var lo:Number = 0, hi:Number = 1, t:Number = 0.5;

            for (var i:int = 0; i < 100; ++i)
            {
                t = (lo + hi) / 2;
                if (bezier(t, x1, x2) < x) lo = t;
                else hi = t;
            }
            return bezier(t, y1, y2);
        }

        private static function bezier(t:Number, p1:Number, p2:Number):Number
        {
            var u:Number = 1 - t;
            return 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t;
        }
    }
}
