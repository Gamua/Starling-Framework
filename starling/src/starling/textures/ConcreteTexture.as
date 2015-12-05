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
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.media.Camera;
    import flash.net.NetStream;
    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;

    import starling.core.Starling;
    import starling.core.starling_internal;
    import starling.errors.MissingContextError;
    import starling.errors.NotSupportedError;
    import starling.events.Event;
    import starling.utils.Color;
    import starling.utils.RenderUtil;
    import starling.utils.execute;

    use namespace starling_internal;

    /** A ConcreteTexture wraps a Stage3D texture object, storing the properties of the texture. */
    public class ConcreteTexture extends Texture
    {
        private static const TEXTURE_READY:String = "textureReady"; // defined here for backwards compatibility
        
        private var _base:TextureBase;
        private var _format:String;
        private var _width:int;
        private var _height:int;
        private var _mipMapping:Boolean;
        private var _premultipliedAlpha:Boolean;
        private var _optimizedForRenderTexture:Boolean;
        private var _scale:Number;
        private var _onRestore:Function;
        private var _dataUploaded:Boolean;
        private var _textureReadyCallback:Function;
        
        /** helper object */
        private static var sOrigin:Point = new Point();
        
        /** Creates a ConcreteTexture object from a TextureBase, storing information about size,
         *  mip-mapping, and if the channels contain premultiplied alpha values. */
        public function ConcreteTexture(base:TextureBase, format:String, width:int, height:int, 
                                        mipMapping:Boolean, premultipliedAlpha:Boolean,
                                        optimizedForRenderTexture:Boolean=false, scale:Number=1)
        {
            _scale = scale <= 0 ? 1.0 : scale;
            _base = base;
            _format = format;
            _width = width;
            _height = height;
            _mipMapping = mipMapping;
            _premultipliedAlpha = premultipliedAlpha;
            _optimizedForRenderTexture = optimizedForRenderTexture;
            _onRestore = null;
            _dataUploaded = false;
            _textureReadyCallback = null;
        }
        
        /** Disposes the TextureBase object. */
        public override function dispose():void
        {
            if (_base)
            {
                _base.removeEventListener(TEXTURE_READY, onTextureReady);
                _base.dispose();
            }

            this.onRestore = null; // removes event listener
            super.dispose();
        }
        
        // texture data upload
        
        /** Uploads a bitmap to the texture. The existing contents will be replaced.
         *  If the size of the bitmap does not match the size of the texture, the bitmap will be
         *  cropped or filled up with transparent pixels */
        public function uploadBitmap(bitmap:Bitmap):void
        {
            uploadBitmapData(bitmap.bitmapData);
        }
        
        /** Uploads bitmap data to the texture. The existing contents will be replaced.
         *  If the size of the bitmap does not match the size of the texture, the bitmap will be
         *  cropped or filled up with transparent pixels */
        public function uploadBitmapData(data:BitmapData):void
        {
            var potData:BitmapData;
            
            if (data.width != _width || data.height != _height)
            {
                potData = new BitmapData(_width, _height, true, 0);
                potData.copyPixels(data, data.rect, sOrigin);
                data = potData;
            }
            
            if (_base is flash.display3D.textures.Texture)
            {
                var potTexture:flash.display3D.textures.Texture = 
                    _base as flash.display3D.textures.Texture;
                
                potTexture.uploadFromBitmapData(data);
                
                if (_mipMapping && data.width > 1 && data.height > 1)
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
            else // if (_base is RectangleTexture)
            {
                _base["uploadFromBitmapData"](data);
            }
            
            if (potData) potData.dispose();
            _dataUploaded = true;
        }
        
        /** Uploads ATF data from a ByteArray to the texture. Note that the size of the
         *  ATF-encoded data must be exactly the same as the original texture size.
         *  
         *  <p>The 'async' parameter may be either a boolean value or a callback function.
         *  If it's <code>false</code> or <code>null</code>, the texture will be decoded
         *  synchronously and will be visible right away. If it's <code>true</code> or a function,
         *  the data will be decoded asynchronously. The texture will remain unchanged until the
         *  upload is complete, at which time the callback function will be executed. This is the
         *  expected function definition: <code>function(texture:Texture):void;</code></p>
         */
        public function uploadAtfData(data:ByteArray, offset:int=0, async:*=null):void
        {
            var isAsync:Boolean = async is Function || async === true;
            var potTexture:flash.display3D.textures.Texture = 
                  _base as flash.display3D.textures.Texture;
            
            if (potTexture == null)
                throw new Error("This texture type does not support ATF data");
            
            if (async is Function)
            {
                _textureReadyCallback = async as Function;
                _base.addEventListener(TEXTURE_READY, onTextureReady);
            }
            
            potTexture.uploadCompressedTextureFromByteArray(data, offset, isAsync);
            _dataUploaded = true;
        }

        public function attachNetStream(netStream:NetStream, onComplete:Function=null):void
        {
            attachVideo("NetStream", netStream, onComplete);
        }

        public function attachCamera(camera:Camera, onComplete:Function=null):void
        {
            attachVideo("Camera", camera, onComplete);
        }

        internal function attachVideo(type:String, attachment:Object, onComplete:Function=null):void
        {
            const className:String = getQualifiedClassName(_base);

            if (className == "flash.display3D.textures::VideoTexture")
            {
                _dataUploaded = true;
                _textureReadyCallback = onComplete;
                _base["attach" + type](attachment);
                _base.addEventListener(TEXTURE_READY, onTextureReady);
            }
            else throw new Error("This texture type does not support " + type + " data");
        }

        private function onTextureReady(event:Object):void
        {
            _base.removeEventListener(TEXTURE_READY, onTextureReady);
            execute(_textureReadyCallback, this);
            _textureReadyCallback = null;
        }
        
        // texture backup (context loss)
        
        private function onContextCreated():void
        {
            // recreate the underlying texture & restore contents
            createBase();
            if (_onRestore != null) _onRestore();
            
            // if no texture has been uploaded above, we init the texture with transparent pixels.
            if (!_dataUploaded) clear();
        }
        
        /** Recreates the underlying Stage3D texture object with the same dimensions and attributes
         *  as the one that was passed to the constructor. You have to upload new data before the
         *  texture becomes usable again. Beware: this method does <strong>not</strong> dispose
         *  the current base. */
        starling_internal function createBase():void
        {
            var context:Context3D = Starling.context;
            var className:String = getQualifiedClassName(_base);
            
            if (className == "flash.display3D.textures::Texture")
                _base = context.createTexture(_width, _height, _format,
                                              _optimizedForRenderTexture);
            else if (className == "flash.display3D.textures::RectangleTexture")
                _base = context["createRectangleTexture"](_width, _height, _format,
                                                          _optimizedForRenderTexture);
            else if (className == "flash.display3D.textures::VideoTexture")
                _base = context["createVideoTexture"]();
            else
                throw new NotSupportedError("Texture type not supported: " + className);

            _dataUploaded = false;
        }
        
        /** Clears the texture with a certain color and alpha value. The previous contents of the
         *  texture is wiped out. Beware: this method resets the render target to the back buffer; 
         *  don't call it from within a render method. */ 
        public function clear(color:uint=0x0, alpha:Number=0.0):void
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            if (_premultipliedAlpha && alpha < 1.0)
                color = Color.rgb(Color.getRed(color)   * alpha,
                                  Color.getGreen(color) * alpha,
                                  Color.getBlue(color)  * alpha);
            
            context.setRenderToTexture(_base);
            
            // we wrap the clear call in a try/catch block as a workaround for a problem of
            // FP 11.8 plugin/projector: calling clear on a compressed texture doesn't work there
            // (while it *does* work on iOS + Android).
            
            try { RenderUtil.clear(color, alpha); }
            catch (e:Error) {}
            
            context.setRenderToBackBuffer();
            _dataUploaded = true;
        }
        
        // properties
        
        /** Indicates if the base texture was optimized for being used in a render texture. */
        public function get optimizedForRenderTexture():Boolean { return _optimizedForRenderTexture; }
        
        /** The function that you provide here will be called after a context loss.
         *  On execution, a new base texture will already have been created; however,
         *  it will be empty. Call one of the "upload..." methods from within the callbacks
         *  to restore the actual texture data. */
        public function get onRestore():Function { return _onRestore; }
        public function set onRestore(value:Function):void
        {
            Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            
            if (value != null)
            {
                _onRestore = value;
                Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            }
            else _onRestore = null;
        }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return _base; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return this; }
        
        /** @inheritDoc */
        public override function get format():String { return _format; }
        
        /** @inheritDoc */
        public override function get width():Number  { return _width / _scale;  }
        
        /** @inheritDoc */
        public override function get height():Number { return _height / _scale; }
        
        /** @inheritDoc */
        public override function get nativeWidth():Number { return _width; }
        
        /** @inheritDoc */
        public override function get nativeHeight():Number { return _height; }
        
        /** The scale factor, which influences width and height properties. */
        public override function get scale():Number { return _scale; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return _mipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return _premultipliedAlpha; }
    }
}