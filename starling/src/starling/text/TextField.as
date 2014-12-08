// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text
{
    import flash.display.BitmapData;
    import flash.display.StageQuality;
    import flash.display3D.Context3DTextureFormat;
    import flash.filters.BitmapFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.AntiAliasType;
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
    import starling.utils.RectangleUtil;
    import starling.utils.VAlign;
    import starling.utils.deg2rad;

    /** A TextField displays text, either using standard true type fonts or custom bitmap fonts.
     *  
     *  <p>You can set all properties you are used to, like the font name and size, a color, the 
     *  horizontal and vertical alignment, etc. The border property is helpful during development, 
     *  because it lets you see the bounds of the textfield.</p>
     *  
     *  <p>There are two types of fonts that can be displayed:</p>
     *  
     *  <ul>
     *    <li>Standard TrueType fonts. This renders the text just like a conventional Flash
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
     * 
     *  <strong>Batching of TextFields</strong>
     *  
     *  <p>Normally, TextFields will require exactly one draw call. For TrueType fonts, you cannot
     *  avoid that; bitmap fonts, however, may be batched if you enable the "batchable" property.
     *  This makes sense if you have several TextFields with short texts that are rendered one
     *  after the other (e.g. subsequent children of the same sprite), or if your bitmap font
     *  texture is in your main texture atlas.</p>
     *  
     *  <p>The recommendation is to activate "batchable" if it reduces your draw calls (use the
     *  StatsDisplay to check this) AND if the TextFields contain no more than about 10-15
     *  characters (per TextField). For longer texts, the batching would take up more CPU time
     *  than what is saved by avoiding the draw calls.</p>
     */
    public class TextField extends DisplayObjectContainer
    {
        // the name container with the registered bitmap fonts
        private static const BITMAP_FONT_DATA_NAME:String = "starling.display.TextField.BitmapFonts";
        
        // the texture format that is used for TTF rendering
        private static var sDefaultTextureFormat:String =
            "BGRA_PACKED" in Context3DTextureFormat ? "bgraPacked4444" : "bgra";

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
        private var mAutoSize:String;
        private var mKerning:Boolean;
        private var mNativeFilters:Array;
        private var mRequiresRedraw:Boolean;
        private var mIsRenderedText:Boolean;
        private var mIsHtmlText:Boolean;
        private var mTextBounds:Rectangle;
        private var mBatchable:Boolean;
        
        private var mHitArea:Rectangle;
        private var mBorder:DisplayObjectContainer;
        
        private var mImage:Image;
        private var mQuadBatch:QuadBatch;
        
        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
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
            mAutoSize = TextFieldAutoSize.NONE;
            mHitArea = new Rectangle(0, 0, width, height);
            this.fontName = fontName;
            
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
            if (mRequiresRedraw) redraw();
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (mRequiresRedraw) redraw();
            super.render(support, parentAlpha);
        }
        
        /** Forces the text field to be constructed right away. Normally, 
         *  it will only do so lazily, i.e. before being rendered. */
        public function redraw():void
        {
            if (mRequiresRedraw)
            {
                if (mIsRenderedText) createRenderedContents();
                else                 createComposedContents();
                
                updateBorder();
                mRequiresRedraw = false;
            }
        }
        
        // TrueType font rendering
        
        private function createRenderedContents():void
        {
            if (mQuadBatch)
            {
                mQuadBatch.removeFromParent(true); 
                mQuadBatch = null; 
            }
            
            if (mTextBounds == null) 
                mTextBounds = new Rectangle();
            
            var texture:Texture;
            var scale:Number = Starling.contentScaleFactor;
            var bitmapData:BitmapData = renderText(scale, mTextBounds);
            var format:String = sDefaultTextureFormat;
            
            mHitArea.width  = bitmapData.width  / scale;
            mHitArea.height = bitmapData.height / scale;
            
            texture = Texture.fromBitmapData(bitmapData, false, false, scale, format);
            texture.root.onRestore = function():void
            {
                if (mTextBounds == null)
                    mTextBounds = new Rectangle();

                bitmapData = renderText(scale, mTextBounds);
                texture.root.uploadBitmapData(renderText(scale, mTextBounds));
                bitmapData.dispose();
                bitmapData = null;
            };
            
            bitmapData.dispose();
            bitmapData = null;
            
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
        }

        /** This method is called immediately before the text is rendered. The intent of
         *  'formatText' is to be overridden in a subclass, so that you can provide custom
         *  formatting for the TextField. In the overriden method, call 'setFormat' (either
         *  over a range of characters or the complete TextField) to modify the format to
         *  your needs.
         *  
         *  @param textField  the flash.text.TextField object that you can format.
         *  @param textFormat the default text format that's currently set on the text field.
         */
        protected function formatText(textField:flash.text.TextField, textFormat:TextFormat):void {}

        private function renderText(scale:Number, resultTextBounds:Rectangle):BitmapData
        {
            var width:Number  = mHitArea.width  * scale;
            var height:Number = mHitArea.height * scale;
            var hAlign:String = mHAlign;
            var vAlign:String = mVAlign;
            
            if (isHorizontalAutoSize)
            {
                width = int.MAX_VALUE;
                hAlign = HAlign.LEFT;
            }
            if (isVerticalAutoSize)
            {
                height = int.MAX_VALUE;
                vAlign = VAlign.TOP;
            }
            
            var textFormat:TextFormat = new TextFormat(mFontName, 
                mFontSize * scale, mColor, mBold, mItalic, mUnderline, null, null, hAlign);
            textFormat.kerning = mKerning;
            
            sNativeTextField.defaultTextFormat = textFormat;
            sNativeTextField.width = width;
            sNativeTextField.height = height;
            sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
            sNativeTextField.selectable = false;            
            sNativeTextField.multiline = true;            
            sNativeTextField.wordWrap = true;         

            if (mIsHtmlText) sNativeTextField.htmlText = mText;
            else             sNativeTextField.text     = mText;
               
            sNativeTextField.embedFonts = true;
            sNativeTextField.filters = mNativeFilters;
            
            // we try embedded fonts first, non-embedded fonts are just a fallback
            if (sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
                sNativeTextField.embedFonts = false;
            
            formatText(sNativeTextField, textFormat);
            
            if (mAutoScale)
                autoScaleNativeTextField(sNativeTextField);
            
            var textWidth:Number  = sNativeTextField.textWidth;
            var textHeight:Number = sNativeTextField.textHeight;

            if (isHorizontalAutoSize)
                sNativeTextField.width = width = Math.ceil(textWidth + 5);
            if (isVerticalAutoSize)
                sNativeTextField.height = height = Math.ceil(textHeight + 4);
            
            // avoid invalid texture size
            if (width  < 1) width  = 1.0;
            if (height < 1) height = 1.0;
            
            var textOffsetX:Number = 0.0;
            if (hAlign == HAlign.LEFT)        textOffsetX = 2; // flash adds a 2 pixel offset
            else if (hAlign == HAlign.CENTER) textOffsetX = (width - textWidth) / 2.0;
            else if (hAlign == HAlign.RIGHT)  textOffsetX =  width - textWidth - 2;

            var textOffsetY:Number = 0.0;
            if (vAlign == VAlign.TOP)         textOffsetY = 2; // flash adds a 2 pixel offset
            else if (vAlign == VAlign.CENTER) textOffsetY = (height - textHeight) / 2.0;
            else if (vAlign == VAlign.BOTTOM) textOffsetY =  height - textHeight - 2;
            
            // if 'nativeFilters' are in use, the text field might grow beyond its bounds
            var filterOffset:Point = calculateFilterOffset(sNativeTextField, hAlign, vAlign);
            
            // finally: draw text field to bitmap data
            var bitmapData:BitmapData = new BitmapData(width, height, true, 0x0);
            var drawMatrix:Matrix = new Matrix(1, 0, 0, 1,
                filterOffset.x, filterOffset.y + int(textOffsetY)-2);
            var drawWithQualityFunc:Function = 
                "drawWithQuality" in bitmapData ? bitmapData["drawWithQuality"] : null;
            
            // Beginning with AIR 3.3, we can force a drawing quality. Since "LOW" produces
            // wrong output oftentimes, we force "MEDIUM" if possible.
            
            if (drawWithQualityFunc is Function)
                drawWithQualityFunc.call(bitmapData, sNativeTextField, drawMatrix, 
                                         null, null, null, false, StageQuality.MEDIUM);
            else
                bitmapData.draw(sNativeTextField, drawMatrix);
            
            sNativeTextField.text = "";
            
            // update textBounds rectangle
            resultTextBounds.setTo((textOffsetX + filterOffset.x) / scale,
                                   (textOffsetY + filterOffset.y) / scale,
                                   textWidth / scale, textHeight / scale);
            
            return bitmapData;
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
        
        private function calculateFilterOffset(textField:flash.text.TextField,
                                               hAlign:String, vAlign:String):Point
        {
            var resultOffset:Point = new Point();
            var filters:Array = textField.filters;
            
            if (filters != null && filters.length > 0)
            {
                var textWidth:Number  = textField.textWidth;
                var textHeight:Number = textField.textHeight;
                var bounds:Rectangle  = new Rectangle();
                
                for each (var filter:BitmapFilter in filters)
                {
                    var blurX:Number    = "blurX"    in filter ? filter["blurX"]    : 0;
                    var blurY:Number    = "blurY"    in filter ? filter["blurY"]    : 0;
                    var angleDeg:Number = "angle"    in filter ? filter["angle"]    : 0;
                    var distance:Number = "distance" in filter ? filter["distance"] : 0;
                    var angle:Number = deg2rad(angleDeg);
                    var marginX:Number = blurX * 1.33; // that's an empirical value
                    var marginY:Number = blurY * 1.33;
                    var offsetX:Number  = Math.cos(angle) * distance - marginX / 2.0;
                    var offsetY:Number  = Math.sin(angle) * distance - marginY / 2.0;
                    var filterBounds:Rectangle = new Rectangle(
                        offsetX, offsetY, textWidth + marginX, textHeight + marginY);
                    
                    bounds = bounds.union(filterBounds);
                }
                
                if (hAlign == HAlign.LEFT && bounds.x < 0)
                    resultOffset.x = -bounds.x;
                else if (hAlign == HAlign.RIGHT && bounds.y > 0)
                    resultOffset.x = -(bounds.right - textWidth);
                
                if (vAlign == VAlign.TOP && bounds.y < 0)
                    resultOffset.y = -bounds.y;
                else if (vAlign == VAlign.BOTTOM && bounds.y > 0)
                    resultOffset.y = -(bounds.bottom - textHeight);
            }
            
            return resultOffset;
        }
        
        // bitmap font composition
        
        private function createComposedContents():void
        {
            if (mImage) 
            {
                mImage.removeFromParent(true); 
                mImage.texture.dispose();
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
            
            var bitmapFont:BitmapFont = getBitmapFont(mFontName);
            if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);
            
            var width:Number  = mHitArea.width;
            var height:Number = mHitArea.height;
            var hAlign:String = mHAlign;
            var vAlign:String = mVAlign;
            
            if (isHorizontalAutoSize)
            {
                width = int.MAX_VALUE;
                hAlign = HAlign.LEFT;
            }
            if (isVerticalAutoSize)
            {
                height = int.MAX_VALUE;
                vAlign = VAlign.TOP;
            }
            
            bitmapFont.fillQuadBatch(mQuadBatch,
                width, height, mText, mFontSize, mColor, hAlign, vAlign, mAutoScale, mKerning);
            
            mQuadBatch.batchable = mBatchable;
            
            if (mAutoSize != TextFieldAutoSize.NONE)
            {
                mTextBounds = mQuadBatch.getBounds(mQuadBatch, mTextBounds);
                
                if (isHorizontalAutoSize)
                    mHitArea.width  = mTextBounds.x + mTextBounds.width;
                if (isVerticalAutoSize)
                    mHitArea.height = mTextBounds.y + mTextBounds.height;
            }
            else
            {
                // hit area doesn't change, text bounds can be created on demand
                mTextBounds = null;
            }
        }
        
        // helpers
        
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
        
        // properties
        
        private function get isHorizontalAutoSize():Boolean
        {
            return mAutoSize == TextFieldAutoSize.HORIZONTAL || 
                   mAutoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
        }
        
        private function get isVerticalAutoSize():Boolean
        {
            return mAutoSize == TextFieldAutoSize.VERTICAL || 
                   mAutoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
        }
        
        /** Returns the bounds of the text within the text field. */
        public function get textBounds():Rectangle
        {
            if (mRequiresRedraw) redraw();
            if (mTextBounds == null) mTextBounds = mQuadBatch.getBounds(mQuadBatch);
            return mTextBounds.clone();
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (mRequiresRedraw) redraw();
            getTransformationMatrix(targetSpace, sHelperMatrix);
            return RectangleUtil.getBounds(mHitArea, sHelperMatrix, resultRect);
        }
        
        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable)) return null;
            else if (mHitArea.containsPoint(localPoint)) return this;
            else return null;
        }

        /** @inheritDoc */
        public override function set width(value:Number):void
        {
            // different to ordinary display objects, changing the size of the text field should 
            // not change the scaling, but make the texture bigger/smaller, while the size 
            // of the text/font stays the same (this applies to the height, as well).
            
            mHitArea.width = value;
            mRequiresRedraw = true;
        }
        
        /** @inheritDoc */
        public override function set height(value:Number):void
        {
            mHitArea.height = value;
            mRequiresRedraw = true;
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
                mIsRenderedText = getBitmapFont(value) == null;
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
         *  into the text field. @default false */
        public function get autoScale():Boolean { return mAutoScale; }
        public function set autoScale(value:Boolean):void
        {
            if (mAutoScale != value)
            {
                mAutoScale = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Specifies the type of auto-sizing the TextField will do.
         *  Note that any auto-sizing will make auto-scaling useless. Furthermore, it has 
         *  implications on alignment: horizontally auto-sized text will always be left-, 
         *  vertically auto-sized text will always be top-aligned. @default "none" */
        public function get autoSize():String { return mAutoSize; }
        public function set autoSize(value:String):void
        {
            if (mAutoSize != value)
            {
                mAutoSize = value;
                mRequiresRedraw = true;
            }
        }
        
        /** Indicates if TextField should be batched on rendering. This works only with bitmap
         *  fonts, and it makes sense only for TextFields with no more than 10-15 characters.
         *  Otherwise, the CPU costs will exceed any gains you get from avoiding the additional
         *  draw call. @default false */
        public function get batchable():Boolean { return mBatchable; }
        public function set batchable(value:Boolean):void
        { 
            mBatchable = value;
            if (mQuadBatch) mQuadBatch.batchable = value;
        }

        /** The native Flash BitmapFilters to apply to this TextField.
         *
         *  <p>BEWARE: this property is ignored when using bitmap fonts!</p> */
        public function get nativeFilters():Array { return mNativeFilters; }
        public function set nativeFilters(value:Array) : void
        {
            mNativeFilters = value.concat();
            mRequiresRedraw = true;
        }

        /** Indicates if the assigned text should be interpreted as HTML code. For a description
         *  of the supported HTML subset, refer to the classic Flash 'TextField' documentation.
         *  Clickable hyperlinks and external images are not supported.
         *
         *  <p>BEWARE: this property is ignored when using bitmap fonts!</p> */
        public function get isHtmlText():Boolean { return mIsHtmlText; }
        public function set isHtmlText(value:Boolean):void
        {
            if (mIsHtmlText != value)
            {
                mIsHtmlText = value;
                mRequiresRedraw = true;
            }
        }
        
        /** The Context3D texture format that is used for rendering of all TrueType texts.
         *  The default (<pre>Context3DTextureFormat.BGRA_PACKED</pre>) provides a good
         *  compromise between quality and memory consumption; use <pre>BGRA</pre> for
         *  the highest quality. */
        public static function get defaultTextureFormat():String { return sDefaultTextureFormat; }
        public static function set defaultTextureFormat(value:String):void
        {
            sDefaultTextureFormat = value;
        }
        
        /** Makes a bitmap font available at any TextField in the current stage3D context.
         *  The font is identified by its <code>name</code> (not case sensitive).
         *  Per default, the <code>name</code> property of the bitmap font will be used, but you 
         *  can pass a custom name, as well. @return the name of the font. */
        public static function registerBitmapFont(bitmapFont:BitmapFont, name:String=null):String
        {
            if (name == null) name = bitmapFont.name;
            bitmapFonts[name.toLowerCase()] = bitmapFont;
            return name;
        }
        
        /** Unregisters the bitmap font and, optionally, disposes it. */
        public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
        {
            name = name.toLowerCase();
            
            if (dispose && bitmapFonts[name] != undefined)
                bitmapFonts[name].dispose();
            
            delete bitmapFonts[name];
        }
        
        /** Returns a registered bitmap font (or null, if the font has not been registered). 
         *  The name is not case sensitive. */
        public static function getBitmapFont(name:String):BitmapFont
        {
            return bitmapFonts[name.toLowerCase()];
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
