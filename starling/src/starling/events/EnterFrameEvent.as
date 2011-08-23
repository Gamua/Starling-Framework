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
    public class EnterFrameEvent extends Event
    {
        public static const ENTER_FRAME:String = "enterFrame";
        
        private var mPassedTime:Number;
        
        public function EnterFrameEvent(type:String, passedTime:Number, bubbles:Boolean=false)
        {
            super(type, bubbles);
            mPassedTime = passedTime;
        }
        
        public function get passedTime():Number { return mPassedTime; }
    }
}