package starling.core
{
    import flash.display3D.Context3D;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix3D;
    
    import starling.display.Image;
    import starling.display.Quad;
    import starling.errors.MissingContextError;
    import starling.textures.Texture;
    import starling.utils.VertexData;

    public class QuadBuffer
    {
        private var mCapacity:int;
        private var mBaseQuad:Quad;
        private var mBaseTexture:Texture;
        
        private var mVertexData:VertexData;
        private var mIndexData:Vector.<uint>;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexBuffer:IndexBuffer3D;

        public function QuadBuffer(capacity:int=128)
        {
            mVertexData = new VertexData(0);
            mIndexData = new <uint>[];
            mCapacity = 0;
            
            resize(capacity);
        }
        
        public function dispose():void
        {
            mVertexBuffer.dispose();
            mIndexBuffer.dispose();
        }
        
        public function resize(capacity:int):void
        {
            if (mCapacity == capacity) return;
            
            mVertexData.numVertices = capacity * 4;
            
            for (var i:int = mCapacity; i < capacity; ++i)
            {
                mIndexData[i*6  ] = i*4;
                mIndexData[i*6+1] = i*4 + 1;
                mIndexData[i*6+2] = i*4 + 2;
                mIndexData[i*6+3] = i*4 + 1;
                mIndexData[i*6+4] = i*4 + 3;
                mIndexData[i*6+5] = i*4 + 2;
            }
            
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            mVertexBuffer = context.createVertexBuffer(capacity * 4, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, capacity * 4);
            
            mIndexBuffer = context.createIndexBuffer(capacity * 6);
            mIndexBuffer.uploadFromVector(mIndexData, 0, capacity * 6);
            
            mCapacity = capacity;
        }
        
        public function renderQuad(quad:Quad, alpha:Number, viewMatrix:Matrix3D):void
        {
            var image:Image = quad as Image;
            var texture:Texture = image ? image.texture : null;
            
            
                
                
            
            
        }
    }
}