package starling.textures
{
    import starling.errors.AbstractClassError;

    public class TextureSmoothing
    {
        public function TextureSmoothing() { throw new AbstractClassError(); }
        
        public static const NONE:String      = "none";       // nearest neighbor
        public static const BILINEAR:String  = "bilinear";
        public static const TRILINEAR:String = "trilinear";
        
        public static function isValid(smoothing:String):Boolean
        {
            return smoothing == NONE || smoothing == BILINEAR || smoothing == TRILINEAR;
        }
    }
}