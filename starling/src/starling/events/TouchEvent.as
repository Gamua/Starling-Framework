// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    
    public class TouchEvent extends Event
    {
        public static const TOUCH:String = "touch";
        
        private var mTouches:Vector.<Touch>;
        private var mShiftKey:Boolean;
        private var mCtrlKey:Boolean;
        
        public function TouchEvent(type:String, touches:Vector.<Touch>, shiftKey:Boolean=false, 
                                   ctrlKey:Boolean=false, bubbles:Boolean=true)
        {
            super(type, bubbles);
            mTouches = touches;
            mShiftKey = shiftKey;
            mCtrlKey = ctrlKey;
        }
        
        public function getTouches(target:DisplayObject, phase:String=null):Vector.<Touch>
        {
            var touchesFound:Vector.<Touch> = new <Touch>[];
            for each (var touch:Touch in mTouches)
            {
                var correctTarget:Boolean = (touch.target == target) ||
                    ((target is DisplayObjectContainer) && 
                     (target as DisplayObjectContainer).contains(touch.target));
                var correctPhase:Boolean = (phase == null || phase == touch.phase);
                    
                if (correctTarget && correctPhase)
                    touchesFound.push(touch);
            }
            return touchesFound;
        }
        
        public function getTouch(target:DisplayObject, phase:String=null):Touch
        {
            var touchesFound:Vector.<Touch> = getTouches(target, phase);
            if (touchesFound.length > 0) return touchesFound[0];
            else return null;
        }

        public function get timestamp():Number
        {
            if (mTouches != null && mTouches.length != 0)
                return mTouches[0].timestamp;
            else 
                return -1.0;
        }
        
        public function get touches():Vector.<Touch> { return mTouches.concat(); }
        public function get shiftKey():Boolean { return mShiftKey; }
        public function get ctrlKey():Boolean { return mCtrlKey; }
    }
}