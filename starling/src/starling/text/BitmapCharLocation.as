package starling.text
{
    /** A helper class referencing a BitmapChar and properties about its location and size.
     *
     *  <p>This class is used and returned by <code>BitmapFont.arrangeChars()</code>.
     *  It's typically only needed for advanced changes to Starling's default text composition
     *  mechanisms.</p>
     *
     *  <p>This class supports object pooling. All instances returned by the methods
     *  <code>instanceFromPool</code> and <code>vectorFromPool</code> are returned to the
     *  respective pool when calling <code>rechargePool</code>.</p>
     */
    public class BitmapCharLocation
    {
        /** The actual bitmap char to be drawn. */
        public var char:BitmapChar;

        /** The scale with which the char must be placed. */
        public var scale:Number;

        /** The x-coordinate of the char's location. */
        public var x:Number;

        /** The y-coordinate of the char's location. */
        public var y:Number;

        /** The index of this char in the processed String. */
        public var index:int;

        /** Create a new instance that references the given char. */
        public function BitmapCharLocation(char:BitmapChar)
        {
            init(char);
        }

        private function init(char:BitmapChar):BitmapCharLocation
        {
            this.char = char;
            return this;
        }

        // pooling

        private static var sInstancePool:Vector.<BitmapCharLocation> = new <BitmapCharLocation>[];
        private static var sVectorPool:Array = [];

        private static var sInstanceLoan:Vector.<BitmapCharLocation> = new <BitmapCharLocation>[];
        private static var sVectorLoan:Array = [];

        /** Returns a "BitmapCharLocation" instance from the pool, initialized with the given char.
         *  All instances will be returned to the pool when calling <code>rechargePool</code>. */
        public static function instanceFromPool(char:BitmapChar):BitmapCharLocation
        {
            var instance:BitmapCharLocation = sInstancePool.length > 0 ?
                sInstancePool.pop() : new BitmapCharLocation(char);

            instance.init(char);
            sInstanceLoan[sInstanceLoan.length] = instance;

            return instance;
        }

        /** Returns an empty Vector for "BitmapCharLocation" instances from the pool.
         *  All vectors will be returned to the pool when calling <code>rechargePool</code>. */
        public static function vectorFromPool():Vector.<BitmapCharLocation>
        {
            var vector:Vector.<BitmapCharLocation> = sVectorPool.length > 0 ?
                sVectorPool.pop() : new <BitmapCharLocation>[];

            vector.length = 0;
            sVectorLoan[sVectorLoan.length] = vector;

            return vector;
        }

        /** Puts all objects that were previously returned by either of the "...fromPool" methods
         *  back into the pool. */
        public static function rechargePool():void
        {
            var instance:BitmapCharLocation;
            var vector:Vector.<BitmapCharLocation>;

            while (sInstanceLoan.length > 0)
            {
                instance = sInstanceLoan.pop();
                instance.char = null;
                sInstancePool[sInstancePool.length] = instance;
            }

            while (sVectorLoan.length > 0)
            {
                vector = sVectorLoan.pop();
                vector.length = 0;
                sVectorPool[sVectorPool.length] = vector;
            }
        }
    }
}
