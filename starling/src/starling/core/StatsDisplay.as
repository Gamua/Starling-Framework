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
    
    /** A small, lightweight box that displays the current framerate and memory consumption. */
    internal class StatsDisplay extends Sprite
    {
        private var mBackground:Quad;
        private var mTextField:TextField;
        
        private var mFrameCount:int = 0;
        private var mTotalTime:Number = 0;
        
        /** Creates a new Statistics Box. */
        public function StatsDisplay()
        {
            mBackground = new Quad(128, 32, 0x0);
            mTextField = new TextField(128, 32, "", BitmapFont.MINI, BitmapFont.NATIVE_SIZE, 0xffffff);
            mTextField.x = 2;
            mTextField.hAlign = HAlign.LEFT;
            mTextField.vAlign = VAlign.TOP;
            
            addChild(mBackground);
            addChild(mTextField);
            
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
            updateText(0, getMemory());
            blendMode = BlendMode.NONE;
        }
        
        private function updateText(fps:Number, memory:Number):void
        {
            mTextField.text = "FPS: " + fps.toFixed(2) + "\nMEM: " + memory.toFixed(2);
            mBackground.width  = mTextField.textBounds.width  + 5;
            mBackground.height = mTextField.textBounds.height + 5;
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
                updateText(mFrameCount / mTotalTime, getMemory());
                mFrameCount = mTotalTime = 0;
            }
        }
    }
}