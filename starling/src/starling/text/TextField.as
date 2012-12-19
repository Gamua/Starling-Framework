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
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

    /** A TextField displays text, either using standard true type fonts or custom bitmap fonts.
     *  
     *  <p>You can set all properties you are used to, like the font name and size, a color, the 
     *  horizontal and vertical alignment, etc. The border property is helpful during development, 
     *  because it lets you see the bounds of the textfield.</p>
     *  
     *  <p>There are two types of fonts that can be displayed:</p>
     *  
     *  <ul>
     *    <li>Standard true type fonts. This renders the text just like a conventional Flash
     *        TextField. It is recommended to embed the font, since you cannot be sure which fonts
     *        are available on the client system, and since this enhances rendering quality. 
     *        Simply pass the font name to the corresponding property.</li>
     *    <li>Bitmap fonts. If you need speed or fancy font effects, use a bitmap font instead. 
     *        That is a font that has its glyphs rendered to a texture atlas. To use it, first 
     *        register the font with the method <code>registerBitmapFont</code>, and then pass 
     *        the font name to the corresponding property of the text field.</li>
     *  </ul> 
     *    
     *  For bitmap fonts, we recommend one of the following tools:
     * 
     *  <ul>
     *    <li>Windows: <a href="http://www.angelcode.com/products/bmfont">Bitmap Font Generator</a>
     *       from Angel Code (free). Export the font data as an XML file and the texture as a png 
     *       with white characters on a transparent background (32 bit).</li>
     *    <li>Mac OS: <a href="http://glyphdesigner.71squared.com">Glyph Designer</a> from 
     *        71squared or <a href="http://http://www.bmglyph.com">bmGlyph</a> (both commercial). 
     *        They support Starling natively.</li>
     *  </ul> 
     */
    public class TextField extends DisplayObjectContainer
    {
        // the name container with the registered bitmap fonts
        private static const BITMAP_FONT_DATA_NAME:String = "starling.display.TextField.BitmapFonts";
        
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
        private var mNativeFilters:Array;
        private var mRequiresRedraw:Boolean;
        private var mIsRenderedText:Boolean;
        private var mTextBounds:Rectangle;

        private var mAutoSize:String = TextFieldAutoSize.NONE;
        private var mAutoSizeMaxWidth:Number = 0;
        private var mAutoSizeMaxHeight:Number = 0;

        private var mHitArea:DisplayObject;
        private var mBorder:DisplayObjectContainer;
        
        private var mImage:Image;
        private var mQuadBatch:QuadBatch;
        
        // this object will be used for text rendering
        private static var sNativeTextField:flash.text.TextField = new flash.text.TextField();
        
        /** Create a new text field with the given properties. */
        public function TextField(width:int, height:int, text:String, fontName:String="Verdana",
                                  fontSize:Number=12, color:uint=0x0, bold:Boolean=false)
        {
            mText = text ? text : "";
            mFontSize = fontSize;
            mColor = color;
            mHAlign = HAlign.CENTER;
            mVAlign = VAlign.CENTER;
            mBorder = null;
            mKerning = true;
            mBold = bold;
            this.fontName = fontName;
            
            mHitArea = new Quad(width, height);
            mHitArea.alpha = 0.0;
            addChild(mHitArea);
            
            addEventListener(Event.FLATTEN, onFlatten);
        }
        
        /** Disposes the underlying texture data. */
        public override function dispose():void
        {
            removeEventListener(Event.FLATTEN, onFlatten);
            if (mImage) mImage.texture.dispose();
            if (mQuadBatch) mQuadBatch.dispose();
            super.dispose();
        }
        
        private function onFlatten():void
        {
            if (mRequiresRedraw) redrawContents();
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mRequiresRedraw) redrawContents();
            super.render(support, parentAlpha);
        }
        
        private function redrawContents():void
        {
            if (mIsRenderedText) createRenderedContents();
            else                 createComposedContents();
            
            mRequiresRedraw = false;
        }
        
        private function createRenderedContents():void
        {
            if (mQuadBatch)
            { 
                mQuadBatch.removeFromParent(true); 
                mQuadBatch = null; 
            }
            
            var scale:Number  = Starling.contentScaleFactor;

            var width:Number;
            var height:Number;
            var multiline:Boolean;
            var wordWrap:Boolean;
            switch (mAutoSize) {
            case TextFieldAutoSize.NONE:
                width = mHitArea.width * scale;
                height = mHitArea.width * scale;
                multiline = true;
                wordWrap = true;
                break;

            case TextFieldAutoSize.SINGLE_LINE:
                width = (mAutoSizeMaxWidth > 0 ? mAutoSizeMaxWidth * scale : Number.MAX_VALUE);
                height = Number.MAX_VALUE;
                multiline = false;
                wordWrap = false;
                break;

            case TextFieldAutoSize.MULTI_LINE:
                width = (mAutoSizeMaxWidth > 0 ? mAutoSizeMaxWidth * scale : Number.MAX_VALUE);
                height = Number.MAX_VALUE;
                multiline = true;
                wordWrap = true;
                break;
            }

            var textFormat:TextFormat = new TextFormat(mFontName,
                mFontSize * scale, mColor, mBold, mItalic, mUnderline, null, null, mHAlign);
            textFormat.kerning = mKerning;
            
            sNativeTextField.defaultTextFormat = textFormat;
            sNativeTextField.width = width;
            sNativeTextField.height = height;
            sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
            sNativeTextField.selectable = false;
            sNativeTextField.multiline = multiline;
            sNativeTextField.wordWrap = wordWrap;
            sNativeTextField.text = mText;
            sNativeTextField.embedFonts = true;
            sNativeTextField.filters = mNativeFilters;
            
            // we try embedded fonts first, non-embedded fonts are just a fallback
            if (sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
                sNativeTextField.embedFonts = false;
            
            if (mAutoScale)
                autoScaleNativeTextField(sNativeTextField);

            // Flash incorrectly reports textWidth and height
            var textWidth:Number  = sNativeTextField.textWidth + 5;
            var textHeight:Number = sNativeTextField.textHeight + 4;

            if (mAutoSize != TextFieldAutoSize.NONE)
            {
                sNativeTextField.width = width = textWidth;
                sNativeTextField.height = height = textHeight;

                // Clip our height, if necessary
                if (mAutoSizeMaxHeight > 0)
                    textHeight = height = Math.min(textHeight, mAutoSizeMaxHeight * scale);
            }

            var xOffset:Number = 0.0;
            if (mHAlign == HAlign.LEFT)        xOffset = 2; // flash adds a 2 pixel offset
            else if (mHAlign == HAlign.CENTER) xOffset = (width - textWidth) / 2.0;
            else if (mHAlign == HAlign.RIGHT)  xOffset =  width - textWidth - 2;

            var yOffset:Number = 0.0;
            if (mVAlign == VAlign.TOP)         yOffset = 2; // flash adds a 2 pixel offset
            else if (mVAlign == VAlign.CENTER) yOffset = (height - textHeight) / 2.0;
            else if (mVAlign == VAlign.BOTTOM) yOffset =  height - textHeight - 2;

            formatText(sNativeTextField, textFormat);
            
            var bitmapData:BitmapData = new BitmapData(width, height, true, 0x0);
            bitmapData.draw(sNativeTextField, new Matrix(1, 0, 0, 1, 0, int(yOffset)-2));
            sNativeTextField.text = "";
            
            // update textBounds rectangle
            if (mTextBounds == null) mTextBounds = new Rectangle();
            mTextBounds.setTo(xOffset   / scale, yOffset    / scale,
                              textWidth / scale, textHeight / scale);
            
            var texture:Texture = Texture.fromBitmapData(bitmapData, false, false, scale);
            
            if (mImage == null) 
            {
                mImage = new Image(texture);
                mImage.touchable = false;
                addChild(mImage);
            }
            else 
            { 
                mImage.texture.dispose();
                mImage.texture = texture; 
                mImage.readjustSize(); 
            }

            if (mAutoSize != TextFieldAutoSize.NONE)
            {
                mHitArea.width = mTextBounds.width;
                mHitArea.height = mTextBounds.height;
                updateBorder();
            }
        }

        /** formatText is called immediately before the text is rendered. The intent of formatText
         *  is to be overridden in a subclass, so that you can provide custom formatting for TextField.
         *  <code>textField</code> is the flash.text.TextField object that you can specially format;
         *  <code>textFormat</code> is the default TextFormat for <code>textField</code>.
         */
        protected function formatText(textField:flash.text.TextField, textFormat:TextFormat):void {}

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
        
        private function createComposedContents():void
        {
            if (mImage) 
            { 
                mImage.removeFromParent(true); 
                mImage = null; 
            }
            
            if (mQuadBatch == null) 
            { 
                mQuadBatch = new QuadBatch(); 
                mQuadBatch.touchable = false;
                addChild(mQuadBatch); 
            }
            else
                mQuadBatch.reset();
            
            var bitmapFont:BitmapFont = bitmapFonts[mFontName];
            if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);

            // Determine our parameters
            var width:Number;
            var height:Number;
            var autoSize:Boolean;
            var multiline:Boolean;
            switch (mAutoSize)
            {
            case TextFieldAutoSize.NONE:
                width = mHitArea.width;
                height = mHitArea.height;
                autoSize = false;
                multiline = true;
                break;

            case TextFieldAutoSize.SINGLE_LINE:
                width = (autoSizeMaxWidth > 0 ? autoSizeMaxWidth : Number.MAX_VALUE);
                height = bitmapFont.lineHeight;
                autoSize = true;
                multiline = false;
                break;

            case TextFieldAutoSize.MULTI_LINE:
                width = (autoSizeMaxWidth > 0 ? autoSizeMaxWidth : Number.MAX_VALUE);
                height = (autoSizeMaxHeight > 0 ? autoSizeMaxHeight : Number.MAX_VALUE);
                autoSize = true;
                multiline = true;
                break;
            }

            bitmapFont.fillQuadBatch(mQuadBatch,
                width, height, mText, mFontSize, mColor, mHAlign, mVAlign,
                mAutoScale, mKerning, autoSize, multiline);

            mTextBounds = null; // will be created on demand

            if (autoSize)
            {
                mTextBounds = mQuadBatch.getBounds(mQuadBatch);
                mHitArea.width = mTextBounds.width;
                mHitArea.height = mTextBounds.height;
                updateBorder();
            }
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
            rightLine.x  = width  - 1;
            bottomLine.y = height - 1;
            topLine.color = rightLine.color = bottomLine.color = leftLine.color = mColor;
        }
        
        /** Returns the bounds of the text within the text field. */
        public function get textBounds():Rectangle
        {
            if (mRequiresRedraw) redrawContents();
            if (mTextBounds == null) mTextBounds = mQuadBatch.getBounds(mQuadBatch);
            return mTextBounds.clone();
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            // If we are auto-sized, ensure we're up-to-date
            if (mRequiresRedraw && mAutoSize != TextFieldAutoSize.NONE) redrawContents();
            return mHitArea.getBounds(targetSpace, resultRect);
        }

        /** Sets the width of the TextField. Unlike ordinary display objects, changing
         * the size of the TextField will not change its scaling. Instead, it makes the texture
         * bigger or smaller while the size of the text and font stays the same.
         *
         * Manually changing the TextField's size will disable auto-sizing, if it's enabled. */
        public override function set width(value:Number):void
        {
            if (mHitArea.width != value)
            {
                mHitArea.width = value;
                mAutoSize = TextFieldAutoSize.NONE;
                mRequiresRedraw = true;
                updateBorder();
            }
        }

        /** Sets the height of the TextField. Unlike ordinary display objects, changing
         * the size of the TextField will not change its scaling. Instead, it makes the texture
         * bigger or smaller while the size of the text and font stays the same.
         *
         * Manually changing the TextField's size will disable auto-sizing, if it's enabled. */
        public override function set height(value:Number):void
        {
            if (mHitArea.height != value)
            {
                mHitArea.height = value;
                mAutoSize = TextFieldAutoSize.NONE;
                mRequiresRedraw = true;
                updateBorder();
            }
        }
        
        /** The displayed text. */
        public function get text():String { return mText; }
        public function set text(value:String):void
        {
            if (value == null) value = "";
            if (mText != value)
            {
                mText = value;
                mRequiresRedraw = true;
            }
        }
        
        /** The name of the font (true type or bitmap font). */
        public function get fontName():String { return mFontName; }
        public function set fontName(value:String):void
        {
            if (mFontName != value)
            {
                if (value == BitmapFont.MINI && bitmapFonts[value] == undefined)
                    registerBitmapFont(new BitmapFont());
                
                mFontName = value;
                mRequiresRedraw = true;
                mIsRenderedText = bitmapFonts[value] == undefined;
            }
        }
        
        /** The size of the font. For bitmap fonts, use <code>BitmapFont.NATIVE_SIZE</code> for 
         *  the original size. */
        public function get fontSize():Number { return mFontSize; }
        public function set fontSize(value:Number):void
        {
            if (mFontSize != value)
            {
                mFontSize = value;
                mRequiresRedraw = true;
            }
        }
        
        /** The color of the text. For bitmap fonts, use <code>Color.WHITE</code> to use the
         *  original, untinted color. @default black */
        public function get color():uint { return mColor; }
        public function set color(value:uint):void
        {
            if (mColor != value)
            {
                mColor = value;
                updateBorder();
                mRequiresRedraw = true;
            }
        }
        
        /** The horizontal alignment of the text. @default center @see starling.utils.HAlign */
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
        
        /** The vertical alignment of the text. @default center @see starling.utils.VAlign */
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
        
        /** Draws a border around the edges of the text field. Useful for visual debugging. 
         *  @default false */
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
        
        /** Indicates whether the text is bold. @default false */
        public function get bold():Boolean { return mBold; }
        public function set bold(value:Boolean):void 
        {
            if (mBold != value)
            {
                mBold = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether the text is italicized. @default false */
        public function get italic():Boolean { return mItalic; }
        public function set italic(value:Boolean):void
        {
            if (mItalic != value)
            {
                mItalic = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether the text is underlined. @default false */
        public function get underline():Boolean { return mUnderline; }
        public function set underline(value:Boolean):void
        {
            if (mUnderline != value)
            {
                mUnderline = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether kerning is enabled. @default true */
        public function get kerning():Boolean { return mKerning; }
        public function set kerning(value:Boolean):void
        {
            if (mKerning != value)
            {
                mKerning = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates whether the font size is scaled down so that the complete text fits
         *  into the text field. (Auto-sizing is incompatible with auto-scaling;
         *  enabling auto-sizing will disable auto-scaling and vice-versa).
         *  @default false */
        public function get autoScale():Boolean { return mAutoScale; }
        public function set autoScale(value:Boolean):void
        {
            if (mAutoScale != value)
            {
                mAutoScale = value;
                if (mAutoScale) mAutoSize = TextFieldAutoSize.NONE;
                mRequiresRedraw = true;
            }
        }

        /** The native Flash BitmapFilters to apply to this TextField. 
         *  Only available when using standard (TrueType) fonts! */
        public function get nativeFilters():Array { return mNativeFilters; }
        public function set nativeFilters(value:Array) : void
        {
            if (!mIsRenderedText)
                throw(new Error("The TextField.nativeFilters property cannot be used on Bitmap fonts."));
			
            mNativeFilters = value.concat();
            mRequiresRedraw = true;
        }

        /** Specifies the type of auto-sizing the TextField will do. (Auto-sizing is incompatible
        *   with auto-scaling; enabling auto-sizing will disable auto-scaling and vice-versa).
        *   @default "none" */
        public function get autoSize():String { return mAutoSize; }
        public function set autoSize(value:String):void
        {
            if (mAutoSize != value)
            {
                mAutoSize = value;
                mAutoScale = mAutoScale && (mAutoSize == TextFieldAutoSize.NONE);
                mRequiresRedraw = true;
            }
        }

        /** Specifies the TextField's maximum width when auto-sizing is used. A value <= 0
         *  indicates no max width. @default 0 */
        public function get autoSizeMaxWidth():Number { return mAutoSizeMaxWidth; }
        public function set autoSizeMaxWidth(value:Number):void
        {
            if (mAutoSizeMaxWidth != value)
            {
                mAutoSizeMaxWidth = value;
                mRequiresRedraw = true;
            }
        }

        /** Specifies the TextField's maximum height when auto-sizing is used. A value <= 0
         *  indicates no max height. @default 0 */
        public function get autoSizeMaxHeight():Number { return mAutoSizeMaxHeight; }
        public function set autoSizeMaxHeight(value:Number):void
        {
            if (mAutoSizeMaxHeight != value)
            {
                mAutoSizeMaxHeight = value;
                mRequiresRedraw = true;
            }
        }

        /** Makes a bitmap font available at any text field, identified by its <code>name</code>.
         *  Per default, the <code>name</code> property of the bitmap font will be used, but you
         *  can pass a custom name, as well. @returns the name of the font. */
        public static function registerBitmapFont(bitmapFont:BitmapFont, name:String=null):String
        {
            if (name == null) name = bitmapFont.name;
            bitmapFonts[name] = bitmapFont;
            return name;
        }
        
        /** Unregisters the bitmap font and, optionally, disposes it. */
        public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
        {
            if (dispose && bitmapFonts[name] != undefined)
                bitmapFonts[name].dispose();
            
            delete bitmapFonts[name];
        }
        
        /** Returns a registered bitmap font (or null, if the font has not been registered). */
        public static function getBitmapFont(name:String):BitmapFont
        {
            return bitmapFonts[name];
        }
        
        /** Stores the currently available bitmap fonts. Since a bitmap font will only work
         *  in one Stage3D context, they are saved in Starling's 'contextData' property. */
        private static function get bitmapFonts():Dictionary
        {
            var fonts:Dictionary = Starling.current.contextData[BITMAP_FONT_DATA_NAME] as Dictionary;
            
            if (fonts == null)
            {
                fonts = new Dictionary();
                Starling.current.contextData[BITMAP_FONT_DATA_NAME] = fonts;
            }
            
            return fonts;
        }
    }
}
