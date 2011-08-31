// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    public class VertexData 
    {
        public static const ELEMENTS_PER_VERTEX:int = 9;
        public static const POSITION_OFFSET:int = 0;
        public static const COLOR_OFFSET:int = 3;
        public static const TEXCOORD_OFFSET:int = 7;
        
        private var mData:Vector.<Number>;
        private var mPremultipliedAlpha:Boolean;
        
        public function VertexData(numVertices:int, premultipliedAlpha:Boolean=false)
        {            
            mData = new Vector.<Number>(numVertices * ELEMENTS_PER_VERTEX, true);
            mPremultipliedAlpha = premultipliedAlpha;
        }        
        
        public function append(data:VertexData):void
        {
            mData.fixed = false;
            
            for each (var element:Number in data.mData)
                mData.push(element);
                
            mData.fixed = true;
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
        
        public function setColor(vertexID:int, color:uint, alpha:Number=1.0):void
        {
            var multiplier:Number = mPremultipliedAlpha ? alpha : 1.0;
            setValues(getOffset(vertexID) + COLOR_OFFSET, 
                      Color.getRed(color)   / 255.0 * multiplier,
                      Color.getGreen(color) / 255.0 * multiplier,
                      Color.getBlue(color)  / 255.0 * multiplier,
                      alpha);
        }
        
        public function getColor(vertexID:int):uint
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
            var divisor:Number = mPremultipliedAlpha ? mData[offset+3] : 1.0;
            
            if (divisor == 0) return 0;
            else
            {
                var red:Number   = mData[offset  ] / divisor;
                var green:Number = mData[offset+1] / divisor;
                var blue:Number  = mData[offset+2] / divisor;
                return Color.rgb(red * 255, green * 255, blue * 255);
            }
        }
        
        public function setAlpha(vertexID:int, alpha:Number):void
        {
            if (mPremultipliedAlpha) setColor(vertexID, getColor(vertexID), alpha);
            else 
            {
                var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
                mData[offset] = alpha;
            }
        }
        
        public function getAlpha(vertexID:int):Number
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
            return mData[offset];
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
        
        public function clone():VertexData
        {
            var clone:VertexData = new VertexData(0, mPremultipliedAlpha);
            clone.mData = mData.concat();
            clone.mData.fixed = true;
            return clone;
        }
        
        // utility functions
        
        public function translateVertex(vertexID:int, 
                                        deltaX:Number, deltaY:Number, deltaZ:Number=0.0):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            mData[offset]   += deltaX;
            mData[offset+1] += deltaY;
            mData[offset+2] += deltaZ;
        }
        
        public function transformVertex(vertexID:int, matrix:Matrix3D=null):void
        {
            var position:Vector3D = getPosition(vertexID);
            
            if (matrix)
            {
                var transPosition:Vector3D = matrix.transformVector(position);
                setPosition(vertexID, transPosition.x, transPosition.y, transPosition.z);
            }
        }
        
        public function setUniformColor(color:uint, alpha:Number=1.0):void
        {
            for (var i:int=0; i<numVertices; ++i)
                setColor(i, color, alpha);
        }
        
        public function scaleAlpha(vertexID:int, alpha:Number):void
        {
            if (mPremultipliedAlpha) setAlpha(vertexID, getAlpha(vertexID) * alpha);
            else
            {
                var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
                mData[offset] *= alpha;
            }
        }
        
        private function setValues(offset:int, ...values):void
        {
            var numValues:int = values.length;
            for (var i:int=0; i<numValues; ++i)
                mData[offset+i] = values[i];
        }
        
        private function getOffset(vertexID:int):int
        {
            return vertexID * ELEMENTS_PER_VERTEX;
        }
        
        // properties
        
        public function set premultipliedAlpha(value:Boolean):void
        {
            if (value == mPremultipliedAlpha) return;            
            var dataLength:int = mData.length;
            
            for (var i:int=COLOR_OFFSET; i<dataLength; i += ELEMENTS_PER_VERTEX)
            {
                var alpha:Number = mData[i+3];
                var divisor:Number = mPremultipliedAlpha ? alpha : 1.0;
                var multiplier:Number = value ? alpha : 1.0;
                
                if (divisor != 0)
                {
                    mData[i  ] = mData[i  ] / divisor * multiplier;
                    mData[i+1] = mData[i+1] / divisor * multiplier;
                    mData[i+2] = mData[i+2] / divisor * multiplier;
                }
            }
            
            mPremultipliedAlpha = value;
        }
        
        public function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
        
        public function get numVertices():int { return mData.length / ELEMENTS_PER_VERTEX; }
        public function get data():Vector.<Number> { return mData; }
    }
}