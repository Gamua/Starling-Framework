// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.display.Bitmap;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
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
                
                mTexture = texture;
                mSmoothing = TextureSmoothing.BILINEAR;
                mVertexDataCache = new VertexData(4, pma);
                
                updateVertexDataCache();
            }
            else
            {
                throw new ArgumentError("Texture cannot be null");                
            }
        }
        
        /** Creates an Image with a texture that is created from a bitmap object. */
        public static function fromBitmap(bitmap:Bitmap):Image
        {
            return new Image(Texture.fromBitmap(bitmap));
        }
        
        /** @inheritDoc */
        protected override function updateVertexData(width:Number, height:Number, color:uint,
                                                     premultipliedAlpha:Boolean):void
        {
            super.updateVertexData(width, height, color, premultipliedAlpha);
            
            mVertexData.setTexCoords(0, 0.0, 0.0);
            mVertexData.setTexCoords(1, 1.0, 0.0);
            mVertexData.setTexCoords(2, 0.0, 1.0);
            mVertexData.setTexCoords(3, 1.0, 1.0);
        }
        
        private function updateVertexDataCache():void
        {
            mVertexData.copyTo(mVertexDataCache);
            mTexture.adjustVertexData(mVertexDataCache, 0, 4);
        }
        
        /** Readjusts the dimensions of the image according to its current texture. Call this method 
         *  to synchronize image and texture size after assigning a texture with a different size.*/
        public function readjustSize():void
        {
            var frame:Rectangle = texture.frame;
            var width:Number  = frame ? frame.width  : texture.width;
            var height:Number = frame ? frame.height : texture.height;
            
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height); 
            
            updateVertexDataCache();
        }
        
        /** Sets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
        public function setTexCoords(vertexID:int, coords:Point):void
        {
            mVertexData.setTexCoords(vertexID, coords.x, coords.y);
            updateVertexDataCache();
        }
        
        /** Gets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
        public function getTexCoords(vertexID:int):Point
        {
            var coords:Point = new Point();
            mVertexData.getTexCoords(vertexID, coords);
            return coords;
        }
        
        /** Copies the raw vertex data to a VertexData instance.
         *  The texture coordinates are already in the format required for rendering. */ 
        public override function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            mVertexDataCache.copyTo(targetData, targetVertexID);
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
                mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
                updateVertexDataCache();
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
                throw new ArgumentError("Invalid smoothing mode: " + smoothing);
        }
        
        /** @inheritDoc */
        public override function setVertexColor(vertexID:int, color:uint):void
        {
            super.setVertexColor(vertexID, color);
            updateVertexDataCache();
        }
        
        /** @inheritDoc */
        public override function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            super.setVertexAlpha(vertexID, alpha);
            updateVertexDataCache();
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, alpha:Number):void
        {
            support.batchQuad(this, alpha, mTexture, mSmoothing);
        }
    }
}