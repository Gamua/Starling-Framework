package starling.textures
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.Starling;
    import starling.errors.AbstractClassError;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    public class Texture
    {
        private var mFrame:Rectangle;
        private var mRepeat:Boolean;
        
        public function Texture()
        {
            if (getQualifiedClassName(this) == "starling.textures::Texture")
                throw new AbstractClassError();
            
            mRepeat = false;
        }
        
        public function dispose():void
        { }
        
        public static function fromBitmap(data:Bitmap, generateMipMaps:Boolean=true,
                                          optimizeForRenderTexture:Boolean=false):Texture
        {
            return fromBitmapData(data.bitmapData, generateMipMaps, optimizeForRenderTexture);
        }
        
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
                new ConcreteTexture(nativeTexture, legalWidth, legalHeight, generateMipMaps);
            
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
        
        public static function empty(width:int=64, height:int=64, color:uint=0xffffffff,
                                     optimizeForRenderTexture:Boolean=false):Texture
        {
            return fromBitmapData(new BitmapData(width, height, true, color), 
                                  false, optimizeForRenderTexture);
        }
        
        public function adjustVertexData(vertexData:VertexData):VertexData
        {
            var clone:VertexData = vertexData.clone();
            
            if (frame)
            {
                var deltaRight:Number  = mFrame.width  + mFrame.x - width;
                var deltaBottom:Number = mFrame.height + mFrame.y - height;
                
                clone.translateVertex(0, -mFrame.x, -mFrame.y);
                clone.translateVertex(1, -deltaRight, -mFrame.y);
                clone.translateVertex(2, -mFrame.x, -deltaBottom);
                clone.translateVertex(3, -deltaRight, -deltaBottom);
            }
            
            return clone;
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
        
        public function get frame():Rectangle { return mFrame; }
        public function set frame(value:Rectangle):void { mFrame = value ? value.clone() : null; }
        
        public function get repeat():Boolean { return mRepeat; }
        public function set repeat(value:Boolean):void { mRepeat = value; }
        
        public function get width():Number { return 0; }        
        public function get height():Number { return 0; }        
        public function get base():TextureBase { return null; }
        public function get mipMapping():Boolean { return false; }
    }
}