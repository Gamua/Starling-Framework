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
    import flash.utils.ByteArray;
    import flash.utils.Endian;

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
        /** Each elements size */
        public static const ELEMENTS_SIZE:int = 4;

        /** The total number of elements (Numbers) stored per vertex. */
        public static const ELEMENTS_PER_VERTEX:int = 8;

        /** The total number of bytes stored per vertex. */
        public static const BYTES_PER_VERTEX:int = ELEMENTS_SIZE*ELEMENTS_PER_VERTEX;
        
        /** The offset of position data (x, y) within a vertex. */
        public static const POSITION_OFFSET:int = 0;
        
        /** The offset of color data (r, g, b, a) within a vertex. */ 
        public static const COLOR_OFFSET:int = 2;
        
        /** The offset of texture coordinates (u, v) within a vertex. */
        public static const TEXCOORD_OFFSET:int = 6;

        /** The byte offset of position data (x, y) within a vertex. */
        public static const POSITION_BYTE_OFFSET:int = POSITION_OFFSET*ELEMENTS_SIZE;

        /** The byte offset of color data (r, g, b, a) within a vertex. */
        public static const COLOR_BYTE_OFFSET:int = COLOR_OFFSET*ELEMENTS_SIZE;

        /** The byte offset of color data (r, g, b, a) within a vertex. */
        public static const ALPHA_BYTE_OFFSET:int = COLOR_BYTE_OFFSET+3*ELEMENTS_SIZE;

        /** The byte offset of texture coordinates (u, v) within a vertex. */
        public static const TEXCOORD_BYTE_OFFSET:int = TEXCOORD_OFFSET*ELEMENTS_SIZE;

        private var mRawData:ByteArray;
        private var mPremultipliedAlpha:Boolean;
        private var mNumVertices:int;

        /** Helper object. */
        private static var sHelperPoint:Point = new Point();
        
        /** Create a new VertexData object with a specified number of vertices. */
        public function VertexData(numVertices:int, premultipliedAlpha:Boolean=false)
        {
            mRawData = new ByteArray();
            mRawData.endian=Endian.LITTLE_ENDIAN;
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
            clone.mRawData.writeBytes(mRawData);

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
            targetData.mRawData.position=uint(targetVertexID * BYTES_PER_VERTEX);
            targetData.mRawData.writeBytes(mRawData,vertexID * BYTES_PER_VERTEX,numVertices * BYTES_PER_VERTEX);

        }
        
        /** Appends the vertices from another VertexData object. */
        public function append(data:VertexData):void
        {
            mRawData.position=mRawData.length;
            mRawData.writeBytes(data.mRawData);
            
            mNumVertices += data.numVertices;
        }
        
        // functions
        
        /** Updates the position values of a vertex. */
        public function setPosition(vertexID:int, x:Number, y:Number):void
        {
            mRawData.position=int(vertexID*BYTES_PER_VERTEX + POSITION_BYTE_OFFSET);
            mRawData.writeFloat(x);
            mRawData.writeFloat(y);
        }
        
        /** Returns the position of a vertex. */
        public function getPosition(vertexID:int, position:Point):void
        {
            mRawData.position=int(vertexID*BYTES_PER_VERTEX + POSITION_BYTE_OFFSET);
            position.x = mRawData.readFloat();
            position.y = mRawData.readFloat();
        }
        
        /** Updates the RGB color values of a vertex. */ 
        public function setColor(vertexID:int, color:uint):void
        {
            var offset:int = vertexID*BYTES_PER_VERTEX + COLOR_BYTE_OFFSET;
            mRawData.position=offset+3*ELEMENTS_SIZE;
            var multiplier:Number = mPremultipliedAlpha ? mRawData.readFloat() : 1.0;
            mRawData.position=offset;
            mRawData.writeFloat(((color >> 16) & 0xff) / 255.0 * multiplier);
            mRawData.writeFloat(((color >>  8) & 0xff) / 255.0 * multiplier);
            mRawData.writeFloat(( color        & 0xff) / 255.0 * multiplier);
        }
        
        /** Returns the RGB color of a vertex (no alpha). */
        public function getColor(vertexID:int):uint
        {
            var offset:int = vertexID*BYTES_PER_VERTEX + COLOR_BYTE_OFFSET;

            mRawData.position=offset+3*ELEMENTS_SIZE;
            var divisor:Number = mPremultipliedAlpha ? mRawData.readFloat() : 1.0;
            
            if (divisor == 0) return 0;
            else
            {
                mRawData.position=offset;
                var red:Number   = mRawData.readFloat() / divisor;
                var green:Number = mRawData.readFloat() / divisor;
                var blue:Number  = mRawData.readFloat() / divisor;
                
                return (int(red*255) << 16) | (int(green*255) << 8) | int(blue*255);
            }
        }

        /** Reset the alpha of the vertex if Premultiplied Alpha */
        /** This is a helper function to compensate the longer time for ByteArray.readFloat */
        public function resetPremultipliedAlpha(vertexID:int, alpha:Number):void
        {
            var offset:int = vertexID*BYTES_PER_VERTEX + COLOR_BYTE_OFFSET;
            var color:uint = 0;

            mRawData.position=int(offset+3*ELEMENTS_SIZE);
            var divisor:Number = mPremultipliedAlpha ? mRawData.readFloat() : 1.0;
            var multiplier:Number = mPremultipliedAlpha ? alpha : 1.0;
            var red:Number;
            var green:Number;
            var blue:Number;

            if (divisor == 0) {}
            else
            {
                mRawData.position=offset;
                red = mRawData.readFloat() / divisor;
                green = mRawData.readFloat() / divisor;
                blue  = mRawData.readFloat() / divisor;
            }

            mRawData.position=offset;
            mRawData.writeFloat(red * multiplier);
            mRawData.writeFloat(green * multiplier);
            mRawData.writeFloat(blue * multiplier);
            mRawData.writeFloat(alpha);

        }
        
        /** Updates the alpha value of a vertex (range 0-1). */
        public function setAlpha(vertexID:int, alpha:Number):void
        {
            if (mPremultipliedAlpha)
            {
                if (alpha < 0.001) alpha = 0.001; // zero alpha would wipe out all color data
                resetPremultipliedAlpha(vertexID,alpha);
            }
            else
            {
                mRawData.position=vertexID*BYTES_PER_VERTEX + ALPHA_BYTE_OFFSET;
                mRawData.writeFloat(alpha);
            }
        }
        
        /** Returns the alpha value of a vertex in the range 0-1. */
        public function getAlpha(vertexID:int):Number
        {
            mRawData.position = vertexID*BYTES_PER_VERTEX + ALPHA_BYTE_OFFSET;
            return mRawData.readFloat();
        }
        
        /** Updates the texture coordinates of a vertex (range 0-1). */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            mRawData.position=vertexID*BYTES_PER_VERTEX + TEXCOORD_BYTE_OFFSET;
            mRawData.writeFloat(u);
            mRawData.writeFloat(v);
        }
        
        /** Returns the texture coordinates of a vertex in the range 0-1. */
        public function getTexCoords(vertexID:int, texCoords:Point):void
        {
            mRawData.position=vertexID*BYTES_PER_VERTEX + TEXCOORD_BYTE_OFFSET;
            texCoords.x = mRawData.readFloat();
            texCoords.y = mRawData.readFloat();
        }
        
        // utility functions
        
        /** Translate the position of a vertex by a certain offset. */
        public function translateVertex(vertexID:int, deltaX:Number, deltaY:Number):void
        {
            var offset:int = vertexID*BYTES_PER_VERTEX + POSITION_BYTE_OFFSET;
            mRawData.position=offset;
            var x:Number=mRawData.readFloat();
            var y:Number=mRawData.readFloat();
            mRawData.position=offset;
            mRawData.writeFloat(x+deltaX);
            mRawData.writeFloat(y+deltaY);
        }

        /** Transforms the position of subsequent vertices by multiplication with a 
         *  transformation matrix. */
        public function transformVertex(vertexID:int, matrix:Matrix, numVertices:int=1):void
        {
            var offset:int = vertexID*BYTES_PER_VERTEX + POSITION_BYTE_OFFSET;
            
            for (var i:int=0; i<numVertices; ++i)
            {
                mRawData.position=offset;
                var x:Number=mRawData.readFloat();
                var y:Number=mRawData.readFloat();
                mRawData.position=offset;
                mRawData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
                mRawData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);

                offset += BYTES_PER_VERTEX;
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
                var offset:int = vertexID*BYTES_PER_VERTEX + ALPHA_BYTE_OFFSET;
                var a:Number = 1.0;
                for (i=0; i<numVertices; ++i){
                    mRawData.position=offset+ i*BYTES_PER_VERTEX;
                    a=mRawData.readFloat();
                    mRawData.position=offset+ i*BYTES_PER_VERTEX;
                    mRawData.writeFloat(a*alpha);
                }
//                    mRawData[int(offset + i*ELEMENTS_PER_VERTEX)] *= alpha;
            }
        }

