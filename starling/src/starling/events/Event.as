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
    
    import starling.core.starling_internal;
    import starling.utils.formatString;
    
    use namespace starling_internal;

    /** Event objects are passed as parameters to event listeners when an event occurs.  
     *  This is Starling's version of the Flash Event class. 
     *
     *  <p>EventDispatchers create instances of this class and send them to registered listeners. 
     *  An event object contains information that characterizes an event, most importantly the 
     *  event type and if the event bubbles. The target of an event is the object that 
     *  dispatched it.</p>
     * 
     *  <p>For some event types, this information is sufficient; other events may need additional 
     *  information to be carried to the listener. In that case, you can subclass "Event" and add 
     *  properties with all the information you require. The "EnterFrameEvent" is an example for 
     *  this practice; it adds a property about the time that has passed since the last frame.</p>
     * 
     *  <p>Furthermore, the event class contains methods that can stop the event from being 
     *  processed by other listeners - either completely or at the next bubble stage.</p>
     * 
     *  @see EventDispatcher
     */
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
        /** Event type for a display object that is being flattened. */
        public static const FLATTEN:String = "flatten";
        /** Event type for a resized Flash Player. */
        public static const RESIZE:String = "resize";
        /** Event type that may be used whenever something finishes. */
        public static const COMPLETE:String = "complete";
        /** Event type for a (re)created stage3D rendering context. */
        public static const CONTEXT3D_CREATE:String = "context3DCreate";
        /** Event type that indicates that the root DisplayObject has been created. */
        public static const ROOT_CREATED:String = "rootCreated";
        /** Event type for an animated object that requests to be removed from the juggler. */
        public static const REMOVE_FROM_JUGGLER:String = "removeFromJuggler";
        
        /** An event type to be utilized in custom events. Not used by Starling right now. */
        public static const CHANGE:String = "change";
        /** An event type to be utilized in custom events. Not used by Starling right now. */
        public static const CANCEL:String = "cancel";
        /** An event type to be utilized in custom events. Not used by Starling right now. */
        public static const SCROLL:String = "scroll";
        /** An event type to be utilized in custom events. Not used by Starling right now. */
        public static const OPEN:String = "open";
        /** An event type to be utilized in custom events. Not used by Starling right now. */
        public static const CLOSE:String = "close";
        /** An event type to be utilized in custom events. Not used by Starling right now. */
        public static const SELECT:String = "select";
        
        private static var sEventPool:Vector.<Event> = new <Event>[];
        
        private var mTarget:EventDispatcher;
        private var mCurrentTarget:EventDispatcher;
        private var mType:String;
        private var mBubbles:Boolean;
        private var mStopsPropagation:Boolean;
        private var mStopsImmediatePropagation:Boolean;
        private var mData:Object;
        
        /** Creates an event object that can be passed to listeners. */
        public function Event(type:String, bubbles:Boolean=false, data:Object=null)
        {
            mType = type;
            mBubbles = bubbles;
            mData = data;
        }
        
        /** Prevents listeners at the next bubble stage from receiving the event. */
        public function stopPropagation():void
        {
            mStopsPropagation = true;            
        }
        
        /** Prevents any other listeners from receiving the event. */
        public function stopImmediatePropagation():void
        {
            mStopsPropagation = mStopsImmediatePropagation = true;
        }
        
        /** Returns a description of the event, containing type and bubble information. */
        public function toString():String
        {
            return formatString("[{0} type=\"{1}\" bubbles={2}]", 
                getQualifiedClassName(this).split("::").pop(), mType, mBubbles);
        }
        
        /** Indicates if event will bubble. */
        public function get bubbles():Boolean { return mBubbles; }
        
        /** The object that dispatched the event. */
        public function get target():EventDispatcher { return mTarget; }
        
        /** The object the event is currently bubbling at. */
        public function get currentTarget():EventDispatcher { return mCurrentTarget; }
        
        /** A string that identifies the event. */
        public function get type():String { return mType; }
        
        /** Arbitrary data that is attached to the event. */
        public function get data():Object { return mData; }
        
        // properties for internal use
        
        /** @private */
        internal function setTarget(value:EventDispatcher):void { mTarget = value; }
        
        /** @private */
        internal function setCurrentTarget(value:EventDispatcher):void { mCurrentTarget = value; } 
        
        /** @private */
        internal function setData(value:Object):void { mData = value; }
        
        /** @private */
        internal function get stopsPropagation():Boolean { return mStopsPropagation; }
        
        /** @private */
        internal function get stopsImmediatePropagation():Boolean { return mStopsImmediatePropagation; }
        
        // event pooling
        
        /** @private */
        starling_internal static function fromPool(type:String, bubbles:Boolean=false, data:Object=null):Event
        {
            if (sEventPool.length) return sEventPool.pop().reset(type, bubbles, data);
            else return new Event(type, bubbles, data);
        }
        
        /** @private */
        starling_internal static function toPool(event:Event):void
        {
            event.mData = event.mTarget = event.mCurrentTarget = null;
            sEventPool[sEventPool.length] = event; // avoiding 'push'
        }
        
        /** @private */
        starling_internal function reset(type:String, bubbles:Boolean=false, data:Object=null):Event
        {
            mType = type;
            mBubbles = bubbles;
            mData = data;
            mTarget = mCurrentTarget = null;
            mStopsPropagation = mStopsImmediatePropagation = false;
            return this;
        }
    }
}