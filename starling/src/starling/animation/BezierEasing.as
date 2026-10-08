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

            // x(t) = ((2a * t + 3b) * t + 3c) * t, y(t) = ((ay * t + by) * t + cy) * t
            var a:Number = (3 * x1 - 3 * x2 + 1) / 2;
            var b:Number = x2 - 2 * x1;
            var c:Number = x1;
            var ay:Number = 3 * y1 - 3 * y2 + 1;
            var by:Number = 3 * (y2 - 2 * y1);
            var cy:Number = 3 * y1;

            return bezierEasing;

            function bezierEasing(ratio:Number):Number
            {
                // ratio outside (0, 1) saturates to 0 / 1
                if (ratio <= 0) return 0;
                else if (ratio >= 1) return 1;
                else if (isNaN(ratio)) return ratio;
                var t:Number = solveTForX(ratio, a, b, c);
                return ((ay * t + by) * t + cy) * t;
            }
        }

        // Solves x(t) = ((2a * t + 3b) * t + 3c) * t = x for t, with x in (0, 1):
        // u = 1/t is the largest real root of x·u³ − 3c·u² − 3b·u − 2a = 0
        private static function solveTForX(x:Number, a:Number, b:Number, c:Number):Number
        {
            var j:Number = 1 / Math.max(c, Math.sqrt(x));
            var k:Number = x * j;
            var l:Number = k * j;
            var s:Number = c * j;
            var q:Number = b * l;
            var m:Number = s * s + q;
            var h:Number = -s * (s * s + 1.5 * q) - a * k * l;
            var d:Number = h * h - m * m * m;
            var v:Number;
            if (m == 0 || d > 1e-12 * h * h)
            {
                // one real root (Cardano)
                var w:Number = h < 0 ? h - Math.sqrt(d) : h + Math.sqrt(d);
                var u:Number = w < 0 ? Math.pow(-w, 1 / 3) : -Math.pow(w, 1 / 3);
                v = u + m / u;
                if (isNaN(v)) v = 0; // triple root (m = h = 0)
            }
            else
            {
                // three real roots, take the largest
                var r:Number = Math.sqrt(m);
                v = 2 * r * Math.cos(Math.acos(Math.max(-1, Math.min(1, -h / (m * r)))) / 3);
            }
            return Math.min(1, k / (v + s));
        }

        private static function linearEasing(ratio:Number):Number { return ratio; }
    }
}
