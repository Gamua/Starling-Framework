// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures
{
    import starling.core.Starling;

    /** The TextureOptions class specifies options for loading textures with the 'Texture.fromData'
     *  method. */ 
    public class TextureOptions
    {
        private var _scale:Number;
        private var _format:String;
        private var _mipMapping:Boolean;
        private var _optimizeForRenderToTexture:Boolean = false;
        private var _onReady:Function = null;

        public function TextureOptions(scale:Number=1.0, mipMapping:Boolean=false, 
                                       format:String="bgra")
        {
            _scale = scale;
            _format = format;
            _mipMapping = mipMapping;
        }
        
        /** Creates a clone of the TextureOptions object with the exact same properties. */
        public function clone():TextureOptions
        {
            var clone:TextureOptions = new TextureOptions(_scale, _mipMapping, _format);
            clone._optimizeForRenderToTexture = _optimizeForRenderToTexture;
            clone._onReady = _onReady;
            return clone;
        }

        /** The scale factor, which influences width and height properties. If you pass '-1',
         *  the current global content scale factor will be used. */
        public function get scale():Number { return _scale; }
        public function set scale(value:Number):void
        {
            _scale = value > 0 ? value : Starling.contentScaleFactor;
        }
        
        /** The <code>Context3DTextureFormat</code> of the underlying texture data. Only used
         *  for textures that are created from Bitmaps; the format of ATF files is set when they
         *  are created. */
        public function get format():String { return _format; }
        public function set format(value:String):void { _format = value; }
        
        /** Indicates if the texture contains mip maps. */ 
        public function get mipMapping():Boolean { return _mipMapping; }
        public function set mipMapping(value:Boolean):void { _mipMapping = value; }
        
        /** Indicates if the texture will be used as render target. */
        public function get optimizeForRenderToTexture():Boolean { return _optimizeForRenderToTexture; }
        public function set optimizeForRenderToTexture(value:Boolean):void { _optimizeForRenderToTexture = value; }
     
        /** A callback that is used only for ATF textures; if it is set, the ATF data will be
         *  decoded asynchronously. The texture can only be used when the callback has been
         *  executed. This property is ignored for all other texture types (they are ready
         *  immediately when the 'Texture.from...' method returns, anyway).
         *  
         *  <p>This is the expected function definition: 
         *  <code>function(texture:Texture):void;</code></p> 
         */
        public function get onReady():Function { return _onReady; }
        public function set onReady(value:Function):void { _onReady = value; }
    }
}