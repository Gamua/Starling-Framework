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
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

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
    public class BitmapFont
    {
        /** Use this constant for the <code>fontSize</code> property of the TextField class to 
         *  render the bitmap font in exactly the size it was created. */ 
        public static const NATIVE_SIZE:int = -1;
        
        private static const CHAR_SPACE:int   = 32;
        private static const CHAR_TAB:int     =  9;
        private static const CHAR_NEWLINE:int = 10;
        
        private var mTexture:Texture;
        private var mChars:Dictionary;
        private var mName:String;
        private var mSize:Number;
        private var mLineHeight:Number;
        
        /** Creates a bitmap font by parsing an XML file and uses the specified texture. */
        public function BitmapFont(texture:Texture, fontXml:XML=null)
        {
            mName = "unknown";
            mLineHeight = mSize = 14;
            mTexture = texture;
            mChars = new Dictionary();
            
            if (fontXml)
                parseFontXml(fontXml);
        }
        
        /** Disposes the texture of the bitmap font! */
        public function dispose():void
        {
            if (mTexture)
                mTexture.dispose();
        }
        
        private function parseFontXml(fontXml:XML):void
        {
            var scale:Number = mTexture.scale;
            var frame:Rectangle = mTexture.frame;
            
            mName = fontXml.info.attribute("face");
            mSize = parseFloat(fontXml.info.attribute("size")) / scale;
            mLineHeight = parseFloat(fontXml.common.attribute("lineHeight")) / scale;
            
            if (mSize <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + mName + "' font.");
                mSize = (mSize == 0.0 ? 16.0 : mSize * -1.0);
            }
            
            for each (var charElement:XML in fontXml.chars.char)
            {
                var id:int = parseInt(charElement.attribute("id"));
                var xOffset:Number = parseFloat(charElement.attribute("xoffset")) / scale;
                var yOffset:Number = parseFloat(charElement.attribute("yoffset")) / scale;
                var xAdvance:Number = parseFloat(charElement.attribute("xadvance")) / scale;
                
                var region:Rectangle = new Rectangle();
                region.x = parseFloat(charElement.attribute("x")) / scale + frame.x;
                region.y = parseFloat(charElement.attribute("y")) / scale + frame.y;
                region.width  = parseFloat(charElement.attribute("width")) / scale;
                region.height = parseFloat(charElement.attribute("height")) / scale;
                
                var texture:Texture = Texture.fromTexture(mTexture, region);
                var bitmapChar:BitmapChar = new BitmapChar(id, texture, xOffset, yOffset, xAdvance); 
                addChar(id, bitmapChar);
            }
            
            for each (var kerningElement:XML in fontXml.kernings.kerning)
            {
                var first:int = parseInt(kerningElement.attribute("first"));
                var second:int = parseInt(kerningElement.attribute("second"));
                var amount:Number = parseFloat(kerningElement.attribute("amount")) / scale;
                if (second in mChars) getChar(second).addKerning(first, amount);
            }
        }
        
        /** Returns a single bitmap char with a certain character ID. */
        public function getChar(charID:int):BitmapChar
        {
            return mChars[charID];   
        }
        
        /** Adds a bitmap char with a certain character ID. */
        public function addChar(charID:int, bitmapChar:BitmapChar):void
        {
            mChars[charID] = bitmapChar;
        }
        
        /** Creates a display object that contains the given text by arranging individual chars. */
        public function createDisplayObject(width:Number, height:Number, text:String,
                                            fontSize:Number=-1, color:uint=0xffffff, 
                                            hAlign:String="center", vAlign:String="center",      
                                            autoScale:Boolean=true, 
                                            kerning:Boolean=true):DisplayObject
        {
            if (fontSize == NATIVE_SIZE) fontSize = mSize;
            
            var lineContainer:Sprite;
            var finished:Boolean = false;
            
            while (!finished)
            {
                var scale:Number = fontSize / mSize;
                lineContainer = new Sprite();
                
                if (mLineHeight * scale <= height)
                {
                    var containerWidth:Number  = width / scale;
                    var containerHeight:Number = height / scale;
                    lineContainer.scaleX = lineContainer.scaleY = scale;
                
                    var lastWhiteSpace:int = -1;
                    var lastCharID:int = -1;
                    var currentX:Number = 0;
                    var currentLine:Sprite = new Sprite();
                    var numChars:int = text.length;
                
                    for (var i:int=0; i<numChars; ++i)
                    {
                        var lineFull:Boolean = false;
                        
                        var charID:int = text.charCodeAt(i);
                        if (charID == CHAR_NEWLINE)
                        {
                            lineFull = true;
                        }
                        else
                        {
                            var bitmapChar:BitmapChar = getChar(charID);
                            
                            if (bitmapChar == null)
                            {
                                trace("[Starling] Missing character: " + charID);
                                continue;
                            }
                            
                            if (charID == CHAR_SPACE || charID == CHAR_TAB)
                                lastWhiteSpace = i;
                            
                            var charImage:Image = bitmapChar.createImage();
                            
                            if (kerning)
                                currentX += bitmapChar.getKerning(lastCharID);
                            
                            charImage.x = currentX + bitmapChar.xOffset;
                            charImage.y = bitmapChar.yOffset;
                            charImage.color = color;
                            currentLine.addChild(charImage);
                            
                            currentX += bitmapChar.xAdvance;
                            lastCharID = charID;
                            
                            if (currentX > containerWidth)
                            {
                                // remove characters and add them again to next line
                                var numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;
                                var removeIndex:int = currentLine.numChildren - numCharsToRemove;
                                
                                for (var r:int=0; r<numCharsToRemove; ++r)
                                    currentLine.removeChildAt(removeIndex);
                                
                                if (currentLine.numChildren == 0)
                                    break;
                                
                                var lastChar:DisplayObject = currentLine.getChildAt(currentLine.numChildren-1);
                                currentX = lastChar.x + lastChar.width;
                                
                                i -= numCharsToRemove;
                                lineFull = true;
                            }
                        }
                        
                        if (i == numChars - 1)
                        {
                            lineContainer.addChild(currentLine);
                            finished = true;
                        }
                        else if (lineFull)
                        {
                            lineContainer.addChild(currentLine);
                            var nextLineY:Number = currentLine.y + mLineHeight;
                            
                            if (nextLineY + mLineHeight <= containerHeight)
                            {
                                currentLine = new Sprite();
                                currentLine.y = nextLineY;
                                currentX = 0;
                                lastWhiteSpace = -1;
                                lastCharID = -1;
                            }
                            else
                            {
                                break;
                            }
                        }
                    } // for each char
                } // if (mLineHeight * scale <= height)
                
                if (autoScale && !finished)
                {
                    fontSize -= 1;
                    lineContainer.dispose();
                }
                else
                {
                    finished = true; 
                }
                
            } // while (!finished)
            
            if (hAlign != HAlign.LEFT)
            {
                var numLines:int = lineContainer.numChildren;
                for (var l:int=0; l<numLines; ++l)
                {
                    var line:Sprite = lineContainer.getChildAt(l) as Sprite;
                    var finalChar:DisplayObject = line.getChildAt(line.numChildren-1);
                    var lineWidth:Number = finalChar.x + finalChar.width;
                    var widthDiff:Number = containerWidth - lineWidth;
                    line.x = int(hAlign == HAlign.RIGHT ? widthDiff : widthDiff / 2);
                }
            }
            
            var outerContainer:Sprite = new Sprite();
            outerContainer.addChild(lineContainer);
            
            if (vAlign != VAlign.TOP)
            {
                var contentHeight:Number = lineContainer.numChildren * mLineHeight * scale;
                var heightDiff:Number = height - contentHeight;
                lineContainer.y = int(vAlign == VAlign.BOTTOM ? heightDiff : heightDiff / 2);
            }
            
            outerContainer.flatten();
            return outerContainer;
        }
        
        /** The name of the font as it was parsed from the font file. */
        public function get name():String { return mName; }
        
        /** The native size of the font. */
        public function get size():Number { return mSize; }
        
        /** The height of one line in pixels. */
        public function get lineHeight():Number { return mLineHeight; }
        public function set lineHeight(value:Number):void { mLineHeight = value; }
    }
}