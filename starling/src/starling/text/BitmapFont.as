﻿// =================================================================================================
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
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import starling.display.Image;
    import starling.display.MeshBatch;
    import starling.display.Sprite;
    import starling.styles.DistanceFieldStyle;
    import starling.styles.MeshStyle;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.Align;
    import starling.utils.StringUtil;

    /** The BitmapFont class parses bitmap font files and arranges the glyphs
     *  in the form of a text.
     *
     *  The class parses the XML format as it is used in the 
     *  <a href="http://www.angelcode.com/products/bmfont/">AngelCode Bitmap Font Generator</a> or
     *  the <a href="http://glyphdesigner.71squared.com/">Glyph Designer</a>. 
     *  This is what the file format looks like:
     *
     *  <pre> 
     *  &lt;font&gt;
     *    &lt;info face="BranchingMouse" size="40" /&gt;
     *    &lt;common lineHeight="40" /&gt;
     *    &lt;pages&gt;  &lt;!-- currently, only one page is supported --&gt;
     *      &lt;page id="0" file="texture.png" /&gt;
     *    &lt;/pages&gt;
     *    &lt;chars&gt;
     *      &lt;char id="32" x="60" y="29" width="1" height="1" xoffset="0" yoffset="27" xadvance="8" /&gt;
     *      &lt;char id="33" x="155" y="144" width="9" height="21" xoffset="0" yoffset="6" xadvance="9" /&gt;
     *    &lt;/chars&gt;
     *    &lt;kernings&gt; &lt;!-- Kerning is optional --&gt;
     *      &lt;kerning first="83" second="83" amount="-4"/&gt;
     *    &lt;/kernings&gt;
     *  &lt;/font&gt;
     *  </pre>
     *  
     *  Pass an instance of this class to the method <code>registerBitmapFont</code> of the
     *  TextField class. Then, set the <code>fontName</code> property of the text field to the 
     *  <code>name</code> value of the bitmap font. This will make the text field use the bitmap
     *  font.  
     */ 
    public class BitmapFont implements ITextCompositor
    {
        /** Use this constant for the <code>fontSize</code> property of the TextField class to 
         *  render the bitmap font in exactly the size it was created. */ 
        public static const NATIVE_SIZE:int = -1;
        
        /** The font name of the embedded minimal bitmap font. Use this e.g. for debug output. */
        public static const MINI:String = "mini";

        private static const CHAR_MISSING:int         =  0;
        private static const CHAR_TAB:int             =  9;
        private static const CHAR_NEWLINE:int         = 10;
        private static const CHAR_CARRIAGE_RETURN:int = 13;
        private static const CHAR_SPACE:int           = 32;

        private var _texture:Texture;
        private var _chars:Dictionary;
        private var _name:String;
        private var _size:Number;
        private var _lineHeight:Number;
        private var _baseline:Number;
        private var _offsetX:Number;
        private var _offsetY:Number;
        private var _padding:Number;
        private var _helperImage:Image;
        private var _type:String;
        private var _distanceFieldSpread:Number;

        // helper objects
        private static var sLines:Array = [];
        private static var sDefaultOptions:TextOptions = new TextOptions();

        /** Creates a bitmap font from the given texture and font data.
         *  If you don't pass any data, the "mini" font will be created.
         *
         * @param texture  The texture containing all the glyphs.
         * @param fontData Typically an XML file in the standard AngelCode format. Override the
         *                 the 'parseFontData' method to add support for additional formats.
         */
        public function BitmapFont(texture:Texture=null, fontData:*=null)
        {
            // if no texture is passed in, we create the minimal, embedded font
            if (texture == null && fontData == null)
            {
                texture = MiniBitmapFont.texture;
                fontData = MiniBitmapFont.xml;
            }
            else if (texture == null || fontData == null)
            {
                throw new ArgumentError("Set both of the 'texture' and 'fontData' " +
                    "arguments to valid objects or leave both of them null.");
            }
            
            _name = "unknown";
            _lineHeight = _size = _baseline = 14;
            _offsetX = _offsetY = _padding = 0.0;
            _texture = texture;
            _chars = new Dictionary();
            _helperImage = new Image(texture);
            _type = BitmapFontType.STANDARD;
            _distanceFieldSpread = 0.0;

            addChar(CHAR_MISSING, new BitmapChar(CHAR_MISSING, null, 0, 0, 0));
            parseFontData(fontData);
        }
        
        /** Disposes the texture of the bitmap font. */
        public function dispose():void
        {
            if (_texture)
                _texture.dispose();
        }

        /** Parses the data that's passed as second argument to the constructor.
         *  Override this method to support different file formats. */
        protected function parseFontData(data:*):void
        {
            if (data is XML) parseFontXml(data);
            else throw new ArgumentError("BitmapFont only supports XML data");
        }
        
        private function parseFontXml(fontXml:XML):void
        {
            var scale:Number = _texture.scale;
            var frame:Rectangle = _texture.frame;
            var frameX:Number = frame ? frame.x : 0;
            var frameY:Number = frame ? frame.y : 0;
            
            _name = StringUtil.clean(fontXml.info.@face);
            _size = parseFloat(fontXml.info.@size) / scale;
            _lineHeight = parseFloat(fontXml.common.@lineHeight) / scale;
            _baseline = parseFloat(fontXml.common.@base) / scale;
            
            if (fontXml.info.@smooth.toString() == "0")
                smoothing = TextureSmoothing.NONE;
            
            if (_size <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + _name + "' font.");
                _size = (_size == 0.0 ? 16.0 : _size * -1.0);
            }

            if (fontXml.distanceField.length())
            {
                _distanceFieldSpread = parseFloat(fontXml.distanceField.@distanceRange);
                _type = fontXml.distanceField.@fieldType == "msdf" ?
                    BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD : BitmapFontType.DISTANCE_FIELD;
            }
            else
            {
                _distanceFieldSpread = 0.0;
                _type = BitmapFontType.STANDARD;
            }
            
            for each (var charElement:XML in fontXml.chars.char)
            {
                var id:int = parseInt(charElement.@id);
                var xOffset:Number  = parseFloat(charElement.@xoffset)  / scale;
                var yOffset:Number  = parseFloat(charElement.@yoffset)  / scale;
                var xAdvance:Number = parseFloat(charElement.@xadvance) / scale;
                
                var region:Rectangle = new Rectangle();
                region.x = parseFloat(charElement.@x) / scale + frameX;
                region.y = parseFloat(charElement.@y) / scale + frameY;
                region.width  = parseFloat(charElement.@width)  / scale;
                region.height = parseFloat(charElement.@height) / scale;
                
                var texture:Texture = Texture.fromTexture(_texture, region);
                var bitmapChar:BitmapChar = new BitmapChar(id, texture, xOffset, yOffset, xAdvance); 
                addChar(id, bitmapChar);
            }
            
            for each (var kerningElement:XML in fontXml.kernings.kerning)
            {
                var first:int  = parseInt(kerningElement.@first);
                var second:int = parseInt(kerningElement.@second);
                var amount:Number = parseFloat(kerningElement.@amount) / scale;
                if (second in _chars) getChar(second).addKerning(first, amount);
            }
        }
        
        /** Returns a single bitmap char with a certain character ID. */
        public function getChar(charID:int):BitmapChar
        {
            return _chars[charID];
        }
        
        /** Adds a bitmap char with a certain character ID. */
        public function addChar(charID:int, bitmapChar:BitmapChar):void
        {
            _chars[charID] = bitmapChar;
        }
        
        /** Returns a vector containing all the character IDs that are contained in this font. */
        public function getCharIDs(out:Vector.<int>=null):Vector.<int>
        {
            if (out == null) out = new <int>[];

            for(var key:* in _chars)
                out[out.length] = int(key);

            return out;
        }

        /** Checks whether a provided string can be displayed with the font. */
        public function hasChars(text:String):Boolean
        {
            if (text == null) return true;

            var charID:int;
            var numChars:int = text.length;

            for (var i:int=0; i<numChars; ++i)
            {
                charID = text.charCodeAt(i);

                if (charID != CHAR_SPACE && charID != CHAR_TAB && charID != CHAR_NEWLINE &&
                    charID != CHAR_CARRIAGE_RETURN && getChar(charID) == null)
                {
                    return false;
                }
            }

            return true;
        }

        /** Creates a sprite that contains a certain text, made up by one image per char. */
        public function createSprite(width:Number, height:Number, text:String,
                                     format:TextFormat, options:TextOptions=null):Sprite
        {
            var charLocations:Vector.<BitmapCharLocation> = arrangeChars(width, height, text, format, options);
            var numChars:int = charLocations.length;
            var smoothing:String = this.smoothing;
            var sprite:Sprite = new Sprite();
            
            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:BitmapCharLocation = charLocations[i];
                var char:Image = charLocation.char.createImage();
                char.x = charLocation.x;
                char.y = charLocation.y;
                char.scale = charLocation.scale;
                char.color = format.color;
                char.textureSmoothing = smoothing;
                sprite.addChild(char);
            }
            
            BitmapCharLocation.rechargePool();
            return sprite;
        }
        
        /** Draws text into a QuadBatch. */
        public function fillMeshBatch(meshBatch:MeshBatch, width:Number, height:Number, text:String,
                                      format:TextFormat, options:TextOptions=null):void
        {
            var charLocations:Vector.<BitmapCharLocation> = arrangeChars(
                    width, height, text, format, options);
            var numChars:int = charLocations.length;
            _helperImage.color = format.color;

            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:BitmapCharLocation = charLocations[i];
                _helperImage.texture = charLocation.char.texture;
                _helperImage.readjustSize();
                _helperImage.x = charLocation.x;
                _helperImage.y = charLocation.y;
                _helperImage.scale = charLocation.scale;
                meshBatch.addMesh(_helperImage);
            }

            BitmapCharLocation.rechargePool();
        }

        /** @inheritDoc */
        public function clearMeshBatch(meshBatch:MeshBatch):void
        {
            meshBatch.clear();
        }

        /** @inheritDoc */
        public function getDefaultMeshStyle(previousStyle:MeshStyle,
                                            format:TextFormat, options:TextOptions):MeshStyle
        {
            if (_type == BitmapFontType.STANDARD) return null;
            else // -> distance field font
            {
                var dfStyle:DistanceFieldStyle;
                var fontSize:Number = format.size < 0 ? format.size * -_size : format.size;
                dfStyle = previousStyle as DistanceFieldStyle || new DistanceFieldStyle();
                dfStyle.multiChannel = (_type == BitmapFontType.MULTI_CHANNEL_DISTANCE_FIELD);
                dfStyle.softness = _size / (fontSize * _distanceFieldSpread);
                return dfStyle;
            }
        }
        
        /** Arranges the characters of text inside a rectangle, adhering to the given settings.
         *  Returns a Vector of BitmapCharLocations.
         *
         *  <p>BEWARE: This method uses an object pool for the returned vector and all
         *  (returned and temporary) BitmapCharLocation instances. Do not save any references and
         *  always call <code>BitmapCharLocation.rechargePool()</code> when you are done processing.
         *  </p>
         */
        public function arrangeChars(width:Number, height:Number, text:String,
                                     format:TextFormat, options:TextOptions):Vector.<BitmapCharLocation>
        {
            if (text == null || text.length == 0) return BitmapCharLocation.vectorFromPool();
            if (options == null) options = sDefaultOptions;

            var kerning:Boolean = format.kerning;
            var leading:Number = format.leading;
            var spacing:Number = format.letterSpacing;
            var hAlign:String = format.horizontalAlign;
            var vAlign:String = format.verticalAlign;
            var fontSize:Number = format.size;
            var autoScale:Boolean = options.autoScale;
            var wordWrap:Boolean = options.wordWrap;

            var finished:Boolean = false;
            var charLocation:BitmapCharLocation;
            var numChars:int;
            var containerWidth:Number;
            var containerHeight:Number;
            var scale:Number;
            var i:int, j:int;

            if (fontSize < 0) fontSize *= -_size;
            
            while (!finished)
            {
                sLines.length = 0;
                scale = fontSize / _size;
                containerWidth  = (width  - 2 * _padding) / scale;
                containerHeight = (height - 2 * _padding) / scale;
                
                if (_size <= containerHeight)
                {
                    var lastWhiteSpace:int = -1;
                    var lastCharID:int = -1;
                    var currentX:Number = 0;
                    var currentY:Number = 0;
                    var currentLine:Vector.<BitmapCharLocation> = BitmapCharLocation.vectorFromPool();
                    
                    numChars = text.length;
                    for (i=0; i<numChars; ++i)
                    {
                        var lineFull:Boolean = false;
                        var charID:int = text.charCodeAt(i);
                        var char:BitmapChar = getChar(charID);
                        
                        if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN)
                        {
                            lineFull = true;
                        }
                        else
                        {
                            if (char == null)
                            {
                                trace(StringUtil.format(
                                    "[Starling] Character '{0}' (id: {1}) not found in '{2}'",
                                    text.charAt(i), charID, name));

                                charID = CHAR_MISSING;
                                char = getChar(CHAR_MISSING);
                            }

                            if (charID == CHAR_SPACE || charID == CHAR_TAB)
                                lastWhiteSpace = i;
                            
                            if (kerning)
                                currentX += char.getKerning(lastCharID);
                            
                            charLocation = BitmapCharLocation.instanceFromPool(char);
                            charLocation.index = i;
                            charLocation.x = currentX + char.xOffset;
                            charLocation.y = currentY + char.yOffset;
                            currentLine[currentLine.length] = charLocation; // push
                            
                            currentX += char.xAdvance + spacing;
                            lastCharID = charID;
                            
                            if (charLocation.x + char.width > containerWidth)
                            {
                                if (wordWrap)
                                {
                                    // when autoscaling, we must not split a word in half -> restart
                                    if (autoScale && lastWhiteSpace == -1)
                                        break;

                                    // remove characters and add them again to next line
                                    var numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;

                                    for (j=0; j<numCharsToRemove; ++j) // faster than 'splice'
                                        currentLine.pop();

                                    if (currentLine.length == 0)
                                        break;

                                    i -= numCharsToRemove;
                                }
                                else
                                {
                                    if (autoScale) break;
                                    currentLine.pop();

                                    // continue with next line, if there is one
                                    while (i < numChars - 1 && text.charCodeAt(i) != CHAR_NEWLINE)
                                        ++i;
                                }

                                lineFull = true;
                            }
                        }
                        
                        if (i == numChars - 1)
                        {
                            sLines[sLines.length] = currentLine; // push
                            finished = true;
                        }
                        else if (lineFull)
                        {
                            sLines[sLines.length] = currentLine; // push
                            
                            if (lastWhiteSpace == i)
                                currentLine.pop();
                            
                            if (currentY + _lineHeight + leading + _size <= containerHeight)
                            {
                                currentLine = BitmapCharLocation.vectorFromPool();
                                currentX = 0;
                                currentY += _lineHeight + leading;
                                lastWhiteSpace = -1;
                                lastCharID = -1;
                            }
                            else
                            {
                                break;
                            }
                        }
                    } // for each char
                } // if (_lineHeight <= containerHeight)
                
                if (autoScale && !finished && fontSize > 3)
                    fontSize -= 1;
                else
                    finished = true; 
            } // while (!finished)
            
            var finalLocations:Vector.<BitmapCharLocation> = BitmapCharLocation.vectorFromPool();
            var numLines:int = sLines.length;
            var bottom:Number = currentY + _lineHeight;
            var yOffset:int = 0;
            
            if (vAlign == Align.BOTTOM)      yOffset =  containerHeight - bottom;
            else if (vAlign == Align.CENTER) yOffset = (containerHeight - bottom) / 2;
            
            for (var lineID:int=0; lineID<numLines; ++lineID)
            {
                var line:Vector.<BitmapCharLocation> = sLines[lineID];
                numChars = line.length;
                
                if (numChars == 0) continue;
                
                var xOffset:int = 0;
                var lastLocation:BitmapCharLocation = line[line.length-1];
                var right:Number = lastLocation.x - lastLocation.char.xOffset 
                                                  + lastLocation.char.xAdvance;
                
                if (hAlign == Align.RIGHT)       xOffset =  containerWidth - right;
                else if (hAlign == Align.CENTER) xOffset = (containerWidth - right) / 2;
                
                for (var c:int=0; c<numChars; ++c)
                {
                    charLocation = line[c];
                    charLocation.x = scale * (charLocation.x + xOffset + _offsetX) + _padding;
                    charLocation.y = scale * (charLocation.y + yOffset + _offsetY) + _padding;
                    charLocation.scale = scale;
                    
                    if (charLocation.char.width > 0 && charLocation.char.height > 0)
                        finalLocations[finalLocations.length] = charLocation;
                }
            }
            
            return finalLocations;
        }
        
        /** The name of the font as it was parsed from the font file. */
        public function get name():String { return _name; }
        public function set name(value:String):void { _name = value; }
        
        /** The native size of the font. */
        public function get size():Number { return _size; }
        public function set size(value:Number):void { _size = value; }

        /** The type of the bitmap font. @see starling.text.BitmapFontType @default standard */
        public function get type():String { return _type; }
        public function set type(value:String):void { _type = value; }

        /** If the font uses a distance field texture, this property returns its spread (i.e.
         *  the width of the blurred edge in points). */
        public function get distanceFieldSpread():Number { return _distanceFieldSpread; }
        public function set distanceFieldSpread(value:Number):void { _distanceFieldSpread = value; }
        
        /** The height of one line in points. */
        public function get lineHeight():Number { return _lineHeight; }
        public function set lineHeight(value:Number):void { _lineHeight = value; }
        
        /** The smoothing filter that is used for the texture. */ 
        public function get smoothing():String { return _helperImage.textureSmoothing; }
        public function set smoothing(value:String):void { _helperImage.textureSmoothing = value; }
        
        /** The baseline of the font. This property does not affect text rendering;
         *  it's just an information that may be useful for exact text placement. */
        public function get baseline():Number { return _baseline; }
        public function set baseline(value:Number):void { _baseline = value; }
        
        /** An offset that moves any generated text along the x-axis (in points).
         *  Useful to make up for incorrect font data. @default 0. */ 
        public function get offsetX():Number { return _offsetX; }
        public function set offsetX(value:Number):void { _offsetX = value; }
        
        /** An offset that moves any generated text along the y-axis (in points).
         *  Useful to make up for incorrect font data. @default 0. */
        public function get offsetY():Number { return _offsetY; }
        public function set offsetY(value:Number):void { _offsetY = value; }

        /** The width of a "gutter" around the composed text area, in points.
         *  This can be used to bring the output more in line with standard TrueType rendering:
         *  Flash always draws them with 2 pixels of padding. @default 0.0 */
        public function get padding():Number { return _padding; }
        public function set padding(value:Number):void { _padding = value; }

        /** The underlying texture that contains all the chars. */
        public function get texture():Texture { return _texture; }
    }
}
