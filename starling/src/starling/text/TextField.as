// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text
{
    import flash.display3D.Context3DTextureFormat;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.MeshBatch;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.rendering.Painter;
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
     *  avoid that; bitmap fonts, however, may be batched as long as the <code>batchable</code>
     *  property is enabled. Since only batchable meshes can make use of Starling's render cache,
     *  it makes sense to keep that property enabled in most circumstances. Only TextFields that
     *  are constantly changing (their position relative to the stage, their color, text, etc.)
     *  and contain are large number of bitmap glyphs should disable batching.</p>
     */
    public class TextField extends DisplayObjectContainer
    {
        // the name container with the registered bitmap fonts
        private static const BITMAP_FONT_DATA_NAME:String = "starling.display.TextField.BitmapFonts";

        private var _text:String;
        private var _options:TextOptions;
        private var _format:TextFormat;
        private var _autoSize:String;
        private var _textBounds:Rectangle;
        private var _hitArea:Rectangle;
        private var _compositor:ITextCompositor;
        private var _requiresRecomposition:Boolean;
        private var _border:DisplayObjectContainer;
        private var _meshBatch:MeshBatch;

        // helper objects
        private static var sMatrix:Matrix = new Matrix();
        private static var sTrueTypeCompositor:TrueTypeCompositor = new TrueTypeCompositor();
        private static var sDefaultTextureFormat:String = Context3DTextureFormat.BGRA_PACKED;
        private var _helperFormat:TextFormat = new TextFormat();

        /** Create a new text field with the given properties. */
        public function TextField(width:int, height:int, text:String="", format:TextFormat=null)
        {
            _text = text ? text : "";
            _autoSize = TextFieldAutoSize.NONE;
            _hitArea = new Rectangle(0, 0, width, height);
            _requiresRecomposition = true;
            _compositor = sTrueTypeCompositor;
            _options = new TextOptions();

            _format = format ? format.clone() : new TextFormat();
            _format.addEventListener(Event.CHANGE, setRequiresRecomposition);

            _meshBatch = new MeshBatch();
            _meshBatch.touchable = false;
            addChild(_meshBatch);
        }
        
        /** Disposes the underlying texture data. */
        public override function dispose():void
        {
            _format.removeEventListener(Event.CHANGE, setRequiresRecomposition);
            _compositor.clearMeshBatch(_meshBatch);

            super.dispose();
        }
        
        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            if (_requiresRecomposition) recompose();
            super.render(painter);
        }

        /** Forces the text contents to be composed right away.
         *  Normally, it will only do so lazily, i.e. before being rendered. */
        private function recompose():void
        {
            if (_requiresRecomposition)
            {
                _compositor.clearMeshBatch(_meshBatch);

                var font:String = _format.font;
                var bitmapFont:BitmapFont = getBitmapFont(font);

                if (bitmapFont == null && font == BitmapFont.MINI)
                {
                    bitmapFont = new BitmapFont();
                    registerBitmapFont(bitmapFont);
                }

                _compositor = bitmapFont ? bitmapFont : sTrueTypeCompositor;

                updateText();
                updateBorder();

                _requiresRecomposition = false;
            }
        }

        // font and border rendering
        
        private function updateText():void
        {
            var width:Number  = _hitArea.width;
            var height:Number = _hitArea.height;
            var format:TextFormat = _helperFormat;

            // By working on a copy of the TextFormat, we make sure that modifications done
            // within the 'fillMeshBatch' method do not cause any side effects.
            //
            // (We cannot use a static variable, because that might lead to problems when
            //  recreating textures after a context loss.)

            format.copyFrom(_format);

            if (isHorizontalAutoSize) width = 100000;
            if (isVerticalAutoSize)  height = 100000;

            _options.textureScale = Starling.contentScaleFactor;
            _options.textureFormat = sDefaultTextureFormat;
            _compositor.fillMeshBatch(_meshBatch, width, height, _text, format, _options);

            if (_autoSize != TextFieldAutoSize.NONE)
            {
                _textBounds = _meshBatch.getBounds(_meshBatch, _textBounds);

                if (isHorizontalAutoSize)
                {
                    _meshBatch.x = _textBounds.x = -_textBounds.x;
                    _hitArea.width = _textBounds.width;
                }

                if (isVerticalAutoSize)
                {
                    _meshBatch.y = _textBounds.y = -_textBounds.y;
                    _hitArea.height = _textBounds.height;
                }
            }
            else
            {
                // hit area doesn't change, and text bounds can be created on demand
                _textBounds = null;
            }
        }

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
            getTransformationMatrix(targetSpace, sMatrix);
            return RectangleUtil.getBounds(_hitArea, sMatrix, out);
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
        
        /** Indicates whether the font size is automatically reduced if the complete text does
         *  not fit into the TextField. @default false */
        public function get autoScale():Boolean { return _options.autoScale; }
        public function set autoScale(value:Boolean):void
        {
            if (_options.autoScale != value)
            {
                _options.autoScale = value;
                setRequiresRecomposition();
            }
        }
        
        /** Specifies the type of auto-sizing the TextField will do.
         *  Note that any auto-sizing will implicitly deactivate all auto-scaling.
         *  @default none */
        public function get autoSize():String { return _autoSize; }
        public function set autoSize(value:String):void
        {
            if (_autoSize != value)
            {
                _autoSize = value;
                setRequiresRecomposition();
            }
        }

        /** Indicates if the text should be wrapped at word boundaries if it does not fit into
         *  the TextField otherwise. @default true */
        public function get wordWrap():Boolean { return _options.wordWrap; }
        public function set wordWrap(value:Boolean):void
        {
            if (value != _options.wordWrap)
            {
                _options.wordWrap = value;
                setRequiresRecomposition();
            }
        }
        
        /** Indicates if TextField should be batched on rendering.
         *
         *  <p>Only batchable meshes can profit from the render cache; but batching large meshes
         *  may take up a lot of CPU time. Thus, for large bitmap font text fields (i.e. many
         *  glyphs) that are constantly changing (i.e. can't use the render cache anyway), it
         *  makes sense to deactivate batching.</p>
         *
         *  @default true
         */
        public function get batchable():Boolean { return _meshBatch.batchable; }
        public function set batchable(value:Boolean):void
        {
            _meshBatch.batchable = value;
        }

        /** Indicates if text should be interpreted as HTML code. For a description
         *  of the supported HTML subset, refer to the classic Flash 'TextField' documentation.
         *  Clickable hyperlinks and external images are not supported. Only works for
         *  TrueType fonts! @default false */
        public function get isHtmlText():Boolean { return _options.isHtmlText; }
        public function set isHtmlText(value:Boolean):void
        {
            if (_options.isHtmlText != value)
            {
                _options.isHtmlText = value;
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
