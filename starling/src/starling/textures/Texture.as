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
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.Starling;
    import starling.errors.AbstractClassError;
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
     *  var image:Image = new Image(texture);
     *  </listing>
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
     *  @see starling.display.Image
     *  @see TextureAtlas
     */ 
    public class Texture
    {
        private var mFrame:Rectangle;
        private var mRepeat:Boolean;
        
        /** @private */
        public function Texture()
        {
            if (getQualifiedClassName(this) == "starling.textures::Texture")
                throw new AbstractClassError();
            
            mRepeat = false;
        }
        
        /** Disposes the underlying texture data. */
        public function dispose():void
        { }
        
        /** Creates a texture object from a bitmap.*/
        public static function fromBitmap(data:Bitmap, generateMipMaps:Boolean=true,
                                          optimizeForRenderTexture:Boolean=false):Texture
        {
            return fromBitmapData(data.bitmapData, generateMipMaps, optimizeForRenderTexture);
        }
        
        /** Creates a texture from bitmap data. */
        public static function fromBitmapData(data:BitmapData, generateMipMaps:Boolean=true,
                                              optimizeForRenderTexture:Boolean=false):Texture
        {
            var origWidth:int = data.width;
            var origHeight:int = data.height;
            var legalWidth:int  = getNextPowerOfTwo(data.width);
            var legalHeight:int = getNextPowerOfTwo(data.height);
            var format:String = Context3DTextureFormat.BGRA;
            
            var nativeTexture:flash.display3D.textures.Texture = Starling.context.createTexture(
                legalWidth, legalHeight, format, optimizeForRenderTexture);
            
            if (legalWidth > origWidth || legalHeight > origHeight)
            {
                var potData:BitmapData = new BitmapData(legalWidth, legalHeight, true, 0);
                potData.copyPixels(data, data.rect, new Point(0, 0));
                uploadTexture(potData, nativeTexture, generateMipMaps);
                potData.dispose();
            }
            else
            {
                uploadTexture(data, nativeTexture, generateMipMaps);
            }
            
            var concreteTexture:Texture = 
                new ConcreteTexture(nativeTexture, legalWidth, legalHeight, generateMipMaps, true);
            
            return fromTexture(concreteTexture, new Rectangle(0, 0, origWidth, origHeight));
        }
        
        /** Creates a texture from the compressed ATF format. */ 
        public static function fromAtfData(data:ByteArray):Texture
        {
            var signature:String = String.fromCharCode(data[0], data[1], data[2]);
            if (signature != "ATF") throw new ArgumentError("Invalid ATF data");
            
            var format:String = data[6] == 2 ? Context3DTextureFormat.COMPRESSED :
                                               Context3DTextureFormat.BGRA;
            var width:int = Math.pow(2, data[7]); 
            var height:int = Math.pow(2, data[8]);
            var textureCount:int = data[9];
            
            var nativeTexture:flash.display3D.textures.Texture = 
                Starling.context.createTexture(width, height, format, false);
            
            nativeTexture.uploadCompressedTextureFromByteArray(data, 0);
            
            return new ConcreteTexture(nativeTexture, width, height, textureCount > 1, false);
        }
        
        /** Creates a texture that contains a region (in pixels) of another texture. The new
         *  texture will reference the base texture; no data is duplicated. */
        public static function fromTexture(texture:Texture, region:Rectangle=null, frame:Rectangle=null):Texture
        {
            var subTexture:Texture = new SubTexture(texture, region);   
            subTexture.mFrame = frame;
            return subTexture;
        }
        
        /** Creates an empty texture of a certain size and color. The color parameter
         *  expects data in ARGB format. */
        public static function empty(width:int=64, height:int=64, color:uint=0xffffffff,
                                     optimizeForRenderTexture:Boolean=false):Texture
        {
            var bitmapData:BitmapData = new BitmapData(width, height, true, color);
            var texture:Texture = fromBitmapData(bitmapData, false, optimizeForRenderTexture);
            bitmapData.dispose();
            return texture;
        }
        
        /** Converts texture coordinates and vertex positions of raw vertex data into the format 
         *  required for rendering. */
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
        
        private static function uploadTexture(data:BitmapData,
                                              texture:flash.display3D.textures.Texture,
                                              generateMipmaps:Boolean):void
        {
            texture.uploadFromBitmapData(data);
            
            if (generateMipmaps)
            {
                var currentWidth:int  = data.width  >> 1;
                var currentHeight:int = data.height >> 1;
                var level:int = 1;
                var canvas:BitmapData = new BitmapData(currentWidth, currentHeight, true, 0);
                var transform:Matrix = new Matrix(.5, 0, 0, .5);
                
                while (currentWidth >= 1 || currentHeight >= 1)
                {
                    canvas.fillRect(new Rectangle(0, 0, currentWidth, currentHeight), 0);
                    canvas.draw(data, transform, null, null, null, true);
                    texture.uploadFromBitmapData(canvas, level++);
                    transform.scale(0.5, 0.5);
                    currentWidth  = currentWidth  >> 1;
                    currentHeight = currentHeight >> 1;
                }
                
                canvas.dispose();
            }
        }
        
        /** The texture frame (see class description). @default null */
        public function get frame():Rectangle 
        { 
            return mFrame ? mFrame.clone() : new Rectangle(0, 0, width, height);
            
            // the frame property is readonly - set the frame in the 'fromTexture' method.
            // why is it readonly? To be able to efficiently cache the texture coordinates on
            // rendering, textures need to be immutable (except 'repeat', which is not cached,
            // anyway).
        }
        
        /** Indicates if the texture should repeat like a wallpaper or stretch the outermost pixels.
         *  Note: this makes sense only in textures with sidelengths that are powers of two and 
         *  that are not loaded from a texture atlas (i.e. no subtextures). @default false */
        public function get repeat():Boolean { return mRepeat; }
        public function set repeat(value:Boolean):void { mRepeat = value; }
        
        /** The width of the texture in pixels. */
        public function get width():Number { return 0; }
        
        /** The height of the texture in pixels. */
        public function get height():Number { return 0; }
        
        /** The Stage3D texture object the texture is based on. */
        public function get base():TextureBase { return null; }
        
        /** Indicates if the texture contains mip maps. */ 
        public function get mipMapping():Boolean { return false; }
        
        /** Indicates if the alpha values are premultiplied into the RGB values. */
        public function get premultipliedAlpha():Boolean { return false; }
    }
}