// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.system.System;
    
    import starling.display.BlendMode;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    
    /** A small, lightweight box that displays the current framerate, memory consumption and
     *  the number of draw calls per frame. */
    internal class StatsDisplay extends Sprite
    {
        private var mBackground:Quad;
        private var mTextField:TextField;
        
        private var mFrameCount:int = 0;
        private var mDrawCount:int  = 0;
        private var mTotalTime:Number = 0;
        
        /** Creates a new Statistics Box. */
        public function StatsDisplay()
        {
            mBackground = new Quad(50, 25, 0x0);
            mTextField = new TextField(48, 25, "", BitmapFont.MINI, BitmapFont.NATIVE_SIZE, 0xffffff);
            mTextField.x = 2;
            mTextField.hAlign = HAlign.LEFT;
            mTextField.vAlign = VAlign.TOP;
            
            addChild(mBackground);
            addChild(mTextField);
            
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            updateText(0, getMemory(), 0);
            blendMode = BlendMode.NONE;
        }
        
        private function updateText(fps:Number, memory:Number, drawCount:int):void
        {
            mTextField.text = "FPS: " + fps.toFixed(fps < 100 ? 1 : 0) + 
                            "\nMEM: " + memory.toFixed(memory < 100 ? 1 : 0) +
                            "\nDRW: " + drawCount; 
        }
        
        private function getMemory():Number
        {
            return System.totalMemory * 0.000000954; // 1 / (1024*1024) to convert to MB
        }
        
        private function onEnterFrame(event:EnterFrameEvent):void
        {
            mTotalTime += event.passedTime;
            mFrameCount++;
            
            if (mTotalTime > 1.0)
            {
                updateText(mFrameCount / mTotalTime, getMemory(), mDrawCount-2); // DRW: ignore self
                mFrameCount = mTotalTime = 0;
            }
        }
        
        /** The number of Stage3D draw calls per second. */
        public function get drawCount():int { return mDrawCount; }
        public function set drawCount(value:int):void { mDrawCount = value; }
    }
}