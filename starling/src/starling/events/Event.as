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
    import flash.utils.getQualifiedClassName;
    
    import starling.utils.formatString;

    public class Event
    {
        public static const ADDED:String = "added";
        public static const ADDED_TO_STAGE:String = "addedToStage";
        public static const ENTER_FRAME:String = "enterFrame";
        public static const REMOVED:String = "removed";
        public static const REMOVED_FROM_STAGE:String = "removedFromStage";
        public static const TRIGGERED:String = "triggered";
        public static const MOVIE_COMPLETED:String = "movieCompleted";
        public static const FLATTEN:String = "flatten";
        public static const RESIZE:String = "resize";
        
        private var mTarget:EventDispatcher;
        private var mCurrentTarget:EventDispatcher;
        private var mType:String;
        private var mBubbles:Boolean;
        private var mStopsPropagation:Boolean;
        private var mStopsImmediatePropagation:Boolean;
        
        public function Event(type:String, bubbles:Boolean=false)
        {
            mType = type;
            mBubbles = bubbles;
        }
        
        public function stopPropagation():void
        {
            mStopsPropagation = true;            
        }
        
        public function stopImmediatePropagation():void
        {
            mStopsPropagation = mStopsImmediatePropagation = true;
        }
        
        public function toString():String
        {
            return formatString("[{0} type=\"{1}\" bubbles={2}]", 
                getQualifiedClassName(this).split("::").pop(), mType, mBubbles);
        }
        
        internal function setTarget(target:EventDispatcher):void 
        { 
            mTarget = target; 
        }
        
        internal function setCurrentTarget(currentTarget:EventDispatcher):void 
        { 
            mCurrentTarget = currentTarget; 
        }
        
        internal function get stopsPropagation():Boolean { return mStopsPropagation; }
        internal function get stopsImmediatePropagation():Boolean { return mStopsImmediatePropagation; }
        
        public function get bubbles():Boolean { return mBubbles; }
        public function get target():EventDispatcher { return mTarget; }
        public function get currentTarget():EventDispatcher { return mCurrentTarget; }
        public function get type():String { return mType; }
    }
}