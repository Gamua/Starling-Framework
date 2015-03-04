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
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.TextureBase;
    import flash.utils.getQualifiedClassName;

    /** A concrete texture that may only be used for a 'VideoTexture' base.
     *  For internal use only. */
    internal class ConcreteVideoTexture extends ConcreteTexture
    {
        /** Creates a new VideoTexture. 'base' must be of type 'VideoTexture'. */
        public function ConcreteVideoTexture(base:TextureBase, scale:Number = 1)
        {
            // we must not reference the "VideoTexture" class directly
            // because it's only available in AIR.

            var format:String = Context3DTextureFormat.BGRA;
            var width:Number  = "videoWidth"  in base ? base["videoWidth"]  : 0;
            var height:Number = "videoHeight" in base ? base["videoHeight"] : 0;

            super(base, format, width, height, false, false, false, scale, false);

            if (getQualifiedClassName(base) != "flash.display3D.textures::VideoTexture")
                throw new ArgumentError("'base' must be VideoTexture");
        }

        /** The actual width of the video in pixels. */
        override public function get nativeWidth():Number
        {
            return base["videoWidth"];
        }

        /** The actual height of the video in pixels. */
        override public function get nativeHeight():Number
        {
            return base["videoHeight"];
        }

        /** inheritDoc */
        override public function get width():Number
        {
            return nativeWidth / scale;
        }

        /** inheritDoc */
        override public function get height():Number
        {
            return nativeHeight / scale;
        }
    }
}
