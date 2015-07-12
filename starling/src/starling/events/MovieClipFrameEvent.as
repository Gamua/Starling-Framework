
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
    /** An MovieClipFrameEvent is triggered once by a MovieClip when a frame is reached
     *  that the event is attached to.
     *
     *  It contains information about the name of the event. That way, you can easily
     *  have animations that dispatch events with unique eventNames
     */ 
    public class MovieClipFrameEvent extends Event
    {
        /** Event type for a display object that is entering a new frame. */
        public static const MOVIE_CLIP_FRAME_EVENT:String = "movieClipFrameEvent";
        
        /** Creates an movie clip frame event with an event name. */
        public function EnterFrameEvent(type:String, eventName:String="", bubbles:Boolean=false)
        {
            super(type, bubbles, eventName);
        }
        
        /** The name of the movie clip frame event */
        public function get eventName():String { return data as String; }
    }
}
