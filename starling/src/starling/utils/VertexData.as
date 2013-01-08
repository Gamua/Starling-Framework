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
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    /** The VertexData class manages a raw list of vertex information, allowing direct upload
     *  to Stage3D vertex buffers. <em>You only have to work with this class if you create display 
     *  objects with a custom render function. If you don't plan to do that, you can safely 
     *  ignore it.</em>
     * 
     *  <p>To render objects with Stage3D, you have to organize vertex data in so-called
     *  vertex buffers. Those buffers reside in graphics memory and can be accessed very 
     *  efficiently by the GPU. Before you can move data into vertex buffers, you have to 
     *  set it up in conventional memory - that is, in a Vector object. The vector contains
     *  all vertex information (the coordinates, color, and texture coordinates) - one
     *  vertex after the other.</p>
     *  
     *  <p>To simplify creating and working with such a bulky list, the VertexData class was 
     *  created. It contains methods to specify and modify vertex data. The raw Vector managed 
     *  by the class can then easily be uploaded to a vertex buffer.</p>
     * 
     *  <strong>Premultiplied Alpha</strong>
     *  
     *  <p>The color values of the "BitmapData" object contain premultiplied alpha values, which 
     *  means that the <code>rgb</code> values were multiplied with the <code>alpha</code> value 
     *  before saving them. Since textures are created from bitmap data, they contain the values in 
     *  the same style. On rendering, it makes a difference in which way the alpha value is saved; 
     *  for that reason, the VertexData class mimics this behavior. You can choose how the alpha 
     *  values should be handled via the <code>premultipliedAlpha</code> property.</p>
     * 
     */ 
    public class VertexData 
    {
        /** The total number of elements (Numbers) stored per vertex. */
        public static const ELEMENTS_PER_VERTEX:int = 8;
        
        /** The offset of position data (x, y) within a vertex. */
        public static const POSITION_OFFSET:int = 0;
        
        /** The offset of color data (r, g, b, a) within a vertex. */ 
        public static const COLOR_OFFSET:int = 2;
        
        /** The offset of texture coordinate (u, v) within a vertex. */
        public static const TEXCOORD_OFFSET:int = 6;
        
        private var mRawData:Vector.<Number>;
        private var mPremultipliedAlpha:Boolean;
        private var mNumVertices:int;

        /** Helper object. */
        private static var sHelperPoint:Point = new Point();
        
        /** Create a new VertexData object with a specified number of vertices. */
        public function VertexData(numVertices:int, premultipliedAlpha:Boolean=false)
        {
            mRawData = new <Number>[];
            mPremultipliedAlpha = premultipliedAlpha;
            this.numVertices = numVertices;
        }

        /** Creates a duplicate of either the complete vertex data object, or of a subset. 
         *  To clone all vertices, set 'numVertices' to '-1'. */
        public function clone(vertexID:int=0, numVertices:int=-1):VertexData
        {
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            var clone:VertexData = new VertexData(0, mPremultipliedAlpha);
            clone.mNumVertices = numVertices; 
            clone.mRawData = mRawData.slice(vertexID * ELEMENTS_PER_VERTEX, 
                                            numVertices * ELEMENTS_PER_VERTEX); 
            clone.mRawData.fixed = true;
            return clone;
        }
        
        /** Copies the vertex data (or a range of it, defined by 'vertexID' and 'numVertices') 
         *  of this instance to another vertex data object, starting at a certain index. */
        public function copyTo(targetData:VertexData, targetVertexID:int=0,
                               vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            // todo: check/convert pma
            
            var targetRawData:Vector.<Number> = targetData.mRawData;
            var targetIndex:int = targetVertexID * ELEMENTS_PER_VERTEX;
            var sourceIndex:int = vertexID * ELEMENTS_PER_VERTEX;
            var dataLength:int = numVertices * ELEMENTS_PER_VERTEX;
            
            for (var i:int=sourceIndex; i<dataLength; ++i)
                targetRawData[int(targetIndex++)] = mRawData[i];
        }
        
        /** Appends the vertices from another VertexData object. */
        public function append(data:VertexData):void
        {
            mRawData.fixed = false;
            
            var targetIndex:int = mRawData.length;
            var rawData:Vector.<Number> = data.mRawData;
            var rawDataLength:int = rawData.length;
            
            for (var i:int=0; i<rawDataLength; ++i)
                mRawData[int(targetIndex++)] = rawData[i];
            
            mNumVertices += data.numVertices;
            mRawData.fixed = true;
        }
        
        // functions
        
        /** Updates the position values of a vertex. */
        public function setPosition(vertexID:int, x:Number, y:Number):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            mRawData[offset] = x;
            mRawData[int(offset+1)] = y;
        }
        
        /** Returns the position of a vertex. */
        public function getPosition(vertexID:int, position:Point):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            position.x = mRawData[offset];
            position.y = mRawData[int(offset+1)];
        }
        
        /** Updates the RGB color values of a vertex. */ 
        public function setColor(vertexID:int, color:uint):void
        {   
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
            var multiplier:Number = mPremultipliedAlpha ? mRawData[int(offset+3)] : 1.0;
            mRawData[offset]        = ((color >> 16) & 0xff) / 255.0 * multiplier;
            mRawData[int(offset+1)] = ((color >>  8) & 0xff) / 255.0 * multiplier;
            mRawData[int(offset+2)] = ( color        & 0xff) / 255.0 * multiplier;
        }
        
        /** Returns the RGB color of a vertex (no alpha). */
        public function getColor(vertexID:int):uint
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
            var divisor:Number = mPremultipliedAlpha ? mRawData[int(offset+3)] : 1.0;
            
            if (divisor == 0) return 0;
            else
            {
                var red:Number   = mRawData[offset]        / divisor;
                var green:Number = mRawData[int(offset+1)] / divisor;
                var blue:Number  = mRawData[int(offset+2)] / divisor;
                
                return (int(red*255) << 16) | (int(green*255) << 8) | int(blue*255);
            }
        }
        
        /** Updates the alpha value of a vertex (range 0-1). */
        public function setAlpha(vertexID:int, alpha:Number):void
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
            
            if (mPremultipliedAlpha)
            {
                if (alpha < 0.001) alpha = 0.001; // zero alpha would wipe out all color data
                var color:uint = getColor(vertexID);
                mRawData[offset] = alpha;
                setColor(vertexID, color);
            }
            else
            {
                mRawData[offset] = alpha;
            }
        }
        
        /** Returns the alpha value of a vertex in the range 0-1. */
        public function getAlpha(vertexID:int):Number
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
            return mRawData[offset];
        }
        
        /** Updates the texture coordinates of a vertex (range 0-1). */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
            mRawData[offset]        = u;
            mRawData[int(offset+1)] = v;
        }
        
        /** Returns the texture coordinates of a vertex in the range 0-1. */
        public function getTexCoords(vertexID:int, texCoords:Point):void
        {
            var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
            texCoords.x = mRawData[offset];
            texCoords.y = mRawData[int(offset+1)];
        }
        
        // utility functions
        
        /** Translate the position of a vertex by a certain offset. */
        public function translateVertex(vertexID:int, deltaX:Number, deltaY:Number):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            mRawData[offset]        += deltaX;
            mRawData[int(offset+1)] += deltaY;
        }

        /** Transforms the position of subsequent vertices by multiplication with a 
         *  transformation matrix. */
        public function transformVertex(vertexID:int, matrix:Matrix, numVertices:int=1):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            
            for (var i:int=0; i<numVertices; ++i)
            {
                var x:Number = mRawData[offset];
                var y:Number = mRawData[int(offset+1)];
                
                mRawData[offset]        = matrix.a * x + matrix.c * y + matrix.tx;
                mRawData[int(offset+1)] = matrix.d * y + matrix.b * x + matrix.ty;
                
                offset += ELEMENTS_PER_VERTEX;
            }
        }
        
        /** Sets all vertices of the object to the same color values. */
        public function setUniformColor(color:uint):void
        {
            for (var i:int=0; i<mNumVertices; ++i)
                setColor(i, color);
        }
        
        /** Sets all vertices of the object to the same alpha values. */
        public function setUniformAlpha(alpha:Number):void
        {
            for (var i:int=0; i<mNumVertices; ++i)
                setAlpha(i, alpha);
        }
        
        /** Multiplies the alpha value of subsequent vertices with a certain delta. */
        public function scaleAlpha(vertexID:int, alpha:Number, numVertices:int=1):void
        {
            if (alpha == 1.0) return;
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
             
            var i:int;
            
            if (mPremultipliedAlpha)
            {
                for (i=0; i<numVertices; ++i)
                    setAlpha(vertexID+i, getAlpha(vertexID+i) * alpha);
            }
            else
            {
                var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
                for (i=0; i<numVertices; ++i)
                    mRawData[int(offset + i*ELEMENTS_PER_VERTEX)] *= alpha;
            }
        }
        
        private function getOffset(vertexID:int):int
        {
            return vertexID * ELEMENTS_PER_VERTEX;
        }
        
        /** Calculates the bounds of the vertices, which are optionally transformed by a matrix. 
         *  If you pass a 'resultRect', the result will be stored in this rectangle 
         *  instead of creating a new object. To use all vertices for the calculation, set
         *  'numVertices' to '-1'. */
        public function getBounds(transformationMatrix:Matrix=null, 
                                  vertexID:int=0, numVertices:int=-1,
                                  resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
            var x:Number, y:Number, i:int;
            
            if (transformationMatrix == null)
            {
                for (i=vertexID; i<numVertices; ++i)
                {
                    x = mRawData[offset];
                    y = mRawData[int(offset+1)];
                    offset += ELEMENTS_PER_VERTEX;
                    
                    minX = minX < x ? minX : x;
                    maxX = maxX > x ? maxX : x;
                    minY = minY < y ? minY : y;
                    maxY = maxY > y ? maxY : y;
                }
            }
            else
            {
                for (i=vertexID; i<numVertices; ++i)
                {
                    x = mRawData[offset];
                    y = mRawData[int(offset+1)];
                    offset += ELEMENTS_PER_VERTEX;
                    
                    MatrixUtil.transformCoords(transformationMatrix, x, y, sHelperPoint);
                    minX = minX < sHelperPoint.x ? minX : sHelperPoint.x;
                    maxX = maxX > sHelperPoint.x ? maxX : sHelperPoint.x;
                    minY = minY < sHelperPoint.y ? minY : sHelperPoint.y;
                    maxY = maxY > sHelperPoint.y ? maxY : sHelperPoint.y;
                }
            }
            
            resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
            return resultRect;
        }
        
        // properties
        
        /** Indicates if any vertices have a non-white color or are not fully opaque. */
        public function get tinted():Boolean
        {
            var offset:int = COLOR_OFFSET;
            
            for (var i:int=0; i<mNumVertices; ++i)
            {
                for (var j:int=0; j<4; ++j)
                    if (mRawData[int(offset+j)] != 1.0) return true;

                offset += ELEMENTS_PER_VERTEX;
            }
            
            return false;
        }
        
        /** Changes the way alpha and color values are stored. Updates all exisiting vertices. */
        public function setPremultipliedAlpha(value:Boolean, updateData:Boolean=true):void
        {
            if (value == mPremultipliedAlpha) return;
            
            if (updateData)
            {
                var dataLength:int = mNumVertices * ELEMENTS_PER_VERTEX;
                
                for (var i:int=COLOR_OFFSET; i<dataLength; i += ELEMENTS_PER_VERTEX)
                {
                    var alpha:Number = mRawData[int(i+3)];
                    var divisor:Number = mPremultipliedAlpha ? alpha : 1.0;
                    var multiplier:Number = value ? alpha : 1.0;
                    
                    if (divisor != 0)
                    {
                        mRawData[i]        = mRawData[i]        / divisor * multiplier;
                        mRawData[int(i+1)] = mRawData[int(i+1)] / divisor * multiplier;
                        mRawData[int(i+2)] = mRawData[int(i+2)] / divisor * multiplier;
                    }
                }
            }
            
            mPremultipliedAlpha = value;
        }
        
        /** Indicates if the rgb values are stored premultiplied with the alpha value. */
        public function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
        
        /** The total number of vertices. */
        public function get numVertices():int { return mNumVertices; }
        public function set numVertices(value:int):void
        {
            mRawData.fixed = false;
            
            var i:int;
            var delta:int = value - mNumVertices;
            
            for (i=0; i<delta; ++i)
                mRawData.push(0, 0,  0, 0, 0, 1,  0, 0); // alpha should be '1' per default
            
            for (i=0; i<-(delta*ELEMENTS_PER_VERTEX); ++i)
                mRawData.pop();
            
            mNumVertices = value;
            mRawData.fixed = true;
        }
        
        /** The raw vertex data; not a copy! */
        public function get rawData():Vector.<Number> { return mRawData; }
    }
}