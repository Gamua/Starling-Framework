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
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.utils.getNextPowerOfTwo;

    /** A ConcreteTexture wraps a Stage3D texture object, storing the properties of the texture. */
    public class ConcreteTexture extends Texture
    {
        private var mBase:TextureBase;
        private var mFormat:String;
        private var mWidth:int;
        private var mHeight:int;
        private var mMipMapping:Boolean;
        private var mPremultipliedAlpha:Boolean;
        private var mOptimizedForRenderTexture:Boolean;
        private var mScale:Number;
        private var mOnRestore:Function;
        private var mDataUploaded:Boolean;
        
        /** Creates a ConcreteTexture object from a TextureBase, storing information about size,
         *  mip-mapping, and if the channels contain premultiplied alpha values. */
        public function ConcreteTexture(base:TextureBase, format:String, width:int, height:int, 
                                        mipMapping:Boolean, premultipliedAlpha:Boolean,
                                        optimizedForRenderTexture:Boolean=false,
                                        scale:Number=1)
        {
            mScale = scale <= 0 ? 1.0 : scale;
            mBase = base;
            mFormat = format;
            mWidth = width;
            mHeight = height;
            mMipMapping = mipMapping;
            mPremultipliedAlpha = premultipliedAlpha;
            mOptimizedForRenderTexture = optimizedForRenderTexture;
            mOnRestore = null;
            mDataUploaded = false;
        }
        
        /** Disposes the TextureBase object. */
        public override function dispose():void
        {
            if (mBase) mBase.dispose();
            this.onRestore = null; // removes event listener 
            super.dispose();
        }
        
        // texture data upload
        
        /** Uploads bitmap data to the texture, optionally creating mipmaps. Note that the
         *  size of the bitmap data must be exactly the same as the original texture size. */
        public function uploadBitmapData(data:BitmapData, generateMipmaps:Boolean):void
        {
            if (mBase is flash.display3D.textures.Texture)
            {
                var potTexture:flash.display3D.textures.Texture = 
                    mBase as flash.display3D.textures.Texture;
                
                potTexture.uploadFromBitmapData(data);
                
                if (generateMipmaps && data.width > 1 && data.height > 1)
                {
                    var currentWidth:int  = data.width  >> 1;
                    var currentHeight:int = data.height >> 1;
                    var level:int = 1;
                    var canvas:BitmapData = new BitmapData(currentWidth, currentHeight, true, 0);
                    var transform:Matrix = new Matrix(.5, 0, 0, .5);
                    var bounds:Rectangle = new Rectangle();
                    
                    while (currentWidth >= 1 || currentHeight >= 1)
                    {
                        bounds.width = currentWidth; bounds.height = currentHeight;
                        canvas.fillRect(bounds, 0);
                        canvas.draw(data, transform, null, null, null, true);
                        potTexture.uploadFromBitmapData(canvas, level++);
                        transform.scale(0.5, 0.5);
                        currentWidth  = currentWidth  >> 1;
                        currentHeight = currentHeight >> 1;
                    }
                    
                    canvas.dispose();
                }
            }
            else // if (nativeTexture is RectangleTexture)
            {
                mBase["uploadFromBitmapData"](data);
            }
            
            mDataUploaded = true;
        }
        
        /** Uploads ATF data from a ByteArray to the texture. Note that the size of the
         *  ATF-encoded data must be exactly the same as the original texture size. */
        public function uploadAtfData(data:ByteArray, offset:int=0, async:Boolean=false):void
        {
            var potTexture:flash.display3D.textures.Texture = 
                  mBase as flash.display3D.textures.Texture;
            
            potTexture.uploadCompressedTextureFromByteArray(data, offset, async);
            mDataUploaded = true;
        }
        
        // texture backup (context loss)
        
        private function onContextCreated():void
        {
            var context:Context3D = Starling.context;
            var isPot:Boolean = mWidth  == getNextPowerOfTwo(mWidth) && 
                                mHeight == getNextPowerOfTwo(mHeight);
            
            if (isPot)
                mBase = context.createTexture(mWidth, mHeight, mFormat, 
                                              mOptimizedForRenderTexture);
            else
                mBase = context["createRectangleTexture"](mWidth, mHeight, mFormat,
                                                          mOptimizedForRenderTexture);
            
            // a chance to upload texture data
            mOnRestore();
            
            // if no texture has been uploaded (yet), we init the texture with transparent pixels.
            if (!mDataUploaded) clear();
        }
        
        /** Clears the texture with a certain color and alpha value. The previous contents of the
         *  texture is wiped out. Beware: this method resets the render target to the back buffer; 
         *  don't call it from within a render method. */ 
        public function clear(color:uint=0xffffff, alpha:Number=0.0):void
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            context.setRenderToTexture(mBase);
            RenderSupport.clear(color, alpha);
            context.setRenderToBackBuffer();
            
            mDataUploaded = true;
        }
        
        // properties
        
        /** Indicates if the base texture was optimized for being used in a render texture. */
        public function get optimizedForRenderTexture():Boolean { return mOptimizedForRenderTexture; }
        
        /** If Starling's "handleLostContext" setting is enabled, the function that you provide
         *  here will be called after a context loss. On execution, a new base texture will 
         *  already have been created; however, it will be empty. Call one of the "upload..." 
         *  methods from within the callbacks to restore the actual texture data. */ 
        public function get onRestore():Function { return mOnRestore; }
        public function set onRestore(value:Function):void
        { 
            if (mOnRestore == null && value != null)
                Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            else if (value == null)
                Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            
            mOnRestore = value; 
        }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mBase; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return this; }
        
        /** @inheritDoc */
        public override function get format():String { return mFormat; }
        
        /** @inheritDoc */
        public override function get width():Number  { return mWidth / mScale;  }
        
        /** @inheritDoc */
        public override function get height():Number { return mHeight / mScale; }
        
        /** @inheritDoc */
        public override function get nativeWidth():Number { return mWidth; }
        
        /** @inheritDoc */
        public override function get nativeHeight():Number { return mHeight; }
        
        /** The scale factor, which influences width and height properties. */
        public override function get scale():Number { return mScale; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return mMipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
    }
}