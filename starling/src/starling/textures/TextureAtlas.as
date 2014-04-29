// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures
{
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    /** A texture atlas is a collection of many smaller textures in one big image. This class
     *  is used to access textures from such an atlas.
     *  
     *  <p>Using a texture atlas for your textures solves two problems:</p>
     *  
     *  <ul>
     *    <li>Whenever you switch between textures, the batching of image objects is disrupted.</li>
     *    <li>Any Stage3D texture has to have side lengths that are powers of two. Starling hides 
     *        this limitation from you, but at the cost of additional graphics memory.</li>
     *  </ul>
     *  
     *  <p>By using a texture atlas, you avoid both texture switches and the power-of-two 
     *  limitation. All textures are within one big "super-texture", and Starling takes care that 
     *  the correct part of this texture is displayed.</p>
     *  
     *  <p>There are several ways to create a texture atlas. One is to use the atlas generator 
     *  script that is bundled with Starling's sibling, the <a href="http://www.sparrow-framework.org">
     *  Sparrow framework</a>. It was only tested in Mac OS X, though. A great multi-platform 
     *  alternative is the commercial tool <a href="http://www.texturepacker.com">
     *  Texture Packer</a>.</p>
     *  
     *  <p>Whatever tool you use, Starling expects the following file format:</p>
     * 
     *  <listing>
     * 	&lt;TextureAtlas imagePath='atlas.png'&gt;
     * 	  &lt;SubTexture name='texture_1' x='0'  y='0' width='50' height='50'/&gt;
     * 	  &lt;SubTexture name='texture_2' x='50' y='0' width='20' height='30'/&gt; 
     * 	&lt;/TextureAtlas&gt;
     *  </listing>
     *  
     *  <strong>Texture Frame</strong>
     *
     *  <p>If your images have transparent areas at their edges, you can make use of the 
     *  <code>frame</code> property of the Texture class. Trim the texture by removing the 
     *  transparent edges and specify the original texture size like this:</p>
     * 
     *  <listing>
     * 	&lt;SubTexture name='trimmed' x='0' y='0' height='10' width='10'
     * 	    frameX='-10' frameY='-10' frameWidth='30' frameHeight='30'/&gt;
     *  </listing>
     *
     *  <strong>Texture Rotation</strong>
     *
     *  <p>Some atlas generators can optionally rotate individual textures to optimize the texture
     *  distribution. This is supported via the boolean attribute "rotated". If it is set to
     *  <code>true</code> for a certain subtexture, this means that the texture on the atlas
     *  has been rotated by 90 degrees, clockwise. Starling will undo that rotation by rotating
     *  it counter-clockwise.</p>
     *
     *  <p>In this case, the positional coordinates (<code>x, y, width, height</code>)
     *  are expected to point at the subtexture as it is present on the atlas (in its rotated
     *  form), while the "frame" properties must describe the texture in its upright form.</p>
     *
     */
    public class TextureAtlas
    {
        private var mAtlasTexture:Texture;
        private var mTextureInfos:Dictionary;
        
        /** helper objects */
        private static var sNames:Vector.<String> = new <String>[];
        
        /** Create a texture atlas from a texture by parsing the regions from an XML file. */
        public function TextureAtlas(texture:Texture, atlasXml:XML=null)
        {
            mTextureInfos = new Dictionary();
            mAtlasTexture = texture;
            
            if (atlasXml)
                parseAtlasXml(atlasXml);
        }
        
        /** Disposes the atlas texture. */
        public function dispose():void
        {
            mAtlasTexture.dispose();
        }
        
        /** This function is called by the constructor and will parse an XML in Starling's 
         *  default atlas file format. Override this method to create custom parsing logic
         *  (e.g. to support a different file format). */
        protected function parseAtlasXml(atlasXml:XML):void
        {
            var scale:Number = mAtlasTexture.scale;
            
            for each (var subTexture:XML in atlasXml.SubTexture)
            {
                var name:String        = subTexture.attribute("name");
                var x:Number           = parseFloat(subTexture.attribute("x")) / scale;
                var y:Number           = parseFloat(subTexture.attribute("y")) / scale;
                var width:Number       = parseFloat(subTexture.attribute("width")) / scale;
                var height:Number      = parseFloat(subTexture.attribute("height")) / scale;
                var frameX:Number      = parseFloat(subTexture.attribute("frameX")) / scale;
                var frameY:Number      = parseFloat(subTexture.attribute("frameY")) / scale;
                var frameWidth:Number  = parseFloat(subTexture.attribute("frameWidth")) / scale;
                var frameHeight:Number = parseFloat(subTexture.attribute("frameHeight")) / scale;
                var rotated:Boolean    = parseBool(subTexture.attribute("rotated"));
                
                var region:Rectangle = new Rectangle(x, y, width, height);
                var frame:Rectangle  = frameWidth > 0 && frameHeight > 0 ?
                        new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;
                
                addRegion(name, region, frame, rotated);
            }
        }
        
        /** Retrieves a subtexture by name. Returns <code>null</code> if it is not found. */
        public function getTexture(name:String):Texture
        {
            var info:TextureInfo = mTextureInfos[name];
            
            if (info == null) return null;
            else return Texture.fromTexture(mAtlasTexture, info.region, info.frame, info.rotated);
        }
        
        /** Returns all textures that start with a certain string, sorted alphabetically
         *  (especially useful for "MovieClip"). */
        public function getTextures(prefix:String="", result:Vector.<Texture>=null):Vector.<Texture>
        {
            if (result == null) result = new <Texture>[];
            
            for each (var name:String in getNames(prefix, sNames)) 
                result.push(getTexture(name)); 

            sNames.length = 0;
            return result;
        }
        
        /** Returns all texture names that start with a certain string, sorted alphabetically. */
        public function getNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
        {
            if (result == null) result = new <String>[];
            
            for (var name:String in mTextureInfos)
                if (name.indexOf(prefix) == 0)
                    result.push(name);
            
            result.sort(Array.CASEINSENSITIVE);
            return result;
        }
        
        /** Returns the region rectangle associated with a specific name. */
        public function getRegion(name:String):Rectangle
        {
            var info:TextureInfo = mTextureInfos[name];
            return info ? info.region : null;
        }
        
        /** Returns the frame rectangle of a specific region, or <code>null</code> if that region 
         *  has no frame. */
        public function getFrame(name:String):Rectangle
        {
            var info:TextureInfo = mTextureInfos[name];
            return info ? info.frame : null;
        }
        
        /** If true, the specified region in the atlas is rotated by 90 degrees (clockwise). The
         *  SubTexture is thus rotated counter-clockwise to cancel out that transformation. */
        public function getRotation(name:String):Boolean
        {
            var info:TextureInfo = mTextureInfos[name];
            return info ? info.rotated : false;
        }

        /** Adds a named region for a subtexture (described by rectangle with coordinates in 
         *  pixels) with an optional frame. */
        public function addRegion(name:String, region:Rectangle, frame:Rectangle=null,
                                  rotated:Boolean=false):void
        {
            mTextureInfos[name] = new TextureInfo(region, frame, rotated);
        }
        
        /** Removes a region with a certain name. */
        public function removeRegion(name:String):void
        {
            delete mTextureInfos[name];
        }
        
        /** The base texture that makes up the atlas. */
        public function get texture():Texture { return mAtlasTexture; }
        
        // utility methods
        
        private static function parseBool(value:String):Boolean
        {
            return value.toLowerCase() == "true";
        }
    }
}

import flash.geom.Rectangle;
import starling.textures.Texture;

class TextureInfo
{
    public var region:Rectangle;
    public var frame:Rectangle;
    public var rotated:Boolean;
    
    public function TextureInfo(region:Rectangle, frame:Rectangle, rotated:Boolean)
    {
        this.region = region;
        this.frame = frame;
        this.rotated = rotated;       
    }
}