package starling.utils
{
    import flash.display3D.Context3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    import starling.core.Starling;
    
    public class VertexData 
    {
        public static const ELEMENTS_PER_VERTEX:int = 8;
        public static const POSITION_OFFSET:int = 0;
        public static const COLOR_OFFSET:int = 3;
        public static const TEXCOORD_OFFSET:int = 6;
        
        private var mData:Vector.<Number>;
        
        public function VertexData(numVertices:int)
        {            
            mData = new Vector.<Number>(numVertices * ELEMENTS_PER_VERTEX, true);
        }        
        
        // functions
        
        public function setPosition(vertexID:int, x:Number, y:Number, z:Number=0.0):void
        {
            setValues(getOffset(vertexID) + POSITION_OFFSET, x, y, z);
        }
        
        public function getPosition(vertexID:int):Vector3D
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            return new Vector3D(mData[offset], mData[offset+1], mData[offset+2]);
        }
        
        public function translateVertex(vertexID:int, 
                                        deltaX:Number, deltaY:Number, deltaZ:Number=0.0):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            mData[offset]   += deltaX;
            mData[offset+1] += deltaY;
            mData[offset+2] += deltaZ;
        }
        
        public function setColor(vertexID:int, color:uint):void
        {
            setValues(getOffset(vertexID) + COLOR_OFFSET, 
                      Color.getRed(color) / 255.0,
                      Color.getGreen(color) / 255.0,
                      Color.getBlue(color) / 255.0);
        }
        
        public function setUniformColor(color:uint):void
        {
            for (var i:int=0; i<numVertices; ++i)
                setColor(i, color);
        }
        
        public function getColor(vertexID:int):uint
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
            return Color.create(mData[offset] * 255, mData[offset+1] * 255, 
                                         mData[offset+2] * 255);
        }
        
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            setValues(getOffset(vertexID) + TEXCOORD_OFFSET, u, v);
        }
        
        public function getTexCoords(vertexID:int):Point
        {
            var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
            return new Point(mData[offset], mData[offset+1]);
        }
        
        public function toVertexBuffer():VertexBuffer3D
        {
            var context:Context3D = Starling.context;
            var buffer:VertexBuffer3D = context.createVertexBuffer(numVertices, ELEMENTS_PER_VERTEX);
            buffer.uploadFromVector(mData, 0, numVertices);
            return buffer;
        }
        
        public function clone():VertexData
        {
            var clone:VertexData = new VertexData(0);
            clone.mData = mData.concat();
            clone.mData.fixed = true;
            return clone;
        }
                
        // helpers
        
        private function setValues(offset:int, ...values):void
        {
            for (var i:int=0; i<values.length; ++i)
                mData[offset+i] = values[i];
        }
        
        private function getOffset(vertexID:int):int
        {
            return vertexID * ELEMENTS_PER_VERTEX;
        }
        
        // properties
        
        public function get numVertices():int { return mData.length / ELEMENTS_PER_VERTEX; }        
        public function get data():Vector.<Number> { return mData; }
    }
}