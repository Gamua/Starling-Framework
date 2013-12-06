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
    /** A KeyboardEvent is dispatched in response to user input through a keyboard.
     * 
     *  <p>This is Starling's version of the Flash KeyboardEvent class. It contains the same 
     *  properties as the Flash equivalent.</p> 
     * 
     *  <p>To be notified of keyboard events, add an event listener to any display object that
     *  is part of your display tree. Starling has no concept of a "Focus" like native Flash.</p>
     *  
     *  @see starling.display.Stage
     */
    public class KeyboardEvent extends Event
    {
        /** Event type for a key that was released. */
        public static const KEY_UP:String = "keyUp";
        
        /** Event type for a key that was pressed. */
        public static const KEY_DOWN:String = "keyDown";
        
        private var mCharCode:uint;
        private var mKeyCode:uint;
        private var mKeyLocation:uint;
        private var mAltKey:Boolean;
        private var mCtrlKey:Boolean;
        private var mShiftKey:Boolean;
        private var mIsDefaultPrevented:Boolean;
        
        /** Creates a new KeyboardEvent. */
        public function KeyboardEvent(type:String, charCode:uint=0, keyCode:uint=0, 
                                      keyLocation:uint=0, ctrlKey:Boolean=false, 
                                      altKey:Boolean=false, shiftKey:Boolean=false)
        {
            super(type, false, keyCode);
            mCharCode = charCode;
            mKeyCode = keyCode;
            mKeyLocation = keyLocation;
            mCtrlKey = ctrlKey;
            mAltKey = altKey;
            mShiftKey = shiftKey;
        }
        
        // prevent default
        
        /** Cancels the keyboard event's default behavior. This will be forwarded to the native
         *  flash KeyboardEvent. */
        public function preventDefault():void
        {
            mIsDefaultPrevented = true;
        }
        
        /** Checks whether the preventDefault() method has been called on the event. */
        public function isDefaultPrevented():Boolean { return mIsDefaultPrevented; }
        
        // properties
        
        /** Contains the character code of the key. */
        public function get charCode():uint { return mCharCode; }
        
        /** The key code of the key. */
        public function get keyCode():uint { return mKeyCode; }
        
        /** Indicates the location of the key on the keyboard. This is useful for differentiating 
         *  keys that appear more than once on a keyboard. @see Keylocation */ 
        public function get keyLocation():uint { return mKeyLocation; }
        
        /** Indicates whether the Alt key is active on Windows or Linux; 
         *  indicates whether the Option key is active on Mac OS. */
        public function get altKey():Boolean { return mAltKey; }
        
        /** Indicates whether the Ctrl key is active on Windows or Linux; 
         *  indicates whether either the Ctrl or the Command key is active on Mac OS. */
        public function get ctrlKey():Boolean { return mCtrlKey; }
        
        /** Indicates whether the Shift key modifier is active (true) or inactive (false). */
        public function get shiftKey():Boolean { return mShiftKey; }
    }
}