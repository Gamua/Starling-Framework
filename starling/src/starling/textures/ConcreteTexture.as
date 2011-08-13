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
    import flash.display3D.textures.TextureBase;

    public class ConcreteTexture extends Texture
    {
        private var mBase:TextureBase;
        private var mWidth:int;
        private var mHeight:int;
        private var mMipMapping:Boolean;
        
        public function ConcreteTexture(base:TextureBase, width:int, height:int, 
                                        mipMapping:Boolean=false)
        {
            mBase = base;
            mWidth = width;
            mHeight = height;
            mMipMapping = mipMapping;
        }
        
        public override function dispose():void
        {
            if (mBase) mBase.dispose();
            super.dispose();
        }
        
        public override function get base():TextureBase { return mBase; }
        public override function get width():Number  { return mWidth;  }
        public override function get height():Number { return mHeight; }
        public override function get mipMapping():Boolean { return mMipMapping; }
    }
}