// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.display.Bitmap;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.core.Painter;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.VertexData;

    /** An Image is a quad with a texture mapped onto it.
     *  
     *  <p>The Image class is the Starling equivalent of Flash's Bitmap class. Instead of 
     *  BitmapData, Starling uses textures to represent the pixels of an image. To display a 
     *  texture, you have to map it onto a quad - and that's what the Image class is for.</p>
     *  
     *  <p>As "Image" inherits from "Quad", you can give it a color. For each pixel, the resulting  
     *  color will be the result of the multiplication of the color of the texture with the color of 
     *  the quad. That way, you can easily tint textures with a certain color. Furthermore, images 
     *  allow the manipulation of texture coordinates. That way, you can move a texture inside an 
     *  image without changing any vertex coordinates of the quad. You can also use this feature
     *  as a very efficient way to create a rectangular mask.</p> 
     *  
     *  @see starling.textures.Texture
     *  @see Quad
     */ 
    public class Image extends Quad
    {
        private var mTexture:Texture;
        private var mSmoothing:String;
        
        private var mVertexDataCache:VertexData;
        private var mVertexDataCacheInvalid:Boolean;
        
        /** Creates a quad with a texture mapped onto it. */
        public function Image(texture:Texture)
        {
            if (texture)
            {
                var frame:Rectangle = texture.frame;
                var width:Number  = frame ? frame.width  : texture.width;
                var height:Number = frame ? frame.height : texture.height;
                var pma:Boolean = texture.premultipliedAlpha;
                
                super(width, height, 0xffffff, pma);
                
                mVertexData.setPoint(0, "texCoords", 0.0, 0.0);
                mVertexData.setPoint(1, "texCoords", 1.0, 0.0);
                mVertexData.setPoint(2, "texCoords", 0.0, 1.0);
                mVertexData.setPoint(3, "texCoords", 1.0, 1.0);
                
                mTexture = texture;
                mSmoothing = TextureSmoothing.BILINEAR;
                mVertexDataCacheInvalid = true;
                mVertexDataCache = new VertexData(mVertexData.format, 4);
                mVertexDataCache.premultipliedAlpha = pma;
            }
            else
            {
                throw new ArgumentError("Texture cannot be null");
            }
        }
        
        /** Creates an Image with a texture that is created from a bitmap object. */
        public static function fromBitmap(bitmap:Bitmap, generateMipMaps:Boolean=true, 
                                          scale:Number=1):Image
        {
            return new Image(Texture.fromBitmap(bitmap, generateMipMaps, false, scale));
        }
        
        /** @inheritDoc */
        protected override function onVertexDataChanged():void
        {
            mVertexDataCacheInvalid = true;
        }
        
        /** Readjusts the dimensions of the image according to its current texture. Call this method 
         *  to synchronize image and texture size after assigning a texture with a different size.*/
        public function readjustSize():void
        {
            var frame:Rectangle = texture.frame;
            var width:Number  = frame ? frame.width  : texture.width;
            var height:Number = frame ? frame.height : texture.height;
            
            mVertexData.setPoint(0, "position", 0.0, 0.0);
            mVertexData.setPoint(1, "position", width, 0.0);
            mVertexData.setPoint(2, "position", 0.0, height);
            mVertexData.setPoint(3, "position", width, height);
            
            onVertexDataChanged();
        }
        
        /** Sets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
        public function setTexCoords(vertexID:int, coords:Point):void
        {
            mVertexData.setPoint(vertexID, "texCoords", coords.x, coords.y);
            onVertexDataChanged();
        }
        
        /** Sets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
        public function setTexCoordsTo(vertexID:int, u:Number, v:Number):void
        {
            mVertexData.setPoint(vertexID, "texCoords", u, v);
            onVertexDataChanged();
        }
        
        /** Gets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. 
         *  If you pass an 'out' Point, the result will be stored in this point instead of
         *  creating a new object.*/
        public function getTexCoords(vertexID:int, out:Point=null):Point
        {
            if (out == null) out = new Point();
            mVertexData.getPoint(vertexID, "texCoords", out);
            return out;
        }
        
        /** Copies the raw vertex data to a VertexData instance.
         *  The texture coordinates are already in the format required for rendering. */ 
        public override function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            copyVertexDataTransformedTo(targetData, targetVertexID, null);
        }
        
        /** Transforms the vertex positions of the raw vertex data by a certain matrix
         *  and copies the result to another VertexData instance.
         *  The texture coordinates are already in the format required for rendering. */
        public override function copyVertexDataTransformedTo(targetData:VertexData,
                                                             targetVertexID:int=0,
                                                             matrix:Matrix=null):void
        {
            if (mVertexDataCacheInvalid)
            {
                mVertexDataCacheInvalid = false;
                mVertexData.copyTo(mVertexDataCache);
                mTexture.adjustVertexData(mVertexDataCache, 0, 4);
            }
            
            mVertexDataCache.copyToTransformed(targetData, targetVertexID, matrix);
        }
        
        /** The texture that is displayed on the quad. */
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void 
        { 
            if (value == null)
            {
                throw new ArgumentError("Texture cannot be null");
            }
            else if (value != mTexture)
            {
                mTexture = value;
                mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha, true);
                mVertexDataCache.setPremultipliedAlpha(mTexture.premultipliedAlpha, true);
                onVertexDataChanged();
            }
        }
        
        /** The smoothing filter that is used for the texture. 
        *   @default bilinear
        *   @see starling.textures.TextureSmoothing */ 
        public function get smoothing():String { return mSmoothing; }
        public function set smoothing(value:String):void 
        {
            if (TextureSmoothing.isValid(value))
                mSmoothing = value;
            else
                throw new ArgumentError("Invalid smoothing mode: " + value);
        }
        
        /** @inheritDoc */
        public override function render(painter:Painter):void
        {
            painter.batchQuad(this, mTexture, mSmoothing);
        }
    }
}