package starling.filters
{
    import starling.errors.AbstractClassError;

    /** An enumeration class with the available modes that are offered by the CompositeFilter
     *  to draw layers on top of each other.
     *
     *  @see starling.filters.CompositeFilter
     */
    public class CompositeMode
    {
        private static const allModes:Array = [
            NORMAL, INSIDE, INSIDE_KNOCKOUT, OUTSIDE, OUTSIDE_KNOCKOUT
        ];

        /** @private */
        public function CompositeMode() { throw new AbstractClassError(); }

        /** Draw layer on top of destination. Corresponds to BlendMode.NORMAL.
         *  <code>src + dst × (1 - src.alpha)</code> */
        public static const NORMAL:String = "normal";

        /** Draw layer on top of the destination using the destination's alpha value.
         *  <code>src × dst.alpha + dst × (1 - src.alpha)</code> */
        public static const INSIDE:String = "inside";

        /** Draw layer on top of the destination, using the destination's inverted alpha value.
         *  <code>src × (1 - dst.alpha) + dst</code> */
        public static const OUTSIDE:String = "outside";

        /** Draw only the new layer (erasing the old), using the destination's alpha value.
         *  <code>src × dst.alpha</code> */
        public static const INSIDE_KNOCKOUT:String = "insideKnockout";

        /** Draw only the new layer (erasing the old), using the destination's inverted alpha value.
         *  <code>src × (1 - dst.alpha)</code> */
        public static const OUTSIDE_KNOCKOUT:String = "outsideKnockout";

        /** Returns a different integer for each mode. */
        public static function getIndex(mode:String):int
        {
            return allModes.indexOf(mode);
        }
    }
}
