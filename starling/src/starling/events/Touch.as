// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    
    import starling.core.starling_internal;
    import starling.display.DisplayObject;
    import starling.utils.formatString;
    
    use namespace starling_internal;

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
        private var mID:int;
        private var mGlobalX:Number;
        private var mGlobalY:Number;
        private var mPreviousGlobalX:Number;
        private var mPreviousGlobalY:Number;
        private var mTapCount:int;
        private var mPhase:String;
        private var mTarget:DisplayObject;
        private var mTimestamp:Number;
        private var mPressure:Number;
        private var mWidth:Number;
        private var mHeight:Number;
        private var mCancelled:Boolean;
        private var mBubbleChain:Vector.<EventDispatcher>;
        
        /** Helper object. */
        private static var sHelperPoint:Point = new Point();
        
        /** Creates a new Touch object. */
        public function Touch(id:int)
        {
            mID = id;
            mTapCount = 0;
            mPhase = TouchPhase.HOVER;
            mPressure = mWidth = mHeight = 1.0;
            mBubbleChain = new <EventDispatcher>[];
        }
        
        /** Converts the current location of a touch to the local coordinate system of a display 
         *  object. If you pass a 'resultPoint', the result will be stored in this point instead 
         *  of creating a new object.*/
        public function getLocation(space:DisplayObject, resultPoint:Point=null):Point
        {
            sHelperPoint.setTo(mGlobalX, mGlobalY);
            return space.globalToLocal(sHelperPoint, resultPoint);
        }
        
        /** Converts the previous location of a touch to the local coordinate system of a display 
         *  object. If you pass a 'resultPoint', the result will be stored in this point instead 
         *  of creating a new object.*/
        public function getPreviousLocation(space:DisplayObject, resultPoint:Point=null):Point
        {
            sHelperPoint.setTo(mPreviousGlobalX, mPreviousGlobalY);
            return space.globalToLocal(sHelperPoint, resultPoint);
        }
        
        /** Returns the movement of the touch between the current and previous location. 
         *  If you pass a 'resultPoint', the result will be stored in this point instead 
         *  of creating a new object. */ 
        public function getMovement(space:DisplayObject, resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();
            getLocation(space, resultPoint);
            var x:Number = resultPoint.x;
            var y:Number = resultPoint.y;
            getPreviousLocation(space, resultPoint);
            resultPoint.setTo(x - resultPoint.x, y - resultPoint.y);
            return resultPoint;
        }
        
        /** Indicates if the target or one of its children is touched. */ 
        public function isTouching(target:DisplayObject):Boolean
        {
            return mBubbleChain.indexOf(target) != -1;
        }
        
        /** Returns a description of the object. */
        public function toString():String
        {
            return formatString("Touch {0}: globalX={1}, globalY={2}, phase={3}",
                                mID, mGlobalX, mGlobalY, mPhase);
        }
        
        /** Creates a clone of the Touch object. */
        public function clone():Touch
        {
            var clone:Touch = new Touch(mID);
            clone.mGlobalX = mGlobalX;
            clone.mGlobalY = mGlobalY;
            clone.mPreviousGlobalX = mPreviousGlobalX;
            clone.mPreviousGlobalY = mPreviousGlobalY;
            clone.mPhase = mPhase;
            clone.mTapCount = mTapCount;
            clone.mTimestamp = mTimestamp;
            clone.mPressure = mPressure;
            clone.mWidth = mWidth;
            clone.mHeight = mHeight;
            clone.mCancelled = mCancelled;
            clone.target = mTarget;
            return clone;
        }
        
        // helper methods
        
        private function updateBubbleChain():void
        {
            if (mTarget)
            {
                var length:int = 1;
                var element:DisplayObject = mTarget;
                
                mBubbleChain.length = 1;
                mBubbleChain[0] = element;
                
                while ((element = element.parent) != null)
                    mBubbleChain[int(length++)] = element;
            }
            else
            {
                mBubbleChain.length = 0;
            }
        }
        
        // properties
        
        /** The identifier of a touch. '0' for mouse events, an increasing number for touches. */
        public function get id():int { return mID; }
        
        /** The previous x-position of the touch in stage coordinates. */
        public function get previousGlobalX():Number { return mPreviousGlobalX; }
        
        /** The previous y-position of the touch in stage coordinates. */
        public function get previousGlobalY():Number { return mPreviousGlobalY; }

        /** The x-position of the touch in stage coordinates. If you change this value,
         *  the previous one will be moved to "previousGlobalX". */
        public function get globalX():Number { return mGlobalX; }
        public function set globalX(value:Number):void
        {
            mPreviousGlobalX = mGlobalX != mGlobalX ? value : mGlobalX; // isNaN check
            mGlobalX = value;
        }

        /** The y-position of the touch in stage coordinates. If you change this value,
         *  the previous one will be moved to "previousGlobalY". */
        public function get globalY():Number { return mGlobalY; }
        public function set globalY(value:Number):void
        {
            mPreviousGlobalY = mGlobalY != mGlobalY ? value : mGlobalY; // isNaN check
            mGlobalY = value;
        }
        
        /** The number of taps the finger made in a short amount of time. Use this to detect 
         *  double-taps / double-clicks, etc. */ 
        public function get tapCount():int { return mTapCount; }
        public function set tapCount(value:int):void { mTapCount = value; }
        
        /** The current phase the touch is in. @see TouchPhase */
        public function get phase():String { return mPhase; }
        public function set phase(value:String):void { mPhase = value; }
        
        /** The display object at which the touch occurred. */
        public function get target():DisplayObject { return mTarget; }
        public function set target(value:DisplayObject):void
        {
            if (mTarget != value)
            {
                mTarget = value;
                updateBubbleChain();
            }
        }
        
        /** The moment the touch occurred (in seconds since application start). */
        public function get timestamp():Number { return mTimestamp; }
        public function set timestamp(value:Number):void { mTimestamp = value; }
        
        /** A value between 0.0 and 1.0 indicating force of the contact with the device. 
         *  If the device does not support detecting the pressure, the value is 1.0. */ 
        public function get pressure():Number { return mPressure; }
        public function set pressure(value:Number):void { mPressure = value; }
        
        /** Width of the contact area. 
         *  If the device does not support detecting the pressure, the value is 1.0. */
        public function get width():Number { return mWidth; }
        public function set width(value:Number):void { mWidth = value; }
        
        /** Height of the contact area. 
         *  If the device does not support detecting the pressure, the value is 1.0. */
        public function get height():Number { return mHeight; }
        public function set height(value:Number):void { mHeight = value; }

        /** Indicates if the touch has been cancelled, which may happen when the app moves into
         *  the background ('Event.DEACTIVATE'). @default false */
        public function get cancelled():Boolean { return mCancelled; }
        public function set cancelled(value:Boolean):void { mCancelled = value; }

        // internal methods
        
        /** @private 
         *  Dispatches a touch event along the current bubble chain (which is updated each time
         *  a target is set). */
        internal function dispatchEvent(event:TouchEvent):void
        {
            if (mTarget) event.dispatch(mBubbleChain);
        }
        
        /** @private */
        internal function get bubbleChain():Vector.<EventDispatcher>
        {
            return mBubbleChain.concat();
        }
    }
}
