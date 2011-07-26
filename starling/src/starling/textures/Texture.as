package starling.textures
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.Starling;
    import starling.errors.AbstractClassError;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    public class Texture
    {
        // TODO: create mip maps
        
        public function Texture()
        {
            if (getQualifiedClassName(this) == "starling.textures::Texture")
                throw new AbstractClassError();
        }        
        
        public static function fromBitmap(data:Bitmap, generateMipMaps:Boolean=true):Texture
        {
            return fromBitmapData(data.bitmapData, generateMipMaps);
        }
        
        public static function fromBitmapData(data:BitmapData, generateMipMaps:Boolean=true):Texture
        {
            var origWidth:int = data.width;
            var origHeight:int = data.height;
            var legalWidth:int  = getNextPowerOfTwo(data.width);
            var legalHeight:int = getNextPowerOfTwo(data.height);
            var format:String = Context3DTextureFormat.BGRA;
            
            var nativeTexture:flash.display3D.textures.Texture = 
                Starling.context.createTexture(legalWidth, legalHeight, format, false);
            
            if (legalWidth > origWidth || legalHeight > origHeight)
            {
                var potData:BitmapData = new BitmapData(legalWidth, legalHeight, true, 0);
                potData.copyPixels(data, data.rect, new Point(0, 0));
                nativeTexture.uploadFromBitmapData(potData);
                potData.dispose();
            }
            else
            {
                nativeTexture.uploadFromBitmapData(data);
            }
            
            var concreteTexture:Texture = new ConcreteTexture(nativeTexture, legalWidth, legalHeight);
            return fromTexture(concreteTexture, new Rectangle(0, 0, origWidth, origHeight));
        }
        
        public static function fromTexture(texture:Texture, region:Rectangle):Texture
        {
            if (region.x == 0 && region.y == 0 && 
                region.width == texture.width && region.height == texture.height)
            {
                return texture;
            }
            else
            {
                return new SubTexture(texture, region);   
            }            
        }
        
        public static function empty(width:int=64, height:int=64, color:uint=0xffffffff):Texture
        {
            return fromBitmapData(new BitmapData(width, height, true, color));
        }
        
        public function adjustVertexData(vertexData:VertexData):VertexData
        {
            return vertexData.clone();
        }
        
        public function dispose():void
        { }
        
        public function get width():Number { return 0; }        
        public function get height():Number { return 0; }        
        public function get nativeTexture():TextureBase { return null; }
    }
}