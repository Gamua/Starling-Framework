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
        private var mPremultipliedAlpha:Boolean;
        private var mNumVertices:int;
		
		private var mColorData:Vector.<Number>;
		private var mPositionData:Vector.<Number>;
		private var mTextureData:Vector.<Number>;

        /** Helper object. */
        private static var sHelperPoint:Point = new Point();
        
        /** Create a new VertexData object with a specified number of vertices. */
        public function VertexData(numVertices:int, premultipliedAlpha:Boolean=false)
        {
			var cdl:int=numVertices<<2;
			var pdl:int=numVertices<<1;
			mColorData=new Vector.<Number>(cdl);
			mPositionData=new Vector.<Number>(pdl);
			mTextureData=new Vector.<Number>(pdl);
           	mNumVertices = numVertices;
			for (var i:int = 3; i < cdl; i+=4) 
			{
				mColorData[i]=1;
			}
			mPremultipliedAlpha = premultipliedAlpha;
        }

        /** Creates a duplicate of either the complete vertex data object, or of a subset. 
         *  To clone all vertices, set 'numVertices' to '-1'. */
        public function clone(vertexID:int=0, numVertices:int=-1):VertexData
        {
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            var clone:VertexData = new VertexData(0, mPremultipliedAlpha);
            clone.mNumVertices = numVertices; 
			clone.mColorData=mColorData.slice(vertexID*4,numVertices*4);
			clone.mPositionData=mPositionData.slice(vertexID*2,numVertices*2);
			clone.mTextureData=mTextureData.slice(vertexID*2,numVertices*2);
			clone.mColorData.fixed=true;
			clone.mPositionData.fixed=true;
			clone.mTextureData.fixed=true;
            return clone;
        }
        
        /** Copies the vertex data (or a range of it, defined by 'vertexID' and 'numVertices') 
         *  of this instance to another vertex data object, starting at a certain index. */
        public function copyTo(targetData:VertexData,tinted:Boolean, targetVertexID:int=0,
                               vertexID:int=0, numVertices:int=-1):void
        {
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
            
            // todo: check/convert pma
            
            var targetIndex:int ;
            var sourceIndex:int ;
            var dataLength:int ;
			var i:int;
			if(tinted)
			{
				 targetIndex = targetVertexID << 2;
				 sourceIndex = vertexID << 2;
				 dataLength = numVertices << 2;
				 var targetColorData:Vector.<Number>=targetData.mColorData;
				 for ( i=sourceIndex; i<dataLength; ++i)
				 {
					 targetColorData[targetIndex]=mColorData[i];
					 targetIndex++;
				 }
			}
			
			 targetIndex = targetVertexID << 1;
			 sourceIndex = vertexID << 1;
			 dataLength = numVertices << 1;
			 var targetPositionData:Vector.<Number>=targetData.mPositionData;
			 var targetTextureData:Vector.<Number>=targetData.mTextureData;
            for ( i=sourceIndex; i<dataLength; ++i)
			{
				targetPositionData[targetIndex]=mPositionData[i];
				targetTextureData[targetIndex]=mTextureData[i];
				targetIndex++;
			}
        }
        
        /** Appends the vertices from another VertexData object. */
        public function append(data:VertexData):void
        {
			
			
			var pData:Vector.<Number>=data.mPositionData;
			var tData:Vector.<Number>=data.mTextureData;
			var targetIndex:int=mPositionData.length;
			var sourceIndex:int=targetIndex;
			var dataLength:int=pData.length;
			var i:int;
			mPositionData.fixed=false;
			mTextureData.fixed=false;
			mColorData.fixed=false;
			for ( i=sourceIndex; i<dataLength; ++i)
			{
				mPositionData[targetIndex]=pData[i];
				mTextureData[targetIndex]=tData[i];
				targetIndex++;
			}
			var cData:Vector.<Number>=data.mColorData;
			 targetIndex=mColorData.length;
			 sourceIndex=targetIndex;
			 dataLength=cData.length;
			for ( i=sourceIndex; i<dataLength; ++i)
			{
				mColorData[targetIndex]=cData[i];
				targetIndex++;
			}
			
			mPositionData.fixed=true;
			mTextureData.fixed=true;
			mColorData.fixed=true;
            
            mNumVertices += data.mNumVertices;
        }
        
        // functions
        
        /** Updates the position values of a vertex. */
        public function setPosition(vertexID:int, x:Number, y:Number):void
        {
			var offset:int = vertexID<<1;
			mPositionData[offset] = x;
			mPositionData[offset+1] = y;
        }
        
        /** Returns the position of a vertex. */
        public function getPosition(vertexID:int, position:Point):void
        {
            var offset:int = vertexID<<1;
            position.x = mPositionData[offset];
            position.y = mPositionData[offset+1];
        }
        
        /** Updates the RGB color values of a vertex. */ 
        public function setColor(vertexID:int, color:uint):void
        {   
            var offset:int = vertexID<<2;
            var multiplier:Number = mPremultipliedAlpha ? mColorData[offset+3] : 1.0;
			mColorData[offset]        = ((color >> 16) & 0xff) / 255.0 * multiplier;
			mColorData[int(offset+1)] = ((color >>  8) & 0xff) / 255.0 * multiplier;
			mColorData[int(offset+2)] = ( color        & 0xff) / 255.0 * multiplier;
        }
        
        /** Returns the RGB color of a vertex (no alpha). */
        public function getColor(vertexID:int):uint
        {
            var offset:int = vertexID<<2;
            var divisor:Number = mPremultipliedAlpha ? mColorData[offset+3] : 1.0;
            
            if (divisor == 0) return 0;
            else
            {
                var red:Number   = mColorData[offset]        / divisor;
                var green:Number = mColorData[int(offset+1)] / divisor;
                var blue:Number  = mColorData[int(offset+2)] / divisor;
                
                return (int(red*255) << 16) | (int(green*255) << 8) | int(blue*255);
            }
        }
        
        /** Updates the alpha value of a vertex (range 0-1). */
        public function setAlpha(vertexID:int, alpha:Number):void
        {
			var offset:int = (vertexID<<2) + 3;
            
            if (mPremultipliedAlpha)
            {
                if (alpha < 0.001) alpha = 0.001; // zero alpha would wipe out all color data
                var color:uint = getColor(vertexID);
                mColorData[offset] = alpha;
                setColor(vertexID, color);
            }
            else
            {
				mColorData[offset] = alpha;
            }
        }
        
        /** Returns the alpha value of a vertex in the range 0-1. */
        public function getAlpha(vertexID:int):Number
        {
            var offset:int = (vertexID<<2) + 3;
            return mColorData[offset];
        }
        
        /** Updates the texture coordinates of a vertex (range 0-1). */
        public function setTexCoords(vertexID:int, u:Number, v:Number):void
        {
            var offset:int = vertexID<<1;
			mTextureData[offset]        = u;
			mTextureData[offset+1] = v;
        }
        
        /** Returns the texture coordinates of a vertex in the range 0-1. */
        public function getTexCoords(vertexID:int, texCoords:Point):void
        {
            var offset:int = vertexID<<1;
            texCoords.x = mTextureData[offset];
            texCoords.y = mTextureData[offset+1];
        }
        
        // utility functions
        
        /** Translate the position of a vertex by a certain offset. */
        public function translateVertex(vertexID:int, deltaX:Number, deltaY:Number):void
        {
            var offset:int = vertexID<<1;
            mPositionData[offset]        += deltaX;
			mPositionData[offset+1] += deltaY;
        }

        /** Transforms the position of subsequent vertices by multiplication with a 
         *  transformation matrix. */
        public function transformVertex(vertexID:int, matrix:Matrix, numVertices:int=1):void
        {
			var offset:int = vertexID<<1;
            
            for (var i:int=0; i<numVertices; ++i)
            {
                var x:Number = mPositionData[offset];
                var y:Number = mPositionData[offset+1];
                
				mPositionData[offset]        = matrix.a * x + matrix.c * y + matrix.tx;
				mPositionData[offset+1] = matrix.d * y + matrix.b * x + matrix.ty;
                
                offset += 2;
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
                var offset:int = (vertexID<<2) + 3;
                for (i=0; i<numVertices; ++i)
                    mColorData[offset + i*4] *= alpha;
            }
        }
        
