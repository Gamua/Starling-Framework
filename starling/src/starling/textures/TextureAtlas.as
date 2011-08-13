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

    public class TextureAtlas
    {
        private var mAtlasTexture:Texture;
        private var mTextureRegions:Dictionary;
        private var mTextureFrames:Dictionary;
        
        public function TextureAtlas(texture:Texture, atlasXml:XML=null)
        {
            mTextureRegions = new Dictionary();
            mTextureFrames  = new Dictionary();
            mAtlasTexture   = texture;
            
            if (atlasXml)
                parseAtlasXml(atlasXml);
        }
        
        public function dispose():void
        {
            mAtlasTexture.dispose();
        }
        
        private function parseAtlasXml(atlasXml:XML):void
        {
            for each (var subTexture:XML in atlasXml.SubTexture)
            {                
                var name:String        = subTexture.attribute("name");
                var x:Number           = parseFloat(subTexture.attribute("x"));
                var y:Number           = parseFloat(subTexture.attribute("y"));
                var width:Number       = parseFloat(subTexture.attribute("width"));
                var height:Number      = parseFloat(subTexture.attribute("height"));
                var frameX:Number      = parseFloat(subTexture.attribute("frameX"));
                var frameY:Number      = parseFloat(subTexture.attribute("frameY"));
                var frameWidth:Number  = parseFloat(subTexture.attribute("frameWidth"));
                var frameHeight:Number = parseFloat(subTexture.attribute("frameHeight"));
                
                var region:Rectangle = new Rectangle(x, y, width, height);
                var frame:Rectangle  = frameWidth > 0 && frameHeight > 0 ?
                        new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;
                
                addRegion(name, region, frame);
            }
        }
        
        public function getTexture(name:String):Texture
        {
            var region:Rectangle = mTextureRegions[name];
            
            if (region == null) return null;
            else
            {
                var texture:Texture = Texture.fromTexture(mAtlasTexture, region);
                texture.frame = mTextureFrames[name];
                return texture;
            }
        }
        
        public function getTextures(prefix:String=""):Vector.<Texture>
        {
            var textures:Vector.<Texture> = new <Texture>[];
            var names:Vector.<String> = new <String>[];
            var name:String;
            
            for (name in mTextureRegions)
                if (name.indexOf(prefix) == 0)                
                    names.push(name);                
            
            names.sort(Array.CASEINSENSITIVE);
            
            for each (name in names) 
                textures.push(getTexture(name)); 
            
            return textures;
        }
        
        public function addRegion(name:String, region:Rectangle, frame:Rectangle=null):void
        {
            mTextureRegions[name] = region;
            if (frame) mTextureFrames[name] = frame;
        }
        
        public function removeRegion(name:String):void
        {
            delete mTextureRegions[name];
        }
    }
}