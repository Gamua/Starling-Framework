package starling.utils
{
    import starling.errors.AbstractClassError;

    public final class VAlign
    {
        public function VAlign() { throw new AbstractClassError(); }
        
        public static const TOP:String    = "top";
        public static const CENTER:String = "center";
        public static const BOTTOM:String = "bottom";
        
        public static function isValid(vAlign:String):Boolean
        {
            return vAlign == TOP || vAlign == CENTER || vAlign == BOTTOM;
        }
    }
}