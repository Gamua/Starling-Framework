// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text
{
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;
    
    import starling.core.RenderSupport;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

    public class TextField extends DisplayObjectContainer
    {
        private var mFontSize:Number;
        private var mColor:uint;
        private var mText:String;
        private var mFontName:String;
        private var mHAlign:String;
        private var mVAlign:String;
        private var mBold:Boolean;
        private var mItalic:Boolean;
        private var mUnderline:Boolean;
        private var mAutoScale:Boolean;
        private var mKerning:Boolean;
        private var mRequiresRedraw:Boolean;
        private var mIsRenderedText:Boolean;
        
        private var mHitArea:DisplayObject;
        private var mTextArea:DisplayObject;
        private var mContents:DisplayObject;
        private var mBorder:DisplayObjectContainer;
        
        // this object will be used for text rendering
        private static var sNativeTextField:flash.text.TextField = new flash.text.TextField();
        
        // this is the container for bitmap fonts
        private static var sBitmapFonts:Dictionary = new Dictionary();
        
        public function TextField(width:int, height:int, text:String, fontName:String="Verdana",
                                  fontSize:Number=12, color:uint=0x0, bold:Boolean=false)
        {
            mText = text;
            mFontSize = fontSize;
            mColor = color;
            mHAlign = HAlign.CENTER;
            mVAlign = VAlign.CENTER;
            mBorder = null;
            mKerning = true;
            this.fontName = fontName;
            
            mHitArea = new Quad(width, height);
            mHitArea.alpha = 0.0;
            addChild(mHitArea);
            
            mTextArea = new Quad(width, height);
            mTextArea.visible = false;
            addChild(mTextArea);
            
            addEventListener(Event.FLATTEN, onFlatten);
        }
        
        public override function dispose():void
        {
            removeEventListener(Event.FLATTEN, onFlatten);
        }
        
        private function onFlatten(event:Event):void
        {
            if (mRequiresRedraw) redrawContents();
        }
        
        public override function render(support:RenderSupport, alpha:Number):void
        {
            if (mRequiresRedraw) redrawContents();
            super.render(support, alpha);
        }
        
        private function redrawContents():void
        {
            if (mContents)
                mContents.removeFromParent(true);
            
            mContents = mIsRenderedText ? createRenderedContents() : createComposedContents();
            mContents.touchable = false;
            mRequiresRedraw = false;
            
            addChild(mContents);
        }
        
        private function createRenderedContents():DisplayObject
        {
            if (mText.length == 0) return new Sprite();
            
            var width:Number  = mHitArea.width;
            var height:Number = mHitArea.height;
            
            var textFormat:TextFormat = new TextFormat(
                mFontName, mFontSize, 0xffffff, mBold, mItalic, mUnderline, null, null, mHAlign);
            textFormat.kerning = mKerning;
            
            sNativeTextField.defaultTextFormat = textFormat;
            sNativeTextField.width = width;
            sNativeTextField.height = height;
            sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
            sNativeTextField.selectable = false;            
            sNativeTextField.multiline = true;            
            sNativeTextField.wordWrap = true;            
            sNativeTextField.text = mText;
            sNativeTextField.embedFonts = true;
            
            // we try embedded fonts first, non-embedded fonts are just a fallback
            if (sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
                sNativeTextField.embedFonts = false;
            
            if (mAutoScale)
                autoScaleNativeTextField(sNativeTextField);
            
            var textWidth:Number  = sNativeTextField.textWidth;
            var textHeight:Number = sNativeTextField.textHeight;
            
            var xOffset:Number = 0.0;
            if (mHAlign == HAlign.LEFT)        xOffset = 2; // flash adds a 2 pixel offset
            else if (mHAlign == HAlign.CENTER) xOffset = (width - textWidth) / 2.0;
            else if (mHAlign == HAlign.RIGHT)  xOffset =  width - textWidth - 2;

            var yOffset:Number = 0.0;
            if (mVAlign == VAlign.TOP)         yOffset = 2; // flash adds a 2 pixel offset
            else if (mVAlign == VAlign.CENTER) yOffset = (height - textHeight) / 2.0;
            else if (mVAlign == VAlign.BOTTOM) yOffset =  height - textHeight - 2;
            
            var bitmapData:BitmapData = new BitmapData(width, height, true, 0x0);
            bitmapData.draw(sNativeTextField, new Matrix(1, 0, 0, 1, 0, int(yOffset)-2));
            
            mTextArea.x = xOffset;
            mTextArea.y = yOffset;
            mTextArea.width = textWidth;
            mTextArea.height = textHeight;
            
            var contents:Image = new Image(Texture.fromBitmapData(bitmapData));
            contents.color = mColor;
            
            return contents;
        }
        
        private function autoScaleNativeTextField(textField:flash.text.TextField):void
        {
            var size:Number   = Number(textField.defaultTextFormat.size);
            var maxHeight:int = textField.height - 4;
            var maxWidth:int  = textField.width - 4;
            
            while (textField.textWidth > maxWidth || textField.textHeight > maxHeight)
            {
                if (size <= 4) break;
                
                var format:TextFormat = textField.defaultTextFormat;
                format.size = size--;
                textField.setTextFormat(format);
            }
        }
        
        private function createComposedContents():DisplayObject
        {
            var bitmapFont:BitmapFont = sBitmapFonts[mFontName];
            if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);
            
            var contents:DisplayObject = bitmapFont.createDisplayObject(
                mHitArea.width, mHitArea.height, mText, mFontSize, mColor, mHAlign, mVAlign,
                mAutoScale, mKerning);
            
            var textBounds:Rectangle = (contents as DisplayObjectContainer).bounds;
            mTextArea.x = textBounds.x;
            mTextArea.y = textBounds.y;
            mTextArea.width  = textBounds.width;
            mTextArea.height = textBounds.height;
            
            return contents;
        }
        
        private function updateBorder():void
        {
            if (mBorder == null) return;
            
            var width:Number  = mHitArea.width;
            var height:Number = mHitArea.height;
            
            var topLine:Quad    = mBorder.getChildAt(0) as Quad;
            var rightLine:Quad  = mBorder.getChildAt(1) as Quad;
            var bottomLine:Quad = mBorder.getChildAt(2) as Quad;
            var leftLine:Quad   = mBorder.getChildAt(3) as Quad;
            
            topLine.width    = width; topLine.height    = 1;
            bottomLine.width = width; bottomLine.height = 1;
            leftLine.width   = 1;     leftLine.height   = height;
            rightLine.width  = 1;     rightLine.height  = height;
            rightLine.x  = width - 1;
            bottomLine.y = height - 1;
            topLine.color = rightLine.color = bottomLine.color = leftLine.color = mColor;
        }
        
        public function get textBounds():Rectangle
        {
            if (mRequiresRedraw) redrawContents();
            return mTextArea.getBounds(parent);
        }
        
        public override function getBounds(targetSpace:DisplayObject):Rectangle
        {
            return mHitArea.getBounds(targetSpace);
        }
        
        public override function set width(value:Number):void
        {
            // different to ordinary display objects, changing the size of the text field should 
            // not change the scaling, but make the texture bigger/smaller, while the size 
            // of the text/font stays the same (this applies to the height, as well).
            
            mHitArea.width = value;
            mRequiresRedraw = true;
            updateBorder();
        }
        
        public override function set height(value:Number):void
        {
            mHitArea.height = value;
            mRequiresRedraw = true;
            updateBorder();
        }
        
        public function get text():String { return mText; }
        public function set text(value:String):void
        {
            if (mText != value)
            {
                mText = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get fontName():String { return mFontName; }
        public function set fontName(value:String):void
        {
            if (mFontName != value)
            {
                mFontName = value;
                mRequiresRedraw = true;
                mIsRenderedText = sBitmapFonts[value] == undefined;
            }
        }
        
        public function get fontSize():Number { return mFontSize; }
        public function set fontSize(value:Number):void
        {
            if (mFontSize != value)
            {
                mFontSize = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get color():uint { return mColor; }
        public function set color(value:uint):void
        {
            if (mColor != value)
            {
                mColor = value;
                updateBorder();
                
                if (mContents)
                {
                   if (mIsRenderedText)
                       (mContents as Image).color = value;
                   else
                       mRequiresRedraw = true;
                }
            }
        }
        
        public function get hAlign():String { return mHAlign; }
        public function set hAlign(value:String):void
        {
            if (!HAlign.isValid(value))
                throw new ArgumentError("Invalid horizontal align: " + value);
            
            if (mHAlign != value)
            {
                mHAlign = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get vAlign():String { return mVAlign; }
        public function set vAlign(value:String):void
        {
            if (!VAlign.isValid(value))
                throw new ArgumentError("Invalid vertical align: " + value);
            
            if (mVAlign != value)
            {
                mVAlign = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get border():Boolean { return mBorder != null; }
        public function set border(value:Boolean):void
        {
            if (value && mBorder == null)
            {                
                mBorder = new Sprite();
                addChild(mBorder);
                
                for (var i:int=0; i<4; ++i)
                    mBorder.addChild(new Quad(1.0, 1.0));
                
                updateBorder();
            }
            else if (!value && mBorder != null)
            {
                mBorder.removeFromParent(true);
                mBorder = null;
            }
        }
        
        public function get bold():Boolean { return mBold; }
        public function set bold(value:Boolean):void 
        {
            if (mBold != value)
            {
                mBold = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get italic():Boolean { return mItalic; }
        public function set italic(value:Boolean):void
        {
            if (mItalic != value)
            {
                mItalic = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get underline():Boolean { return mUnderline; }
        public function set underline(value:Boolean):void
        {
            if (mUnderline != value)
            {
                mUnderline = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get kerning():Boolean { return mKerning; }
        public function set kerning(value:Boolean):void
        {
            if (mKerning != value)
            {
                mKerning = value;
                mRequiresRedraw = true;
            }
        }
        
        public function get autoScale():Boolean { return mAutoScale; }
        public function set autoScale(value:Boolean):void
        {
            if (mAutoScale != value)
            {
                mAutoScale = value;
                mRequiresRedraw = true;
            }
        }
        
        public static function registerBitmapFont(bitmapFont:BitmapFont):void
        {
            sBitmapFonts[bitmapFont.name] = bitmapFont;
        }
        
        public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
        {
            if (dispose && sBitmapFonts[name] != undefined)
                sBitmapFonts[name].dispose();
            
            delete sBitmapFonts[name];
        }
    }
}