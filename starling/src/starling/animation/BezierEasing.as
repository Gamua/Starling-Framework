package starling.animation
{
    import starling.errors.AbstractClassError;

    /** Provides Cubic Bezier Curve easing, which generalizes easing functions
     *  via a four-point bezier curve. That way, you can easily create custom easing functions
     *  that will be picked up by Starling's Tween class later. To set up your bezier curves,
     *  best use a visual tool like <a href="http://cubic-bezier.com/">cubic-bezier.com</a> or
     *  <a href="http://matthewlein.com/ceaser/">Ceaser</a>.
     *
     *  <p>For example, you can add the transitions recommended by Google's Material Design
     *  standards (see <a href="https://material.io/design/motion/speed.html#easing">here</a>)
     *  like this:</p>
     *
     *  <listing>
     *  Transitions.register("standard",   BezierEasing.create(0.4, 0.0, 0.2, 1.0));
     *  Transitions.register("decelerate", BezierEasing.create(0.0, 0.0, 0.2, 1.0));
     *  Transitions.register("accelerate", BezierEasing.create(0.4, 0.0, 1.0, 1.0));</listing>
     *
     *  <p>The <code>create</code> method returns a function that can be registered directly
     *  at the "Transitions" class.</p>
     *
     *  <p>Code based on <a href="http://github.com/gre/bezier-easing">gre/bezier-easing</a>
     *  and its <a href="http://wiki.starling-framework.org/extensions/bezier_easing">Starling
     *  adaptation</a> by Rodrigo Lopez.</p>
     *
     *  @see starling.animation.Transitions
     *  @see starling.animation.Juggler
     *  @see starling.animation.Tween
     */
    public class BezierEasing
    {
        private static const NEWTON_ITERATIONS:int = 4;
        private static const NEWTON_MIN_SLOPE:Number = 0.001;
        private static const SUBDIVISION_PRECISION:Number = 0.0000001;
        private static const SUBDIVISION_MAX_ITERATIONS:int = 10;
        private static const SPLINE_TABLE_SIZE:int = 11;
        private static const SAMPLE_STEP_SIZE:Number = 1.0 / (SPLINE_TABLE_SIZE - 1.0);

        /** @private */
        public function BezierEasing() { throw new AbstractClassError(); }

        /** Create an easing function that's defined by two control points of a bezier curve.
         *  The curve will always go directly through points 0 and 3, which are fixed at
         *  (0, 0) and (1, 1), respectively. Points 1 and 2 define the curvature of the bezier
         *  curve.
         *
         *  <p>The result of this method is best passed directly to
         *  <code>Transitions.create()</code>.</p>
         *
         *  @param x1   The x coordinate of control point 1.
         *  @param y1   The y coordinate of control point 1.
         *  @param x2   The x coordinate of control point 2.
         *  @param y2   The y coordinate of control point 2.
         *  @return     The transition function, which takes exactly one 'ratio:Number' parameter.
         */
        public static function create(x1:Number, y1:Number, x2:Number, y2:Number):Function
        {
            if (x1 < 0 || x1 > 1 || x2 < 0 || x2 > 1)
                throw new ArgumentError("x values must be in range [0, 1]");

            if (x1 == y1 && x2 == y2)
                return linearEasing;

            var sampleValues:Array = []; // pre-computed samples table

            for (var i:int = 0; i < SPLINE_TABLE_SIZE; ++i)
                sampleValues[i] = calcBezier(i * SAMPLE_STEP_SIZE, x1, x2);

            return bezierEasing;

            function getTForX(x:Number):Number
            {
                var intervalStart:Number = 0.0;
                var currentSample:int = 1;
                var lastSample:int = SPLINE_TABLE_SIZE - 1;

                for (; currentSample != lastSample && sampleValues[currentSample] <= x; ++currentSample)
                    intervalStart += SAMPLE_STEP_SIZE;

                --currentSample;

                // interpolate to provide an initial guess for t
                var dist:Number = (x - sampleValues[currentSample]) / (sampleValues[currentSample + 1] - sampleValues[currentSample]);
                var guessForT:Number = intervalStart + dist * SAMPLE_STEP_SIZE;

                var initialSlope:Number = getSlope(guessForT, x1, x2);
                if (initialSlope >= NEWTON_MIN_SLOPE)
                    return newtonRaphsonIterate(x, guessForT, x1, x2);
                else if (initialSlope === 0.0)
                    return guessForT;
                else
                    return binarySubdivide(x, intervalStart, intervalStart + SAMPLE_STEP_SIZE, x1, x2);
            }

            function bezierEasing(ratio:Number):Number
            {
                if (ratio == 0) return 0;
                else if (ratio == 1) return 1;
                else return calcBezier(getTForX(ratio), y1, y2);
            }
        }

        // Returns x(t) given t, x1, and x2, or y(t) given t, y1, and y2.
        private static function calcBezier(t:Number, a1:Number, a2:Number):Number
        {
            return (((1 - 3 * a2 + 3 * a1) * t + (3 * a2 - 6 * a1)) * t + (3 * a1)) * t;
        }

        // Returns dx/dt given t, x1, and x2, or dy/dt given t, y1, and y2.
        private static function getSlope(t:Number, a1:Number, a2:Number):Number
        {
            return 3 * (1 - 3 * a2 + 3 * a1) * t * t + 2 * (3 * a2 - 6 * a1) * t + (3 * a1);
        }

        private static function binarySubdivide(ratio:Number, a:Number, b:Number, x1:Number, x2:Number):Number
        {
            var currentX:Number, t:Number, i:uint = 0;

            do
            {
                t = a + (b - a) / 2;
                currentX = calcBezier(t, x1, x2) - ratio;
                if (currentX > 0) b = t;
                else a = t;
            }
            while (Math.abs(currentX) > SUBDIVISION_PRECISION && ++i < SUBDIVISION_MAX_ITERATIONS);

            return t;
        }

        private static function newtonRaphsonIterate(x:Number, t:Number, x1:Number, x2:Number):Number
        {
            for (var i:int = 0; i < NEWTON_ITERATIONS; ++i)
            {
                var currentSlope:Number = getSlope(t, x1, x2);
                if (currentSlope == 0.0) return t;
                var currentX:Number = calcBezier(t, x1, x2) - x;
                t -= currentX / currentSlope;
            }
            return t;
        }

        private static function linearEasing(ratio:Number):Number { return ratio; }
    }
}
