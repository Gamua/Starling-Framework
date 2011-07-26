package starling.events
{
    import starling.errors.AbstractClassError;

    public final class TouchPhase
    {
        public function TouchPhase() { throw new AbstractClassError(); }
        
        public static const HOVER:String = "hover";
        public static const BEGAN:String = "began";
        public static const MOVED:String = "moved";
        public static const STATIONARY:String = "stationary";
        public static const ENDED:String = "ended";
    }
}