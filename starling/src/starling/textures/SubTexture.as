// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures
{
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;
    import starling.utils.VertexData;

    /** A SubTexture represents a section of another texture. This is achieved solely by 
     *  manipulation of texture coordinates, making the class very efficient. 
     *
     *  <p><em>Note that it is OK to create subtextures of subtextures.</em></p>
     */
    public class SubTexture extends Texture
    {
        private var mParent:Texture;
        private var mOwnsParent:Boolean;
        private var mRegion:Rectangle;
        private var mFrame:Rectangle;
        private var mRotated:Boolean;
        private var mWidth:Number;
        private var mHeight:Number;
        private var mTransformationMatrix:Matrix;
        
        /** Helper object. */
        private static var sTexCoords:Point = new Point();
        private static var sMatrix:Matrix = new Matrix();
        
        /** Creates a new SubTexture containing the specified region of a parent texture.
         *
         *  @param parent     The texture you want to create a SubTexture from.
         *  @param region     The region of the parent texture that the SubTexture will show
         *                    (in points). If <code>null</code>, the complete area of the parent.
         *  @param ownsParent If <code>true</code>, the parent texture will be disposed
         *                    automatically when the SubTexture is disposed.
         *  @param frame      If the texture was trimmed, the frame rectangle can be used to restore
         *                    the trimmed area.
         *  @param rotated    If true, the SubTexture will show the parent region rotated by
         *                    90 degrees (CCW).
         */
        public function SubTexture(parent:Texture, region:Rectangle=null,
                                   ownsParent:Boolean=false, frame:Rectangle=null,
                                   rotated:Boolean=false)
        {
            // TODO: in a future version, the order of arguments of this constructor should
            //       be fixed ('ownsParent' at the very end).
            
            mParent = parent;
            mRegion = region ? region.clone() : new Rectangle(0, 0, parent.width, parent.height);
            mFrame = frame ? frame.clone() : null;
            mOwnsParent = ownsParent;
            mRotated = rotated;
            mWidth  = rotated ? mRegion.height : mRegion.width;
            mHeight = rotated ? mRegion.width  : mRegion.height;
            mTransformationMatrix = new Matrix();
            
            if (rotated)
            {
                mTransformationMatrix.translate(0, -1);
                mTransformationMatrix.rotate(Math.PI / 2.0);
            }

            if (mFrame && (mFrame.x > 0 || mFrame.y > 0 ||
                mFrame.right < mWidth || mFrame.bottom < mHeight))
            {
                trace("[Starling] Warning: frames inside the texture's region are unsupported.");
            }

            mTransformationMatrix.scale(mRegion.width  / mParent.width,
                                        mRegion.height / mParent.height);
            mTransformationMatrix.translate(mRegion.x  / mParent.width,
                                            mRegion.y  / mParent.height);
        }
        
        /** Disposes the parent texture if this texture owns it. */
        public override function dispose():void
        {
            if (mOwnsParent) mParent.dispose();
            super.dispose();
        }
        
        /** @inheritDoc */
        public override function adjustVertexData(vertexData:VertexData, vertexID:int, count:int):void
        {
            var startIndex:int = vertexID * VertexData.ELEMENTS_PER_VERTEX + VertexData.TEXCOORD_OFFSET;
            var stride:int = VertexData.ELEMENTS_PER_VERTEX - 2;
            
            adjustTexCoords(vertexData.rawData, startIndex, stride, count);
            
            if (mFrame)
            {
                if (count != 4)
                    throw new ArgumentError("Textures with a frame can only be used on quads");
                
                var deltaRight:Number  = mFrame.width  + mFrame.x - mWidth;
                var deltaBottom:Number = mFrame.height + mFrame.y - mHeight;
                
                vertexData.translateVertex(vertexID,     -mFrame.x, -mFrame.y);
                vertexData.translateVertex(vertexID + 1, -deltaRight, -mFrame.y);
                vertexData.translateVertex(vertexID + 2, -mFrame.x, -deltaBottom);
                vertexData.translateVertex(vertexID + 3, -deltaRight, -deltaBottom);
            }
        }

        /** @inheritDoc */
        public override function adjustTexCoords(texCoords:Vector.<Number>,
                                                 startIndex:int=0, stride:int=0, count:int=-1):void
        {
            if (count < 0)
                count = (texCoords.length - startIndex - 2) / (stride + 2) + 1;

            var endIndex:int = startIndex + count * (2 + stride);
            var texture:SubTexture = this;
            var u:Number, v:Number;
            
            sMatrix.identity();
            
            while (texture)
            {
                sMatrix.concat(texture.mTransformationMatrix);
                texture = texture.parent as SubTexture;
            }
            
            for (var i:int=startIndex; i<endIndex; i += 2 + stride)
            {
                u = texCoords[    i   ];
                v = texCoords[int(i+1)];
                
                MatrixUtil.transformCoords(sMatrix, u, v, sTexCoords);
                
                texCoords[    i   ] = sTexCoords.x;
                texCoords[int(i+1)] = sTexCoords.y;
            }
        }
        
        /** The texture which the SubTexture is based on. */
        public function get parent():Texture { return mParent; }
        
        /** Indicates if the parent texture is disposed when this object is disposed. */
        public function get ownsParent():Boolean { return mOwnsParent; }
        
        /** If true, the SubTexture will show the parent region rotated by 90 degrees (CCW). */
        public function get rotated():Boolean { return mRotated; }

        /** The region of the parent texture that the SubTexture is showing (in points).
         *
         *  <p>CAUTION: not a copy, but the actual object! Do not modify!</p> */
        public function get region():Rectangle { return mRegion; }

        /** The clipping rectangle, which is the region provided on initialization 
         *  scaled into [0.0, 1.0]. */
        public function get clipping():Rectangle
        {
            var topLeft:Point = new Point();
            var bottomRight:Point = new Point();
            
            MatrixUtil.transformCoords(mTransformationMatrix, 0.0, 0.0, topLeft);
            MatrixUtil.transformCoords(mTransformationMatrix, 1.0, 1.0, bottomRight);
            
            var clipping:Rectangle = new Rectangle(topLeft.x, topLeft.y,
                bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
            
            RectangleUtil.normalize(clipping);
            return clipping;
        }
        
        /** The matrix that is used to transform the texture coordinates into the coordinate
         *  space of the parent texture (used internally by the "adjust..."-methods).
         *
         *  <p>CAUTION: not a copy, but the actual object! Do not modify!</p> */
        public function get transformationMatrix():Matrix { return mTransformationMatrix; }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mParent.base; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return mParent.root; }
        
        /** @inheritDoc */
        public override function get format():String { return mParent.format; }
        
        /** @inheritDoc */
        public override function get width():Number { return mWidth; }
        
        /** @inheritDoc */
        public override function get height():Number { return mHeight; }
        
        /** @inheritDoc */
        public override function get nativeWidth():Number { return mWidth * scale; }
        
        /** @inheritDoc */
        public override function get nativeHeight():Number { return mHeight * scale; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return mParent.mipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return mParent.premultipliedAlpha; }
        
        /** @inheritDoc */
        public override function get scale():Number { return mParent.scale; }
        
        /** @inheritDoc */
        public override function get repeat():Boolean { return mParent.repeat; }
        
        /** @inheritDoc */
        public override function get frame():Rectangle { return mFrame; }
    }
}