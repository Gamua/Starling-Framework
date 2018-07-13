package starling.events
{
    /** Stores the information about raw touches in a pool of object instances.
     *
     *  <p>This class is purely for internal use of the TouchProcessor.</p>
     */
    public class TouchData
    {
        private var _id:int;
        private var _phase:String;
        private var _globalX:Number;
        private var _globalY:Number;
        private var _pressure:Number;
        private var _width:Number;
        private var _height:Number;

        private static var sPool:Vector.<TouchData> = new <TouchData>[];

        /** @private */
        public function TouchData()
        { }

        private function setTo(touchID:int, phase:String, globalX:Number, globalY:Number,
                               pressure:Number=1.0, width:Number=1.0, height:Number=1.0):void
        {
            _id = touchID; _phase = phase; _globalX = globalX; _globalY = globalY;
            _pressure = pressure; _width = width; _height = height;
        }

        /** Creates a new TouchData instance with the given properties or returns one from
         *  the object pool. */
        public static function fromPool(touchID:int, phase:String, globalX:Number, globalY:Number,
                                        pressure:Number=1.0, width:Number=1.0, height:Number=1.0):TouchData
        {
            var touchData:TouchData = sPool.length > 0 ? sPool.pop() : new TouchData();
            touchData.setTo(touchID, phase, globalX, globalY, pressure, width, height);
            return touchData;
        }

        /** Moves an instance back into the pool. */
        public static function  toPool(rawTouch:TouchData):void
        {
            sPool[sPool.length] = rawTouch;
        }

        /** The identifier of a touch. '0' for mouse events, an increasing number for touches. */
        public function get id():int { return _id; }

        /** The current phase the touch is in. @see TouchPhase */
        public function get phase():String { return _phase; }

        /** The x-position of the touch in stage coordinates. */
        public function get globalX():Number { return _globalX; }

        /** The y-position of the touch in stage coordinates. */
        public function get globalY():Number { return _globalY; }

        /** A value between 0.0 and 1.0 indicating force of the contact with the device.
         *  If the device does not support detecting the pressure, the value is 1.0. */
        public function get pressure():Number { return _pressure; }

        /** Width of the contact area.
         *  If the device does not support detecting the pressure, the value is 1.0. */
        public function get width():Number { return _width; }

        /** Height of the contact area.
         *  If the device does not support detecting the pressure, the value is 1.0. */
        public function get height():Number { return _height; }
    }
}