//        private function getOffset(vertexID:int):int
//        {
//            return vertexID * ELEMENTS_PER_VERTEX;
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
            
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            var offset:int = vertexID<<1;
            var x:Number, y:Number, i:int;
            
            if (transformationMatrix == null)
            {
                for (i=vertexID; i<numVertices; ++i)
                {
                    x = mPositionData[offset];
                    y = mPositionData[offset+1];
                    offset += 2;
                    
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
                    x = mPositionData[offset];
                    y = mPositionData[offset+1];
                    offset += 2;
                    
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
			var colorLen:int=mNumVertices<<2;
            for (var i:int=0; i<colorLen;i++)
            {
            	if (mColorData[i] != 1.0) return true;
            }
            return false;
        }
        
        /** Changes the way alpha and color values are stored. Updates all exisiting vertices. */
        public function setPremultipliedAlpha(value:Boolean, updateData:Boolean=true):void
        {
            if (value == mPremultipliedAlpha) return;
            
            if (updateData)
            {
                var dataLength:int = mColorData.length;
                
                for (var i:int=0; i<dataLength; i += 4)
                {
                    var alpha:Number = mColorData[i+3];
                    var divisor:Number = mPremultipliedAlpha ? alpha : 1.0;
                    var multiplier:Number = value ? alpha : 1.0;
                    
                    if (divisor != 0)
                    {
						mColorData[i]        = mColorData[i]        / divisor * multiplier;
						mColorData[i+1] = mColorData[i+1] / divisor * multiplier;
						mColorData[i+2] = mColorData[i+2] / divisor * multiplier;
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
            var delta:int = value - mNumVertices;
            
            if(delta!=0)
			{
				mPositionData.fixed=false;
				mTextureData.fixed=false;
				mColorData.fixed=false;
				var i:int;
				if(delta<0)
				{
					var pi:int=value<<1;
					var ci:int=value<<2;
					var dp:int=delta<<1;
					var dc:int=delta<<2;
					mPositionData.splice(pi,dp);
					mColorData.splice(ci,dc);
					mTextureData.splice(pi,dp);
				}
				else
				{
					for (i=0; i<delta; ++i)
					{
						mPositionData.push(0,0);
						mColorData.push(0,0,0,1);
						mTextureData.push(0,0);
					}
				}
				mNumVertices = value;
				mPositionData.fixed=true;
				mTextureData.fixed=true;
				mColorData.fixed=true;
			}
        }
        
        /** The raw vertex data; not a copy! */

		public function get ColorData():Vector.<Number>
		{
			return mColorData;
		}

		public function get PositionData():Vector.<Number>
		{
			return mPositionData;
		}

		public function get TextureData():Vector.<Number>
		{
			return mTextureData;
		}
    }
}
