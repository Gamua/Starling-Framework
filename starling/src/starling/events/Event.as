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
        /** Event type for a display object that is added to a parent. */
        public static const ADDED:String = "added";
        /** Event type for a display object that is added to the stage */
        public static const ADDED_TO_STAGE:String = "addedToStage";
        /** Event type for a display object that is entering a new frame. */
        public static const ENTER_FRAME:String = "enterFrame";
        /** Event type for a display object that is removed from its parent. */
        public static const REMOVED:String = "removed";
        /** Event type for a display object that is removed from the stage. */
        public static const REMOVED_FROM_STAGE:String = "removedFromStage";
        /** Event type for a triggered button. */
        public static const TRIGGERED:String = "triggered";
        /** Event type for a movie that has reached the last frame. */
        public static const MOVIE_COMPLETED:String = "movieCompleted";
        /** Event type for a display object that is being flattened. */
        public static const FLATTEN:String = "flatten";
        /** Event type for a resized Flash Player. */
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