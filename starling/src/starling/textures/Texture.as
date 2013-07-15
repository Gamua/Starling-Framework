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
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.TextureBase;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.Starling;
    import starling.errors.AbstractClassError;
    import starling.errors.MissingContextError;
    import starling.utils.Color;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    /** <p>A texture stores the information that represents an image. It cannot be added to the
     *  display list directly; instead it has to be mapped onto a display object. In Starling, 
     *  that display object is the class "Image".</p>
     * 
     *  <strong>Texture Formats</strong>
     *  
     *  <p>Since textures can be created from a "BitmapData" object, Starling supports any bitmap
     *  format that is supported by Flash. And since you can render any Flash display object into
     *  a BitmapData object, you can use this to display non-Starling content in Starling - e.g.
     *  Shape objects.</p>
     *  
     *  <p>Starling also supports ATF textures (Adobe Texture Format), which is a container for
     *  compressed texture formats that can be rendered very efficiently by the GPU. Refer to 
     *  the Flash documentation for more information about this format.</p>
     *  
     *  <strong>Mip Mapping</strong>
     *  
     *  <p>MipMaps are scaled down versions of a texture. When an image is displayed smaller than
     *  its natural size, the GPU may display the mip maps instead of the original texture. This
     *  reduces aliasing and accelerates rendering. It does, however, also need additional memory;
     *  for that reason, you can choose if you want to create them or not.</p>  
     *  
     *  <strong>Texture Frame</strong>
     *  
     *  <p>The frame property of a texture allows you let a texture appear inside the bounds of an
     *  image, leaving a transparent space around the texture. The frame rectangle is specified in 
     *  the coordinate system of the texture (not the image):</p>
     *  
     *  <listing>
     *  var frame:Rectangle = new Rectangle(-10, -10, 30, 30); 
     *  var texture:Texture = Texture.fromTexture(anotherTexture, null, frame);
     *  var image:Image = new Image(texture);</listing>
     *  
     *  <p>This code would create an image with a size of 30x30, with the texture placed at 
     *  <code>x=10, y=10</code> within that image (assuming that 'anotherTexture' has a width and 
     *  height of 10 pixels, it would appear in the middle of the image).</p>
     *  
     *  <p>The texture atlas makes use of this feature, as it allows to crop transparent edges
     *  of a texture and making up for the changed size by specifying the original texture frame.
     *  Tools like <a href="http://www.texturepacker.com/">TexturePacker</a> use this to  
     *  optimize the atlas.</p>
     * 
     *  <strong>Texture Coordinates</strong>
     *  
     *  <p>If, on the other hand, you want to show only a part of the texture in an image
     *  (i.e. to crop the the texture), you can either create a subtexture (with the method 
     *  'Texture.fromTexture()' and specifying a rectangle for the region), or you can manipulate 
     *  the texture coordinates of the image object. The method 'image.setTexCoords' allows you 
     *  to do that.</p>
     * 
     *  <strong>Context Loss</strong>
     *  
     *  <p>When the current rendering context is lost (which can happen e.g. on Android and
     *  Windows), all texture data is lost. If you have activated "Starling.handleLostContext", 
     *  however, Starling will try to restore the textures. To do that, it will keep the bitmap
     *  and ATF data in memory - at the price of increased RAM consumption. To save memory,
     *  however, you can restore a texture directly from its source (e.g. an embedded asset):</p>
     *  
     *  <listing>
     *  var texture:Texture = Texture.fromBitmap(new EmbeddedBitmap());
     *  texture.root.onRestore = function():void 
     *  { 
     *      texture.root.uploadFromBitmap(new EmbeddedBitmap());
     *  };</listing>
     *  
     *  <p>The "onRestore"-method will be called when the context was lost and the texture has
     *  been recreated (but is still empty). If you use the "AssetManager" class to manage
     *  your textures, this will be done automatically.</p>
     *  
     *  @see starling.display.Image
     *  @see starling.utils.AssetManager
     *  @see TextureAtlas
     */ 
    public class Texture
    {
        private var mFrame:Rectangle;
        private var mRepeat:Boolean;
        
        /** @private */
        public function Texture()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.textures::Texture")
            {
                throw new AbstractClassError();
            }
            
            mRepeat = false;
        }
        
        /** Disposes the underlying texture data. Note that not all textures need to be disposed: 
         *  SubTextures (created with 'Texture.fromTexture') just reference other textures and
         *  and do not take up resources themselves; this is also true for textures from an 
         *  atlas. */
        public function dispose():void
        { 
            // override in subclasses
        }
        
        /** Creates a texture object from an embedded asset class. Textures created with this
         *  method will be restored directly from the asset class in case of a context loss,
         *  which guarantees a very economic memory usage.  
         * 
         *  @param assetClass: must contain either a Bitmap or a ByteArray with ATF data.
         *  @param mipMaps:    for Bitmaps, indicates if mipMaps will be created;
         *                     for ATF data, indicates if the contained mipMaps will be used.
         *  @param optimizeForRenderToTexture: indicates if this texture will be used as 
         *                     render target
         *  @param scale:      the scale factor of the created texture. 
         */
        public static function fromEmbeddedAsset(assetClass:Class, mipMapping:Boolean=true,
                                                 optimizeForRenderToTexture:Boolean=false,
                                                 scale:Number=1):Texture
        {
            var texture:Texture;
            var asset:Object = new assetClass();
            
            if (asset is Bitmap)
            {
                texture = Texture.fromBitmap(asset as Bitmap, mipMapping, false, scale);
                texture.root.onRestore = function():void
                {
                    texture.root.uploadBitmap(new assetClass());
                };
            }
            else if (asset is ByteArray)
            {
                texture = Texture.fromAtfData(asset as ByteArray, scale, mipMapping);
                texture.root.onRestore = function():void
                {
                    texture.root.uploadAtfData(new assetClass()); 
                };
            }
            else
            {
                throw new ArgumentError("Invalid asset type: " + getQualifiedClassName(asset));
            }
            
            asset = null; // avoid that object stays in memory (through 'onRestore' functions)
            return texture;
        }
        
        /** Creates a texture object from a bitmap.
         *  Beware: you must not dispose 'data' if Starling should handle a lost device context. */
        public static function fromBitmap(data:Bitmap, generateMipMaps:Boolean=true,
                                          optimizeForRenderToTexture:Boolean=false,
                                          scale:Number=1):Texture
        {
            return fromBitmapData(data.bitmapData, generateMipMaps, optimizeForRenderToTexture, scale);
        }
        
        /** Creates a texture from bitmap data. 
         *  Beware: you must not dispose 'data' if Starling should handle a lost device context. */
        public static function fromBitmapData(data:BitmapData, generateMipMaps:Boolean=true,
                                              optimizeForRenderToTexture:Boolean=false,
                                              scale:Number=1):Texture
        {
            var texture:Texture = Texture.empty(data.width / scale, data.height / scale, true, 
                                                generateMipMaps, optimizeForRenderToTexture, scale);
            
            texture.root.uploadBitmapData(data);
            
            // TODO: add documentation about lost context handling vs. this method
            
            if (Starling.handleLostContext)
                texture.root.onRestore = function():void
                {
                    texture.root.uploadBitmapData(data);
                };
            
            return texture;
        }
        
        /** Creates a texture from the compressed ATF format. If you don't want to use any embedded
         *  mipmaps, you can disable them by setting "useMipMaps" to <code>false</code>.
         *  Beware: you must not dispose 'data' if Starling should handle a lost device context.
         *  
         *  <p>If you pass a function for the 'loadAsync' parameter, the method will return
         *  immediately, while the texture will be created asynchronously. It can be used as soon
         *  as the callback has been executed. This is the expected function definition:
         *  <code>function(texture:Texture):void;</code></p> */ 
        public static function fromAtfData(data:ByteArray, scale:Number=1, useMipMaps:Boolean=true, 
                                           loadAsync:Function=null):Texture
        {
            const eventType:String = "textureReady"; // defined here for backwards compatibility
            
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            var async:Boolean = loadAsync != null;
            var atfData:AtfData = new AtfData(data);
            var nativeTexture:flash.display3D.textures.Texture = context.createTexture(
                atfData.width, atfData.height, atfData.format, false);
            var concreteTexture:ConcreteTexture = new ConcreteTexture(nativeTexture, atfData.format, 
                atfData.width, atfData.height, useMipMaps && atfData.numTextures > 1, 
                false, false, scale);
            
            if (async)
                nativeTexture.addEventListener(eventType, onTextureReady);
            
            concreteTexture.uploadAtfData(data, 0, async);
            
            if (Starling.handleLostContext) 
                concreteTexture.onRestore = function():void
                {
                    concreteTexture.uploadAtfData(data, 0, async);
                };
            
            return concreteTexture;
            
            function onTextureReady(event:Event):void
            {
                nativeTexture.removeEventListener(eventType, onTextureReady);
                if (loadAsync.length == 1) loadAsync(concreteTexture);
                else loadAsync();
            }
        }
        
        /** Creates a texture with a certain size and color.
         *  
         *  @param width:  in points; number of pixels depends on scale parameter
         *  @param height: in points; number of pixels depends on scale parameter
         *  @param color:  expected in ARGB format (inlude alpha!)
         *  @param optimizeForRenderToTexture: indicates if this texture will be used as render target
         *  @param scale:  if you omit this parameter, 'Starling.contentScaleFactor' will be used.
         */
        public static function fromColor(width:int, height:int, color:uint=0xffffffff,
                                         optimizeForRenderToTexture:Boolean=false, 
                                         scale:Number=-1):Texture
        {
            var texture:Texture = Texture.empty(width, height, true, false, 
                                                optimizeForRenderToTexture, scale);
            texture.root.clear(color, Color.getAlpha(color) / 255.0);
            
            texture.root.onRestore = function():void
            {
                texture.root.clear(color, Color.getAlpha(color) / 255.0);
            };
            
            return texture;
        }
        
        /** Creates an empty texture of a certain size. 
         *  Beware that the texture can only be used after you either upload some color data
         *  ("texture.root.upload...") or clear the texture ("texture.root.clear()").
         *  
         *  @param width:  in points; number of pixels depends on scale parameter
         *  @param height: in points; number of pixels depends on scale parameter
         *  @param premultipliedAlpha: the PMA format you will use the texture with. If you will
         *                 use the texture for bitmap data, use "true"; for ATF data, use "false".
         *  @param mipMapping: indicates if mipmaps should be used for this texture. When you upload
         *                 bitmap data, this decides if mipmaps will be created; when you upload ATF
         *                 data, this decides if mipmaps inside the ATF file will be displayed.
         *  @param optimizeForRenderToTexture: indicates if this texture will be used as render target 
         *  @param scale:  if you omit this parameter, 'Starling.contentScaleFactor' will be used.
         */
        public static function empty(width:int, height:int, premultipliedAlpha:Boolean=true,
                                     mipMapping:Boolean=true, optimizeForRenderToTexture:Boolean=false,
                                     scale:Number=-1):Texture
        {
            if (scale <= 0) scale = Starling.contentScaleFactor;
            
            var actualWidth:int, actualHeight:int;
            var nativeTexture:flash.display3D.textures.TextureBase;
            var context:Context3D = Starling.context;
            
            if (context == null) throw new MissingContextError();
            
            var origWidth:int  = width  * scale;
            var origHeight:int = height * scale;
            var potWidth:int   = getNextPowerOfTwo(origWidth);
            var potHeight:int  = getNextPowerOfTwo(origHeight);
            var isPot:Boolean  = (origWidth == potWidth && origHeight == potHeight);
            var useRectTexture:Boolean = !isPot && !mipMapping &&
                Starling.current.profile != "baselineConstrained" &&
                "createRectangleTexture" in context;
            
            if (useRectTexture)
            {
                actualWidth  = origWidth;
                actualHeight = origHeight;
                
                // Rectangle Textures are supported beginning with AIR 3.8. By calling the new
                // methods only through those lookups, we stay compatible with older SDKs.
                nativeTexture = context["createRectangleTexture"](actualWidth, actualHeight, 
                    Context3DTextureFormat.BGRA, optimizeForRenderToTexture);
            }
            else
            {
                actualWidth  = potWidth;
                actualHeight = potHeight;
                
                nativeTexture = context.createTexture(actualWidth, actualHeight, 
                    Context3DTextureFormat.BGRA, optimizeForRenderToTexture);
            }
            
            var concreteTexture:ConcreteTexture = new ConcreteTexture(
                nativeTexture, Context3DTextureFormat.BGRA, actualWidth, actualHeight,
                mipMapping, true, optimizeForRenderToTexture, scale);
            
            if (Starling.handleLostContext)
                concreteTexture.onRestore = concreteTexture.clear;
            
            if (isPot || useRectTexture)
                return concreteTexture;
            else
                return new SubTexture(concreteTexture, new Rectangle(0, 0, width, height), true);
        }
        
        /** Creates a texture that contains a region (in pixels) of another texture. The new
         *  texture will reference the base texture; no data is duplicated. */
        public static function fromTexture(texture:Texture, region:Rectangle=null, frame:Rectangle=null):Texture
        {
            var subTexture:Texture = new SubTexture(texture, region);   
            subTexture.mFrame = frame;
            return subTexture;
        }
        
        /** Converts texture coordinates and vertex positions of raw vertex data into the format 
         *  required for rendering. While the texture coordinates of an image always use the
         *  range <code>[0, 1]</code>, the actual coordinates could be different: you
         *  might be working with a SubTexture or a texture frame. This method
         *  adjusts the texture and vertex coordinates accordingly.
         */
        public function adjustVertexData(vertexData:VertexData, vertexID:int, count:int):void
        {
            if (mFrame)
            {
                if (count != 4) 
                    throw new ArgumentError("Textures with a frame can only be used on quads");
                
                var deltaRight:Number  = mFrame.width  + mFrame.x - width;
                var deltaBottom:Number = mFrame.height + mFrame.y - height;
                
                vertexData.translateVertex(vertexID,     -mFrame.x, -mFrame.y);
                vertexData.translateVertex(vertexID + 1, -deltaRight, -mFrame.y);
                vertexData.translateVertex(vertexID + 2, -mFrame.x, -deltaBottom);
                vertexData.translateVertex(vertexID + 3, -deltaRight, -deltaBottom);
            }
        }
        
        /** Converts texture coordinates into the format required for rendering. While the texture
         *  coordinates of an image always use the range <code>[0, 1]</code>, the actual
         *  coordinates could be different: you might be working with a SubTexture. This method
         *  adjusts the coordinates accordingly.
         *
         *  @param texCoords: a vector containing UV coordinates (optionally, among other data).
         *                    U and V coordinates always have to come in pairs. The vector is
         *                    modified in place.
         *  @param startIndex: the index of the first U coordinate in the vector.
         *  @param stride: the distance (in vector elements) of consecutive UV pairs.
         *  @param count: the number of UV pairs that should be adjusted, or "-1" for all of them.
         */
        public function adjustTexCoords(texCoords:Vector.<Number>,
                                        startIndex:int=0, stride:int=0, count:int=-1):void
        {
            // override in subclasses
        }
        
        // properties
        
        /** The texture frame (see class description). */
        public function get frame():Rectangle 
        { 
            return mFrame ? mFrame.clone() : new Rectangle(0, 0, width, height);
            
            // the frame property is readonly - set the frame in the 'fromTexture' method.
            // why is it readonly? To be able to efficiently cache the texture coordinates on
            // rendering, textures need to be immutable (except 'repeat', which is not cached,
            // anyway).
        }
        
        /** Indicates if the texture should repeat like a wallpaper or stretch the outermost pixels.
         *  Note: this only works in textures with sidelengths that are powers of two and 
         *  that are not loaded from a texture atlas (i.e. no subtextures). @default false */
        public function get repeat():Boolean { return mRepeat; }
        public function set repeat(value:Boolean):void { mRepeat = value; }
        
        /** The width of the texture in points. */
        public function get width():Number { return 0; }
        
        /** The height of the texture in points. */
        public function get height():Number { return 0; }

        /** The width of the texture in pixels (without scale adjustment). */
        public function get nativeWidth():Number { return 0; }
        
        /** The height of the texture in pixels (without scale adjustment). */
        public function get nativeHeight():Number { return 0; }
        
        /** The scale factor, which influences width and height properties. */
        public function get scale():Number { return 1.0; }
        
        /** The Stage3D texture object the texture is based on. */
        public function get base():TextureBase { return null; }
        
        /** The concrete (power-of-two) texture the texture is based on. */
        public function get root():ConcreteTexture { return null; }
        
        /** The <code>Context3DTextureFormat</code> of the underlying texture data. */
        public function get format():String { return Context3DTextureFormat.BGRA; }
        
        /** Indicates if the texture contains mip maps. */ 
        public function get mipMapping():Boolean { return false; }
        
        /** Indicates if the alpha values are premultiplied into the RGB values. */
        public function get premultipliedAlpha():Boolean { return false; }
    }
}