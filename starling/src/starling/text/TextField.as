// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text
{
    import flash.display.BitmapData;
    import flash.display3D.Context3DTextureFormat;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.AntiAliasType;
    import flash.utils.Dictionary;

    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.MeshBatch;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.rendering.Painter;
    import starling.textures.Texture;
    import starling.utils.Align;
    import starling.utils.RectangleUtil;

    /** A TextField displays text, either using standard true type fonts or custom bitmap fonts.
     *  
     *  <p>You can set all properties you are used to, like the font name and size, a color, the 
     *  horizontal and vertical alignment, etc. The border property is helpful during development, 
     *  because it lets you see the bounds of the TextField.</p>
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
     *        from Angel Code (free). Export the font data as an XML file and the texture as a png
     *        with white characters on a transparent background (32 bit).</li>
     *    <li>Mac OS: <a href="http://glyphdesigner.71squared.com">Glyph Designer</a> from 
     *        71squared or <a href="http://http://www.bmglyph.com">bmGlyph</a> (both commercial). 
     *        They support Starling natively.</li>
     *  </ul>
     *
     *  <p>When using a bitmap font, the 'color' property is used to tint the font texture. This
     *  works by multiplying the RGB values of that property with those of the texture's pixel.
     *  If your font contains just a single color, export it in plain white and change the 'color'
     *  property to any value you like (it defaults to zero, which means black). If your font
     *  contains multiple colors, change the 'color' property to <code>Color.WHITE</code> to get
     *  the intended result.</p>
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
        private static var sDefaultTextureFormat:String = Context3DTextureFormat.BGRA_PACKED;

        private var _text:String;
        private var _format:TextFormat;
        private var _autoScale:Boolean;
        private var _autoSize:String;
        private var _requiresRecomposition:Boolean;
        private var _isHtmlText:Boolean;
        private var _textBounds:Rectangle;
        private var _hitArea:Rectangle;
        private var _disposeContents:Function;

        private var _meshBatch:MeshBatch;
        private var _border:DisplayObjectContainer;

        // helper objects
        private static var sHelperQuad:Quad = new Quad(100, 100);
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sNativeTextField:flash.text.TextField = new flash.text.TextField();
        private static var sNativeFormat:flash.text.TextFormat = new flash.text.TextFormat();
        
        /** Create a new text field with the given properties. */
        public function TextField(width:int, height:int, text:String="", format:TextFormat=null)
        {
            _text = text ? text : "";
            _border = null;
            _autoSize = TextFieldAutoSize.NONE;
            _hitArea = new Rectangle(0, 0, width, height);
            _requiresRecomposition = true;
            _disposeContents = disposeComposedContents;

            _format = new TextFormat();
            if (format) _format.copyFrom(format);
            _format.addEventListener(Event.CHANGE, onFormatChange);

            _meshBatch = new MeshBatch();
            _meshBatch.touchable = false;
            addChild(_meshBatch);
        }
        
        /** Disposes the underlying texture data. */
        public override function dispose():void
        {
            _format.removeEventListener(Event.CHANGE, onFormatChange);
            _disposeContents();

            super.dispose();
        }
        
        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            if (_requiresRecomposition) recompose();
            super.render(painter);
        }

        /** Forces the text field to be constructed right away. Normally,
         *  it will only do so lazily, i.e. before being rendered. */
        public function recompose():void
        {
            if (_requiresRecomposition)
            {
                _meshBatch.clear();
                _disposeContents();

                var font:String = _format.font;
                var bitmapFont:BitmapFont = getBitmapFont(font);

                if (bitmapFont == null && font == BitmapFont.MINI)
                {
                    bitmapFont = new BitmapFont();
                    registerBitmapFont(bitmapFont);
                }

                if (bitmapFont) createComposedContents();
                else            createRenderedContents();

                updateBorder();
                _requiresRecomposition = false;
            }
        }

        private function onFormatChange():void
        {
            _requiresRecomposition = true;
        }
        
        // TrueType font rendering
        
        private function createRenderedContents():void
        {
            if (_textBounds == null)
                _textBounds = new Rectangle();

            _disposeContents = disposeRenderedContents;
            
            var texture:Texture;
            var scale:Number = Starling.contentScaleFactor;
            var bitmapData:BitmapData = renderText(scale, _textBounds);
            var format:String = sDefaultTextureFormat;
            var maxTextureSize:int = Texture.maxSize;
            var shrinkHelper:Number = 0;
            
            // re-render when size of rendered bitmap overflows 'maxTextureSize'
            while (bitmapData.width > maxTextureSize || bitmapData.height > maxTextureSize)
            {
                scale *= Math.min(
                    (maxTextureSize - shrinkHelper) / bitmapData.width,
                    (maxTextureSize - shrinkHelper) / bitmapData.height
                );
                bitmapData.dispose();
                bitmapData = renderText(scale, _textBounds);
                shrinkHelper += 1;
            }

            _hitArea.width  = bitmapData.width  / scale;
            _hitArea.height = bitmapData.height / scale;

            texture = Texture.fromBitmapData(bitmapData, false, false, scale, format);
            texture.root.onRestore = function():void
            {
                if (_textBounds == null)
                    _textBounds = new Rectangle();

                bitmapData = renderText(scale, _textBounds);
                texture.root.uploadBitmapData(bitmapData);
                bitmapData.dispose();
                bitmapData = null;
            };
            
            bitmapData.dispose();
            bitmapData = null;

            sHelperQuad.texture = texture;
            sHelperQuad.readjustSize();

            _meshBatch.addMesh(sHelperQuad);

            sHelperQuad.texture = null;
        }

        private function disposeRenderedContents():void
        {
            _meshBatch.texture.dispose();
        }

        /** This method is called immediately before the text is rendered. The intent of
         *  'formatText' is to be overridden in a subclass, so that you can provide custom
         *  formatting for the TextField. In the overridden method, call 'setFormat' (either
         *  over a range of characters or the complete TextField) to modify the format to
         *  your needs.
         *  
         *  @param textField  the flash.text.TextField object that you can format.
         *  @param textFormat the default text format that's currently set on the text field.
         */
        protected function formatText(textField:flash.text.TextField,
                                      textFormat:flash.text.TextFormat):void
        {}

        private function renderText(scale:Number, out:Rectangle):BitmapData
        {
            var width:Number  = _hitArea.width  * scale;
            var height:Number = _hitArea.height * scale;
            var hAlign:String = _format.horizontalAlign;
            var vAlign:String = _format.verticalAlign;
            
            if (isHorizontalAutoSize)
            {
                width = int.MAX_VALUE;
                hAlign = Align.LEFT;
            }
            if (isVerticalAutoSize)
            {
                height = int.MAX_VALUE;
                vAlign = Align.TOP;
            }

            _format.toNativeFormat(sNativeFormat);

            sNativeFormat.size = Number(sNativeFormat.size) * scale;
            sNativeTextField.defaultTextFormat = sNativeFormat;
            sNativeTextField.width = width;
            sNativeTextField.height = height;
            sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
            sNativeTextField.selectable = false;            
            sNativeTextField.multiline = true;            
            sNativeTextField.wordWrap = true;         

            if (_isHtmlText) sNativeTextField.htmlText = _text;
            else             sNativeTextField.text     = _text;
               
            sNativeTextField.embedFonts = true;

            // we try embedded fonts first, non-embedded fonts are just a fallback
            if (sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
                sNativeTextField.embedFonts = false;
            
            formatText(sNativeTextField, sNativeFormat);
            
            if (_autoScale)
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
            if (hAlign == Align.LEFT)        textOffsetX = 2; // flash adds a 2 pixel offset
            else if (hAlign == Align.CENTER) textOffsetX = (width - textWidth) / 2.0;
            else if (hAlign == Align.RIGHT)  textOffsetX =  width - textWidth - 2;

            var textOffsetY:Number = 0.0;
            if (vAlign == Align.TOP)         textOffsetY = 2; // flash adds a 2 pixel offset
            else if (vAlign == Align.CENTER) textOffsetY = (height - textHeight) / 2.0;
            else if (vAlign == Align.BOTTOM) textOffsetY =  height - textHeight - 2;
            
            // finally: draw text field to bitmap data
            var bitmapData:BitmapData = new BitmapData(width, height, true, 0x0);
            sHelperMatrix.setTo(1, 0, 0, 1, 0, int(textOffsetY) - 2);
            bitmapData.draw(sNativeTextField, sHelperMatrix);
            
            sNativeTextField.text = "";
            
            // update textBounds rectangle
            out.setTo(textOffsetX / scale, textOffsetY / scale,
                      textWidth   / scale, textHeight  / scale);
            
            return bitmapData;
        }
        
        private function autoScaleNativeTextField(textField:flash.text.TextField):void
        {
            var size:Number   = Number(textField.defaultTextFormat.size);
            var maxHeight:int = textField.height - 4;
            var maxWidth:int  = textField.width  - 4;
            
            while (textField.textWidth > maxWidth || textField.textHeight > maxHeight)
            {
                if (size <= 4) break;
                
                var format:flash.text.TextFormat = textField.defaultTextFormat;
                format.size = size--;
                textField.defaultTextFormat = format;

                if (_isHtmlText) textField.htmlText = _text;
                else             textField.text     = _text;
            }
        }

        // bitmap font composition
        
        private function createComposedContents():void
        {
            _disposeContents = disposeComposedContents;
            
            var bitmapFont:BitmapFont = getBitmapFont(_format.font);
            if (bitmapFont == null) throw new Error("Bitmap font not registered: " + _format.font);
            
            var width:Number  = _hitArea.width;
            var height:Number = _hitArea.height;
            var hAlign:String = _format.horizontalAlign;
            var vAlign:String = _format.verticalAlign;
            
            if (isHorizontalAutoSize)
            {
                width = int.MAX_VALUE;
                hAlign = Align.LEFT;
            }
            if (isVerticalAutoSize)
            {
                height = int.MAX_VALUE;
                vAlign = Align.TOP;
            }
            
            bitmapFont.fillMeshBatch(_meshBatch, width, height, _text, _format);

            if (_autoSize != TextFieldAutoSize.NONE)
            {
                _textBounds = _meshBatch.getBounds(_meshBatch, _textBounds);
                
                if (isHorizontalAutoSize)
                    _hitArea.width  = _textBounds.x + _textBounds.width;
                if (isVerticalAutoSize)
                    _hitArea.height = _textBounds.y + _textBounds.height;
            }
            else
            {
                // hit area doesn't change, text bounds can be created on demand
                _textBounds = null;
            }
        }

        private function disposeComposedContents():void
        {
            // nothing to dispose
        }
        
        // helpers
        
        private function updateBorder():void
        {
            if (_border == null) return;
            
            var width:Number  = _hitArea.width;
            var height:Number = _hitArea.height;
            
            var topLine:Quad    = _border.getChildAt(0) as Quad;
            var rightLine:Quad  = _border.getChildAt(1) as Quad;
            var bottomLine:Quad = _border.getChildAt(2) as Quad;
            var leftLine:Quad   = _border.getChildAt(3) as Quad;
            
            topLine.width    = width; topLine.height    = 1;
            bottomLine.width = width; bottomLine.height = 1;
            leftLine.width   = 1;     leftLine.height   = height;
            rightLine.width  = 1;     rightLine.height  = height;
            rightLine.x  = width  - 1;
            bottomLine.y = height - 1;
            topLine.color = rightLine.color = bottomLine.color = leftLine.color = _format.color;
        }

        private function setRequiresRecomposition():void
        {
            _requiresRecomposition = true;
            setRequiresRedraw();
        }

        // properties
        
        private function get isHorizontalAutoSize():Boolean
        {
            return _autoSize == TextFieldAutoSize.HORIZONTAL ||
                   _autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
        }
        
        private function get isVerticalAutoSize():Boolean
        {
            return _autoSize == TextFieldAutoSize.VERTICAL ||
                   _autoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
        }
        
        /** Returns the bounds of the text within the text field. */
        public function get textBounds():Rectangle
        {
            if (_requiresRecomposition) recompose();
            if (_textBounds == null) _textBounds = _meshBatch.getBounds(_meshBatch);
            return _textBounds.clone();
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, out:Rectangle=null):Rectangle
        {
            if (_requiresRecomposition) recompose();
            getTransformationMatrix(targetSpace, sHelperMatrix);
            return RectangleUtil.getBounds(_hitArea, sHelperMatrix, out);
        }
        
        /** @inheritDoc */
        public override function hitTest(localPoint:Point):DisplayObject
        {
            if (!visible || !touchable || !hitTestMask(localPoint)) return null;
            else if (_hitArea.containsPoint(localPoint)) return this;
            else return null;
        }

        /** @inheritDoc */
        public override function set width(value:Number):void
        {
            // different to ordinary display objects, changing the size of the text field should 
            // not change the scaling, but make the texture bigger/smaller, while the size 
            // of the text/font stays the same (this applies to the height, as well).
            
            _hitArea.width = value;
            setRequiresRecomposition();
        }
        
        /** @inheritDoc */
        public override function set height(value:Number):void
        {
            _hitArea.height = value;
            setRequiresRecomposition();
        }
        
        /** The displayed text. */
        public function get text():String { return _text; }
        public function set text(value:String):void
        {
            if (value == null) value = "";
            if (_text != value)
            {
                _text = value;
                setRequiresRecomposition();
            }
        }

        /** The format describes how the text will be rendered, describing the font name and size,
         *  color, alignment, etc.
         *
         *  <p>Note that you can edit the font properties directly; there's no need to reassign
         *  the format for the changes to show up.</p>
         *
         *  <listing>
         *  var textField:TextField = new TextField(100, 30, "Hello Starling");
         *  textField.format.font = "Arial";
         *  textField.format.color = Color.RED;</listing>
         *
         *  @default Verdana, 12 pt, black, centered
         */
        public function get format():TextFormat { return _format; }
        public function set format(value:TextFormat):void
        {
            if (value == null) throw new ArgumentError("format cannot be null");
            _format.copyFrom(value);
        }

        /** Draws a border around the edges of the text field. Useful for visual debugging.
         *  @default false */
        public function get border():Boolean { return _border != null; }
        public function set border(value:Boolean):void
        {
            if (value && _border == null)
            {                
                _border = new Sprite();
                addChild(_border);
                
                for (var i:int=0; i<4; ++i)
                    _border.addChild(new Quad(1.0, 1.0));
                
                updateBorder();
            }
            else if (!value && _border != null)
            {
                _border.removeFromParent(true);
                _border = null;
            }
        }
        
        /** Indicates whether the font size is scaled down so that the complete text fits
         *  into the text field. @default false */
        public function get autoScale():Boolean { return _autoScale; }
        public function set autoScale(value:Boolean):void
        {
            if (_autoScale != value)
            {
                _autoScale = value;
                setRequiresRecomposition();
            }
        }
        
        /** Specifies the type of auto-sizing the TextField will do.
         *  Note that any auto-sizing will make auto-scaling useless. Furthermore, it has 
         *  implications on alignment: horizontally auto-sized text will always be left-, 
         *  vertically auto-sized text will always be top-aligned. @default "none" */
        public function get autoSize():String { return _autoSize; }
        public function set autoSize(value:String):void
        {
            if (_autoSize != value)
            {
                _autoSize = value;
                setRequiresRecomposition();
            }
        }
        
        /** Indicates if TextField should be batched on rendering. This works only with bitmap
         *  fonts, and it makes sense only for TextFields with no more than 10-15 characters.
         *  Otherwise, the CPU costs will exceed any gains you get from avoiding the additional
         *  draw call. @default false */
        public function get batchable():Boolean { return _meshBatch.batchable; }
        public function set batchable(value:Boolean):void
        {
            _meshBatch.batchable = value;
        }

        /** Indicates if the assigned text should be interpreted as HTML code. For a description
         *  of the supported HTML subset, refer to the classic Flash 'TextField' documentation.
         *  Clickable hyperlinks and external images are not supported.
         *
         *  <p>BEWARE: this property is ignored when using bitmap fonts!</p> */
        public function get isHtmlText():Boolean { return _isHtmlText; }
        public function set isHtmlText(value:Boolean):void
        {
            if (_isHtmlText != value)
            {
                _isHtmlText = value;
                setRequiresRecomposition();
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
            bitmapFonts[convertToLowerCase(name)] = bitmapFont;
            return name;
        }

        /** Unregisters the bitmap font and, optionally, disposes it. */
        public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
        {
            name = convertToLowerCase(name);

            if (dispose && bitmapFonts[name] != undefined)
                bitmapFonts[name].dispose();

            delete bitmapFonts[name];
        }

        /** Returns a registered bitmap font (or null, if the font has not been registered).
         *  The name is not case sensitive. */
        public static function getBitmapFont(name:String):BitmapFont
        {
            return bitmapFonts[convertToLowerCase(name)];
        }
        
        /** Stores the currently available bitmap fonts. Since a bitmap font will only work
         *  in one Stage3D context, they are saved in Starling's 'contextData' property. */
        private static function get bitmapFonts():Dictionary
        {
            var fonts:Dictionary = Starling.painter.sharedData[BITMAP_FONT_DATA_NAME] as Dictionary;
            
            if (fonts == null)
            {
                fonts = new Dictionary();
                Starling.painter.sharedData[BITMAP_FONT_DATA_NAME] = fonts;
            }
            
            return fonts;
        }

        // optimization for 'toLowerCase' calls

        private static var sStringCache:Dictionary = new Dictionary();

        private static function convertToLowerCase(string:String):String
        {
            var result:String = sStringCache[string];
            if (result == null)
            {
                result = string.toLowerCase();
                sStringCache[string] = result;
            }
            return result;
        }
    }
}
