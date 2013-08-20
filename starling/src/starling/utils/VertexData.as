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
        /** The number of bytes per element. Positions and texture coordinates take up one
         *  element per component; color data is stored in a single element. */
        public static const BYTES_PER_ELEMENT:int = 4;
        
        /** The total number of elements stored per vertex (in units of 32 bits).  */
        public static const ELEMENTS_PER_VERTEX:int = 5;
        
        /** The offset of position data (x, y) within a vertex (in units of 32 bits). */
        public static const POSITION_OFFSET:int = 0;
        
        /** The offset of color data (one RGBA uint) within a vertex (in units of 32 bits). */
        public static const COLOR_OFFSET:int = 2;
        
        /** The offset of texture coordinates (u, v) within a vertex (in units of 32 bits). */
        public static const TEXCOORD_OFFSET:int = 3;
        
        private static const BYTES_PER_VERTEX:int         = ELEMENTS_PER_VERTEX * BYTES_PER_ELEMENT;
        private static const POSITION_OFFSET_IN_BYTES:int = POSITION_OFFSET     * BYTES_PER_ELEMENT;
        private static const COLOR_OFFSET_IN_BYTES:int    = COLOR_OFFSET        * BYTES_PER_ELEMENT;
        private static const TEXCOORD_OFFSET_IN_BYTES:int = TEXCOORD_OFFSET     * BYTES_PER_ELEMENT;
        
        private var mRawData:ByteArray;
        private var mPremultipliedAlpha:Boolean;
        private var mNumVertices:int;
        private var mMinAlpha:Number;

        /** Helper object. */
        private static var sHelperPoint:Point = new Point();
        
        /** Create a new VertexData object with a specified number of vertices. */
        public function VertexData(numVertices:int, premultipliedAlpha:Boolean=false)
        {
            mRawData = new ByteArray();
            mRawData.endian = Endian.LITTLE_ENDIAN;
            this.premultipliedAlpha = premultipliedAlpha;
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
            clone.mRawData.writeBytes(mRawData, vertexID * BYTES_PER_VERTEX, 
                                             numVertices * BYTES_PER_VERTEX);
            return clone;
        }
        
        /** Copies the vertex data (or a range of it, defined by 'vertexID' and 'numVertices') 
         *  of this instance to another vertex data object, starting at a certain index. */
        public function copyTo(targetData:VertexData, targetVertexID:int=0,
                               vertexID:int=0, numVertices:int=-1):void
        {
            copyTransformedTo(targetData, targetVertexID, null, vertexID, numVertices);
        }

        /** Transforms the vertex position of this instance by a certain matrix and copies the
         *  result to another VertexData instance. Limit the operation to a range of vertices
         *  via the 'vertexID' and 'numVertices' parameters. */
        public function copyTransformedTo(targetData:VertexData, targetVertexID:int=0,
                                          matrix:Matrix=null,
                                          vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            if (targetData.mNumVertices < targetVertexID + numVertices)
                targetData.mNumVertices = targetVertexID + numVertices;
            
            // It's fastest to copy the complete range in one call
            // and then overwrite only the transformed positions.

            var x:Number, y:Number;
            var targetRawData:ByteArray = targetData.mRawData;
            targetRawData.position = targetVertexID * BYTES_PER_VERTEX;
            targetRawData.writeBytes(mRawData, vertexID * BYTES_PER_VERTEX,
                                            numVertices * BYTES_PER_VERTEX);
            
            if (matrix)
            {
                var sourcePos:int = vertexID * BYTES_PER_VERTEX;
                var targetPos:int = targetVertexID * BYTES_PER_VERTEX;
                
                for (var i:int=0; i<numVertices; ++i)
                {
                    // write transformed position
                    
                    mRawData.position = sourcePos;
                    targetRawData.position = targetPos;
                    
                    x = mRawData.readFloat();
                    y = mRawData.readFloat();
                    
                    targetRawData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
                    targetRawData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);
                    
                    sourcePos += 20;
                    targetPos += 20;
                }
            }
        }
        
        /** Appends the vertices from another VertexData object. */
        public function append(data:VertexData):void
        {
            mRawData.position = mNumVertices * BYTES_PER_VERTEX;;
            mRawData.writeBytes(data.mRawData);
            mNumVertices += data.mNumVertices;
        }
        
        // functions
        
        /** Updates the position values of a vertex. */
        public function setPosition(vertexID:int, x:Number, y:Number):void
        {
            mRawData.position = vertexID * BYTES_PER_VERTEX + POSITION_OFFSET_IN_BYTES;
            mRawData.writeFloat(x);
            mRawData.writeFloat(y);
        }
        
        /** Returns the position of a vertex. */
        public function getPosition(vertexID:int, position:Point):void
        {
            mRawData.position = vertexID * BYTES_PER_VERTEX + POSITION_OFFSET_IN_BYTES;
            position.x = mRawData.readFloat();
            position.y = mRawData.readFloat();
        }
        
        /** Updates the RGB color and alpha value of a vertex in one step. */
        public function setColorAndAlpha(vertexID:int, color:uint, alpha:Number):void
        {
            if (alpha < mMinAlpha) alpha = mMinAlpha;
            if (alpha > 1.0)       alpha = 1.0;
            
            var rgba:uint = ((color << 8) & 0xffffff00) | (int(alpha * 255.0) & 0xff)
            if (mPremultipliedAlpha && alpha != 1.0) rgba = premultiplyAlpha(rgba);
            
            mRawData.position = vertexID * BYTES_PER_VERTEX + COLOR_OFFSET_IN_BYTES;
            mRawData.writeUnsignedInt(switchEndian(rgba));
        }
        
        /** Updates the RGB color values of a vertex (alpha is not changed). */ 
        public function setColor(vertexID:int, color:uint):void
        {   
            var alpha:Number = getAlpha(vertexID);
            setColorAndAlpha(vertexID, color, alpha);
        }
        
        /** Returns the RGB color of a vertex (no alpha). */
        public function getColor(vertexID:int):uint
        {
            mRawData.position = vertexID * BYTES_PER_VERTEX + COLOR_OFFSET_IN_BYTES;
            var rgba:uint = switchEndian(mRawData.readUnsignedInt());
            if (mPremultipliedAlpha) rgba = unmultiplyAlpha(rgba);
            return (rgba >> 8) & 0xffffff;
        }
        
        /** Updates the alpha value of a vertex (range 0-1). */
        public function setAlpha(vertexID:int, alpha:Number):void
        {
            var color:uint = getColor(vertexID);
            setColorAndAlpha(vertexID, color, alpha);
        }
        
        /** Returns the alpha value of a vertex in the range 0-1. */
        public function getAlpha(vertexID:int):Number
        {
            mRawData.position = vertexID * BYTES_PER_VERTEX + COLOR_OFFSET_IN_BYTES;
            var rgba:uint = switchEndian(mRawData.readUnsignedInt());
            return (rgba & 0xff) / 255.0;
        }
        
        /** Updates the texture coordinates of a vertex (range 0-1). */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            mRawData.position = vertexID * BYTES_PER_VERTEX + TEXCOORD_OFFSET_IN_BYTES;
            mRawData.writeFloat(u);
            mRawData.writeFloat(v);
        }
        
        /** Returns the texture coordinates of a vertex in the range 0-1. */
        public function getTexCoords(vertexID:int, texCoords:Point):void
        {
            mRawData.position = vertexID * BYTES_PER_VERTEX + TEXCOORD_OFFSET_IN_BYTES;
            texCoords.x = mRawData.readFloat();
            texCoords.y = mRawData.readFloat();
        }
        
        // utility functions
        
        /** Translate the position of a vertex by a certain offset. */
        public function translateVertex(vertexID:int, deltaX:Number, deltaY:Number):void
        {
            var x:Number, y:Number;
            var position:int = vertexID * BYTES_PER_VERTEX + POSITION_OFFSET_IN_BYTES;
            
            mRawData.position = position;
            x = mRawData.readFloat() + deltaX;
            y = mRawData.readFloat() + deltaY;
            
            mRawData.position = position;
            mRawData.writeFloat(x);
            mRawData.writeFloat(y);
        }

        /** Transforms the position of subsequent vertices by multiplication with a 
         *  transformation matrix. */
        public function transformVertex(vertexID:int, matrix:Matrix, numVertices:int=1):void
        {
            var position:int = vertexID * BYTES_PER_VERTEX + POSITION_OFFSET_IN_BYTES;
            var x:Number, y:Number;
            
            for (var i:int=0; i<numVertices; ++i)
            {
                mRawData.position = position;
                x = mRawData.readFloat();
                y = mRawData.readFloat();
                
                mRawData.position = position;
                mRawData.writeFloat(matrix.a * x + matrix.c * y + matrix.tx);
                mRawData.writeFloat(matrix.d * y + matrix.b * x + matrix.ty);
                
                position += BYTES_PER_VERTEX;
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
        
        /** Multiplies the alpha value of subsequent vertices with a certain factor. */
        public function scaleAlpha(vertexID:int, factor:Number, numVertices:int=1):void
        {
            if (factor == 1.0) return;
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
             
            var i:int;
            
            if (mPremultipliedAlpha)
            {
                for (i=0; i<numVertices; ++i)
                    setAlpha(vertexID+i, getAlpha(vertexID+i) * factor);
            }
            else
            {
                var offset:int = vertexID * BYTES_PER_VERTEX + COLOR_OFFSET_IN_BYTES + 3;
                var oldAlpha:Number;
                
                for (i=0; i<numVertices; ++i)
                {
                    oldAlpha = mRawData[offset] / 255.0;
                    mRawData[offset] = int(oldAlpha * factor * 255.0);
                    offset += BYTES_PER_VERTEX;
                }
            }
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
                var offset:int = vertexID * BYTES_PER_VERTEX + POSITION_OFFSET_IN_BYTES;
                var x:Number, y:Number, i:int;
                
                if (transformationMatrix == null)
                {
                    for (i=0; i<numVertices; ++i)
                    {
                        mRawData.position = offset;
                        x = mRawData.readFloat();
                        y = mRawData.readFloat();
                        offset += BYTES_PER_VERTEX;
                        
                        if (minX > x) minX = x;
                        if (maxX < x) maxX = x;
                        if (minY > y) minY = y;
                        if (maxY < y) maxY = y;
                    }
                }
                else
                {
                    for (i=0; i<numVertices; ++i)
                    {
                        mRawData.position = offset;
                        x = mRawData.readFloat();
                        y = mRawData.readFloat();
                        offset += BYTES_PER_VERTEX;
                        
                        MatrixUtil.transformCoords(transformationMatrix, x, y, sHelperPoint);
                        
                        if (minX > sHelperPoint.x) minX = sHelperPoint.x;
                        if (maxX < sHelperPoint.x) maxX = sHelperPoint.x;
                        if (minY > sHelperPoint.y) minY = sHelperPoint.y;
                        if (maxY < sHelperPoint.y) maxY = sHelperPoint.y;
                    }
                }
                
                resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
            }
            
            return resultRect;
        }
        
        /** Creates a string that contains the values of all included vertices. */
        public function toString():String
        {
            mRawData.position = 0;
            var result:String = "[VertexData \n";
            
            for (var i:int=0; i<numVertices; ++i)
            {
                result += "  [Vertex " + i + ": " +
                          "x=" + mRawData.readFloat().toFixed(1) + ", " +
                          "y=" + mRawData.readFloat().toFixed(1) + ", " +
                          "rgba=" + mRawData.readUnsignedInt().toString(16) + ", " +
                          "u=" + mRawData.readFloat().toFixed(3) + ", " +
                          "v=" + mRawData.readFloat().toFixed(3) + "]" +
                          (i == numVertices-1 ? "\n" : ",\n");
            }
            
            return result + "]";
        }
        
        // helpers
        
        [Inline]
        private final function switchEndian(value:uint):uint
        {
            return ( value        & 0xff) << 24 |
                   ((value >>  8) & 0xff) << 16 |
                   ((value >> 16) & 0xff) <<  8 |
                   ((value >> 24) & 0xff);
        }
        
        private final function premultiplyAlpha(rgba:uint):uint
        {
            var alpha:uint = rgba & 0xff;
            
            if (alpha == 0xff) return rgba;
            else
            {
                var factor:Number = alpha / 255.0;
                var r:uint = ((rgba >> 24) & 0xff) * factor;
                var g:uint = ((rgba >> 16) & 0xff) * factor;
                var b:uint = ((rgba >>  8) & 0xff) * factor;
                
                return (r & 0xff) << 24 |
                       (g & 0xff) << 16 |
                       (b & 0xff) <<  8 | alpha;
            }
        }
        
        private final function unmultiplyAlpha(rgba:uint):uint
        {
            var alpha:uint = rgba & 0xff;
            
            if (alpha == 0xff || alpha == 0x0) return rgba;
            else
            {
                var factor:Number = alpha / 255.0;
                var r:uint = ((rgba >> 24) & 0xff) / factor;
                var g:uint = ((rgba >> 16) & 0xff) / factor;
                var b:uint = ((rgba >>  8) & 0xff) / factor;
                
                return (r & 0xff) << 24 |
                       (g & 0xff) << 16 |
                       (b & 0xff) <<  8 | alpha;
            }
        }
        
        // properties
        
        /** Indicates if any vertices have a non-white color or are not fully opaque. */
        public function get tinted():Boolean
        {
            var offset:int = COLOR_OFFSET_IN_BYTES;
            
            for (var i:int=0; i<mNumVertices; ++i)
            {
                mRawData.position = offset;
                
                if (mRawData.readUnsignedInt() != 0xffffffff) 
                    return true;
                
                offset += BYTES_PER_VERTEX;
            }
            
            return false;
        }
        
        /** Changes the way alpha and color values are stored. Optionally updates all exisiting 
          * vertices. */
        public function setPremultipliedAlpha(value:Boolean, updateData:Boolean=true):void
        {
            if (updateData && value != mPremultipliedAlpha)
            {
                var offset:int = COLOR_OFFSET_IN_BYTES;
                var oldColor:uint;
                var newColor:uint;
                
                for (var i:int=0; i<mNumVertices; ++i)
                {
                    mRawData.position = offset;
                    oldColor = switchEndian(mRawData.readUnsignedInt());
                    newColor = value ? premultiplyAlpha(oldColor) : unmultiplyAlpha(oldColor);
                    
                    mRawData.position = offset;
                    mRawData.writeUnsignedInt(switchEndian(newColor));
                    
                    offset += BYTES_PER_VERTEX;
                }
            }
            
            mPremultipliedAlpha = value;
            mMinAlpha = value ? 5.0 / 255.0 : 0.0;
        }
        
        /** Indicates if the rgb values are stored premultiplied with the alpha value. 
         *  If you change this value, the color data is updated accordingly. If you don't want
         *  that, use the 'setPremultipliedAlpha' method instead. */
        public function get premultipliedAlpha():Boolean { return mPremultipliedAlpha; }
        public function set premultipliedAlpha(value:Boolean):void
        {
            setPremultipliedAlpha(value);
        }
        
        /** The total number of vertices. */
        public function get numVertices():int { return mNumVertices; }
        public function set numVertices(value:int):void
        {
            mRawData.length = value * BYTES_PER_VERTEX; 
            
            for (var i:int=mNumVertices; i<value; ++i)  // alpha should be '1' per default
                mRawData[int(i * BYTES_PER_VERTEX + COLOR_OFFSET_IN_BYTES + 3)] = 0xff;
            
            mNumVertices = value;
        }
        
        /** The raw vertex data; not a copy! */
        public function get rawData():ByteArray { return mRawData; }
    }
}
