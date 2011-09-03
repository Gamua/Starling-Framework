// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Rectangle;
    
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

    [Event(name="triggered", type="starling.events.Event")]
    public class Button extends DisplayObjectContainer
    {
        private static const MAX_DRAG_DIST:Number = 50;
        
        private var mUpState:Texture;
        private var mDownState:Texture;
        
        private var mContents:Sprite;
        private var mBackground:Image;
        private var mTextField:TextField;
        private var mTextBounds:Rectangle;
        
        private var mScaleWhenDown:Number;
        private var mAlphaWhenDisabled:Number;
        private var mEnabled:Boolean;
        private var mIsDown:Boolean;
        
        public function Button(upState:Texture, text:String="", downState:Texture=null)
        {
            if (upState == null) throw new ArgumentError("Texture cannot be null");
            
            mUpState = upState;
            mDownState = downState ? downState : upState;
            mBackground = new Image(upState);
            mScaleWhenDown = downState ? 1.0 : 0.9;
            mAlphaWhenDisabled = 0.5;
            mEnabled = true;
            mIsDown = false;
            mTextBounds = new Rectangle(0, 0, upState.width, upState.height);            
            
            mContents = new Sprite();
            mContents.addChild(mBackground);
            addChild(mContents);
            addEventListener(TouchEvent.TOUCH, onTouch);
            
            if (text.length != 0) this.text = text;
        }
        
        public override function dispose():void
        {
            removeEventListener(TouchEvent.TOUCH, onTouch);
            super.dispose();
        }
        
        private function resetContents():void
        {
            mIsDown = false;
            mBackground.texture = mUpState;
            mContents.x = mContents.y = 0;
            mContents.scaleX = mContents.scaleY = 1.0;
        }
        
        private function createTextField():void
        {
            if (mTextField == null)
            {
                mTextField = new TextField(mTextBounds.width, mTextBounds.height, "");
                mTextField.vAlign = VAlign.CENTER;
                mTextField.hAlign = HAlign.CENTER;
                mTextField.touchable = false;
                mTextField.autoScale = true;
                mContents.addChild(mTextField);
            }
            
            mTextField.width  = mTextBounds.width;
            mTextField.height = mTextBounds.height;
            mTextField.x = mTextBounds.x;
            mTextField.y = mTextBounds.y;
        }
        
        private function onTouch(event:TouchEvent):void
        {
            var touch:Touch = event.getTouch(this);
            if (!mEnabled || touch == null) return;
            
            if (touch.phase == TouchPhase.BEGAN && !mIsDown)
            {
                mBackground.texture = mDownState;
                mContents.scaleX = mContents.scaleY = mScaleWhenDown;
                mContents.x = (1.0 - mScaleWhenDown) / 2.0 * mBackground.width;
                mContents.y = (1.0 - mScaleWhenDown) / 2.0 * mBackground.height;
                mIsDown = true;
            }
            else if (touch.phase == TouchPhase.MOVED && mIsDown)
            {
                // reset button when user dragged too far away after pushing
                var buttonRect:Rectangle = getBounds(stage);
                if (touch.globalX < buttonRect.x - MAX_DRAG_DIST ||
                    touch.globalY < buttonRect.y - MAX_DRAG_DIST ||
                    touch.globalX > buttonRect.x + buttonRect.width + MAX_DRAG_DIST ||
                    touch.globalY > buttonRect.y + buttonRect.height + MAX_DRAG_DIST)
                {
                    resetContents();
                }
            }
            else if (touch.phase == TouchPhase.ENDED && mIsDown)
            {
                resetContents();
                dispatchEvent(new Event(Event.TRIGGERED, true));
            }
        }
        
        public function get scaleWhenDown():Number { return mScaleWhenDown; }
        public function set scaleWhenDown(value:Number):void { mScaleWhenDown = value; }
        
        public function get alphaWhenDisabled():Number { return mAlphaWhenDisabled; }
        public function set alphaWhenDisabled(value:Number):void { mAlphaWhenDisabled = value; }
        
        public function get enabled():Boolean { return mEnabled; }
        public function set enabled(value:Boolean):void
        {
            if (mEnabled != value)
            {            
                mEnabled = value;
                mContents.alpha = value ? 1.0 : mAlphaWhenDisabled;
                resetContents();
            }
        }
        
        public function get text():String { return mTextField ? mTextField.text : ""; }
        public function set text(value:String):void
        {
            createTextField();
            mTextField.text = value;
        }
       
        public function get fontName():String { return mTextField ? mTextField.fontName : "Verdana"; }
        public function set fontName(value:String):void
        {
            createTextField();
            mTextField.fontName = value;
        }
        
        public function get fontSize():Number { return mTextField ? mTextField.fontSize : 12; }
        public function set fontSize(value:Number):void
        {
            createTextField();
            mTextField.fontSize = value;
        }
        
        public function get fontColor():uint { return mTextField ? mTextField.color : 0x0; }
        public function set fontColor(value:uint):void
        {
            createTextField();
            mTextField.color = value;
        }
        
        public function get fontBold():Boolean { return mTextField ? mTextField.bold : false; }
        public function set fontBold(value:Boolean):void
        {
            createTextField();
            mTextField.bold = value;
        }
        
        public function get upState():Texture { return mUpState; }
        public function set upState(value:Texture):void
        {
            if (mUpState != value)
            {
                mUpState = value;
                if (!mIsDown) mBackground.texture = value;
            }
        }
        
        public function get downState():Texture { return mDownState; }
        public function set downState(value:Texture):void
        {
            if (mDownState != value)
            {
                mDownState = value;
                if (mIsDown) mBackground.texture = value;
            }
        }
        
        public function get textBounds():Rectangle { return mTextBounds.clone(); }
        public function set textBounds(value:Rectangle):void
        {
            mTextBounds = value.clone();
            createTextField();
        }
    }
}