package starling.textures
{
    import flash.display3D.textures.TextureBase;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.utils.VertexData;

    public class SubTexture extends Texture
    {
        private var mBaseTexture:Texture;
        private var mClipping:Rectangle;
        private var mRootClipping:Rectangle;
        
        public function SubTexture(baseTexture:Texture, region:Rectangle)
        {
            mBaseTexture = baseTexture;
            this.clipping = new Rectangle(region.x / baseTexture.width,
                                          region.y / baseTexture.height,
                                          region.width / baseTexture.width,
                                          region.height / baseTexture.height);
        }
        
        public override function adjustVertexData(vertexData:VertexData):VertexData
        {
            var newData:VertexData = vertexData.clone();
            
            var clipX:Number = mRootClipping.x;
            var clipY:Number = mRootClipping.y;
            var clipWidth:Number  = mRootClipping.width;
            var clipHeight:Number = mRootClipping.height;
            
            for (var i:int=0; i<vertexData.numVertices; ++i)
            {
                var texCoords:Point = vertexData.getTexCoords(i);
                newData.setTexCoords(i, clipX + texCoords.x * clipWidth,
                                        clipY + texCoords.y * clipHeight);
            }
            
            return newData;
        }
        
        public function get baseTexture():Texture { return mBaseTexture; }
        
        public function get clipping():Rectangle { return mClipping.clone(); }
        public function set clipping(value:Rectangle):void
        {
            mClipping = value.clone();
            mRootClipping = value.clone();
            
            var baseTexture:SubTexture = mBaseTexture as SubTexture;            
            while (baseTexture)
            {
                var baseClipping:Rectangle = baseTexture.mClipping;
                mRootClipping.x = baseClipping.x + mRootClipping.x * baseClipping.width;
                mRootClipping.y = baseClipping.y + mRootClipping.y * baseClipping.height;
                mRootClipping.width  *= baseClipping.width;
                mRootClipping.height *= baseClipping.height;
                baseTexture = baseTexture.mBaseTexture as SubTexture;
            }            
        }
        
        public override function get width():Number { return mBaseTexture.width * mClipping.width; }
        public override function get height():Number { return mBaseTexture.height * mClipping.height; }
        public override function get nativeTexture():TextureBase { return mBaseTexture.nativeTexture; }
    }
}