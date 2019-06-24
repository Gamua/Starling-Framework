// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.geom.Point;

    import starling.display.DisplayObject;
    import starling.utils.Pool;
    import starling.utils.StringUtil;

    /** A Touch object contains information about the presence or movement of a finger
     *  or the mouse on the screen.
     *  
     *  <p>You receive objects of this type from a TouchEvent. When such an event is triggered,
     *  you can query it for all touches that are currently present on the screen. One touch
     *  object contains information about a single touch; it always transitions through a series
     *  of TouchPhases. Have a look at the TouchPhase class for more information.</p>
     *  
     *  <strong>The position of a touch</strong>
     *  
     *  <p>You can get the current and previous position in stage coordinates with the corresponding 
     *  properties. However, you'll want to have the position in a different coordinate system 
     *  most of the time. For this reason, there are methods that convert the current and previous 
     *  touches into the local coordinate system of any object.</p>
     * 
     *  @see TouchEvent
     *  @see TouchPhase
     */  
    public class Touch
    {
        private var _id:int;
        private var _globalX:Number;
        private var _globalY:Number;
        private var _previousGlobalX:Number;
        private var _previousGlobalY:Number;
        private var _startGlobalX:Number;
        private var _startGlobalY:Number;
        private var _startTimestamp:Number;
        private var _tapCount:int;
        private var _phase:String;
        private var _target:DisplayObject;
        private var _timestamp:Number;
        private var _pressure:Number;
        private var _width:Number;
        private var _height:Number;
        private var _cancelled:Boolean;
        private var _bubbleChain:Vector.<EventDispatcher>;
        
        /** Helper object. */
        private static var sHelperPoint:Point = new Point();
        
        /** Creates a new Touch object. */
        public function Touch(id:int)
        {
            _id = id;
            _tapCount = 0;
            _phase = TouchPhase.HOVER;
            _pressure = _width = _height = 1.0;
            _bubbleChain = new <EventDispatcher>[];
            _timestamp = _startTimestamp = -1;
        }
        
        /** Converts the current location of a touch to the local coordinate system of a display 
         *  object. If you pass an <code>out</code>-point, the result will be stored in this point
         *  instead of creating a new object.*/
        public function getLocation(space:DisplayObject, out:Point=null):Point
        {
            sHelperPoint.setTo(_globalX, _globalY);
            return space.globalToLocal(sHelperPoint, out);
        }
        
        /** Converts the previous location of a touch to the local coordinate system of a display 
         *  object. If you pass an <code>out</code>-point, the result will be stored in this point
         *  instead of creating a new object.*/
        public function getPreviousLocation(space:DisplayObject, out:Point=null):Point
        {
            sHelperPoint.setTo(_previousGlobalX, _previousGlobalY);
            return space.globalToLocal(sHelperPoint, out);
        }

        /** Converts the start location of a touch (i.e. when it entered 'TouchPhase.BEGAN') to
         *  the local coordinate system of a display object. If you pass an <code>out</code>-point,
         *  the result will be stored in this point instead of creating a new object.*/
        public function getStartLocation(space:DisplayObject, out:Point=null):Point
        {
            sHelperPoint.setTo(_startGlobalX, _startGlobalY);
            return space.globalToLocal(sHelperPoint, out);
        }
        
        /** Returns the movement of the touch between the current and previous location. 
         *  If you pass an <code>out</code>-point, the result will be stored in this point instead
         *  of creating a new object. */ 
        public function getMovement(space:DisplayObject, out:Point=null):Point
        {
            return getMovementBetween(_previousGlobalX, _previousGlobalY,
                                      _globalX, _globalY, space, out);
        }

        /** Returns the movement of the touch between the current and the start location.
         *  If you pass an <code>out</code>-point, the result will be stored in this point instead
         *  of creating a new object. */
        public function getMovementSinceStart(space:DisplayObject, out:Point=null):Point
        {
            return getMovementBetween(_startGlobalX, _startGlobalY,
                                      _globalX, _globalY, space, out);
        }

        /** Indicates if the target or one of its children is touched. */
        public function isTouching(target:DisplayObject):Boolean
        {
            return _bubbleChain.indexOf(target) != -1;
        }
        
        /** Returns a description of the object. */
        public function toString():String
        {
            return StringUtil.format("[Touch {0}: globalX={1}, globalY={2}, phase={3}]",
                                     _id, _globalX, _globalY, _phase);
        }
        
        /** Creates a clone of the Touch object. */
        public function clone():Touch
        {
            var clone:Touch = new Touch(_id);
            clone._globalX = _globalX;
            clone._globalY = _globalY;
            clone._previousGlobalX = _previousGlobalX;
            clone._previousGlobalY = _previousGlobalY;
            clone._startGlobalX = _startGlobalX;
            clone._startGlobalY = _startGlobalY;
            clone._startTimestamp = _startTimestamp;
            clone._phase = _phase;
            clone._tapCount = _tapCount;
            clone._timestamp = _timestamp;
            clone._pressure = _pressure;
            clone._width = _width;
            clone._height = _height;
            clone._cancelled = _cancelled;
            clone.target = _target;
            return clone;
        }

        // helper methods

        /** Input parameters in global coordinates. */
        private static function getMovementBetween(startX:Number, startY:Number, endX:Number, endY:Number,
                                                   space:DisplayObject, out:Point=null):Point
        {
            if (out == null) out = new Point();

            var startPos:Point = Pool.getPoint(startX, startY);
            var endPos:Point = Pool.getPoint(endX, endY);

            space.globalToLocal(startPos, startPos);
            space.globalToLocal(endPos, endPos);
            out.setTo(endPos.x - startPos.x, endPos.y - startPos.y);

            Pool.putPoint(startPos);
            Pool.putPoint(endPos);

            return out;
        }

        private function updateBubbleChain():void
        {
            if (_target)
            {
                var length:int = 1;
                var element:DisplayObject = _target;
                
                _bubbleChain.length = 1;
                _bubbleChain[0] = element;
                
                while ((element = element.parent) != null)
                    _bubbleChain[int(length++)] = element;
            }
            else
            {
                _bubbleChain.length = 0;
            }
        }
        
        // properties
        
        /** The identifier of a touch. '0' for mouse events, an increasing number for touches. */
        public function get id():int { return _id; }
        
        /** The previous x-position of the touch in stage coordinates. */
        public function get previousGlobalX():Number { return _previousGlobalX; }
        
        /** The previous y-position of the touch in stage coordinates. */
        public function get previousGlobalY():Number { return _previousGlobalY; }

        /** The x-position of the touch when it was in 'TouchPhase.BEGAN', in stage coordinates.
         *  (Or, if the touch is in phase 'HOVER', the x-position when it first appeared.) */
        public function get startGlobalX():Number { return _startGlobalX; }

        /** The y-position of the touch when it was in 'TouchPhase.BEGAN', in stage coordinates.
         *  (Or, if the touch is in phase 'HOVER', the y-position when it first appeared.) */
        public function get startGlobalY():Number { return _startGlobalY; }

        /** The x-position of the touch in stage coordinates. If you change this value,
         *  the previous one will be moved to "previousGlobalX". */
        public function get globalX():Number { return _globalX; }
        public function set globalX(value:Number):void
        {
            if (_globalX != _globalX) // isNaN
                _previousGlobalX = _startGlobalX = value;
            else
                _previousGlobalX = _globalX;

            _globalX = value;
        }

        /** The y-position of the touch in stage coordinates. If you change this value,
         *  the previous one will be moved to "previousGlobalY". */
        public function get globalY():Number { return _globalY; }
        public function set globalY(value:Number):void
        {
            if (_globalY != _globalY) // isNaN
                _previousGlobalY = _startGlobalY = value;
            else
                _previousGlobalY = _globalY;

            _globalY = value;
        }
        
        /** The number of taps the finger made in a short amount of time. Use this to detect 
         *  double-taps / double-clicks, etc. */ 
        public function get tapCount():int { return _tapCount; }
        public function set tapCount(value:int):void { _tapCount = value; }
        
        /** The current phase the touch is in. @see TouchPhase */
        public function get phase():String { return _phase; }
        public function set phase(value:String):void
        {
            _phase = value;

            if (value == TouchPhase.BEGAN)
            {
                _startGlobalX = _globalX;
                _startGlobalY = _globalY;
                _startTimestamp = _timestamp;
            }
        }
        
        /** The display object at which the touch occurred. */
        public function get target():DisplayObject { return _target; }
        public function set target(value:DisplayObject):void
        {
            if (_target != value)
            {
                _target = value;
                updateBubbleChain();
            }
        }
        
        /** The moment the touch occurred (in seconds since application start). */
        public function get timestamp():Number { return _timestamp; }
        public function set timestamp(value:Number):void
        {
            if (_startTimestamp < 0) _startTimestamp = value;
            _timestamp = value;
        }
        
        /** A value between 0.0 and 1.0 indicating force of the contact with the device. 
         *  If the device does not support detecting the pressure, the value is 1.0. */ 
        public function get pressure():Number { return _pressure; }
        public function set pressure(value:Number):void { _pressure = value; }
        
        /** Width of the contact area. 
         *  If the device does not support detecting the pressure, the value is 1.0. */
        public function get width():Number { return _width; }
        public function set width(value:Number):void { _width = value; }
        
        /** Height of the contact area. 
         *  If the device does not support detecting the pressure, the value is 1.0. */
        public function get height():Number { return _height; }
        public function set height(value:Number):void { _height = value; }

        /** Indicates if the touch has been cancelled, which may happen when the app moves into
         *  the background ('Event.DEACTIVATE'). @default false */
        public function get cancelled():Boolean { return _cancelled; }
        public function set cancelled(value:Boolean):void { _cancelled = value; }

        /** If the touch is hovering, returns the time (in seconds) since the touch was created;
         *  afterwards, the time since the touch was in phase 'BEGAN'. */
        public function get duration():Number
        {
            if (_timestamp < 0 || _startTimestamp < 0 || _startTimestamp > _timestamp) return -1.0;
            else return _timestamp - _startTimestamp;
        }

        // internal methods

        /** @private
         *  Updates all important properties at once. */
        internal function update(timestamp:Number, phase:String, globalX:Number, globalY:Number,
                                 pressure:Number=1.0, width:Number=1.0, height:Number=1.0):void
        {
            _pressure = pressure;
            _width = width;
            _height = height;
            this.timestamp = timestamp;
            this.globalX = globalX;
            this.globalY = globalY;
            this.phase = phase; // must be the last property to be updated! (yikes)
        }
        
        /** @private 
         *  Dispatches a touch event along the current bubble chain (which is updated each time
         *  a target is set). */
        internal function dispatchEvent(event:TouchEvent):void
        {
            if (_target) event.dispatch(_bubbleChain);
        }
        
        /** @private */
        internal function get bubbleChain():Vector.<EventDispatcher>
        {
            return _bubbleChain.concat();
        }
    }
}