//        private function getOffset(vertexID:int):int
//        {
//            return vertexID * BYTES_PER_VERTEX;
//        }
        
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
            
            if (numVertices == 0)
            {
                if (transformationMatrix == null)
                    resultRect.setEmpty();
                else
                {
                    MatrixUtil.transformCoords(transformationMatrix, 0, 0, sHelperPoint);
                    resultRect.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
                }
            }
            else
            {
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                var offset:int = getOffset(vertexID) + POSITION_OFFSET;
                var x:Number, y:Number, i:int;
                
                if (transformationMatrix == null)
                {
                    for (i=0; i<numVertices; ++i)
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
                    for (i=0; i<numVertices; ++i)
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
            }
            
            return resultRect;
        }
        
        // properties
        
        /** Indicates if any vertices have a non-white color or are not fully opaque. */
        public function get tinted():Boolean
        {
            var offset:int = COLOR_BYTE_OFFSET;
            
            for (var i:int=0; i<mNumVertices; ++i)
            {
                for (var j:int=0; j<4; ++j)
                {
                    mRawData.position=int(offset+j*ELEMENTS_SIZE);
                    if (mRawData.readFloat() != 1.0) return true;
                }
                offset += BYTES_PER_VERTEX;
            }
            
            return false;
        }
        
        /** Changes the way alpha and color values are stored. Updates all exisiting vertices. */
        public function setPremultipliedAlpha(value:Boolean, updateData:Boolean=true):void
        {
            if (value == mPremultipliedAlpha) return;
            
            if (updateData)
            {
                var dataLength:int = mNumVertices * BYTES_PER_VERTEX;
                
                for (var i:int=COLOR_OFFSET* ELEMENTS_SIZE; i<dataLength; i += BYTES_PER_VERTEX)
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
            var i:int;
            var delta:int = value - mNumVertices;

            mRawData.length=value*BYTES_PER_VERTEX;

            if(delta>0)
            {
                mRawData.position=mNumVertices*BYTES_PER_VERTEX;
                for(i =0; i<delta;++i){
                    mRawData.writeFloat(1.0);
                    mRawData.writeFloat(2.0);
                    mRawData.writeFloat(0.0);
                    mRawData.writeFloat(0.0);
                    mRawData.writeFloat(0.0);
                    mRawData.writeFloat(1.0);
                    mRawData.writeFloat(0.0);
                    mRawData.writeFloat(0.0);
                }
            }
            mRawData.position=0;
            mNumVertices = value;

        }
        
        /** The raw vertex data; not a copy! */
        public function get rawData():ByteArray { return mRawData; }
    }
}
