package starling.text
{
    import starling.errors.AbstractClassError;

    /** This class is an enumeration of possible types of bitmap fonts. */
    public class BitmapFontType
    {
        /** @private */
        public function BitmapFontType() { throw new AbstractClassError(); }

        /** A standard bitmap font uses a regular RGBA texture containing all glyphs. */
        public static const STANDARD:String = "standard";

        /** Indicates that the font texture contains a single channel distance field texture
         *  to be rendered with the <em>DistanceFieldStyle</em>. */
        public static const DISTANCE_FIELD:String = "distanceField";

        /** Indicates that the font texture contains a multi channel distance field texture
         *  to be rendered with the <em>DistanceFieldStyle</em>. */
        public static const MULTI_CHANNEL_DISTANCE_FIELD:String = "multiChannelDistanceField";
    }
}
