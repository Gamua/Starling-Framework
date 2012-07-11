// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures
{
    import flash.display3D.textures.TextureBase;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.utils.VertexData;

    /** A SubTexture represents a section of another texture. This is achieved solely by 
     *  manipulation of texture coordinates, making the class very efficient. 
     *
     *  <p><em>Note that it is OK to create subtextures of subtextures.</em></p>
     */ 
    public class SubTexture extends Texture
    {
        private var mParent:Texture;
        private var mClipping:Rectangle;
        private var mRootClipping:Rectangle;
        private var mOwnsParent:Boolean;
        
        /** Helper object. */
        private static var sTexCoords:Point = new Point();
        
        /** Creates a new subtexture containing the specified region (in points) of a parent 
         *  texture. If 'ownsParent' is true, the parent texture will be disposed automatically
         *  when the subtexture is disposed. */
        public function SubTexture(parentTexture:Texture, region:Rectangle,
                                   ownsParent:Boolean=false)
        {
            mParent = parentTexture;
            mOwnsParent = ownsParent;
            
            if (region == null) setClipping(new Rectangle(0, 0, 1, 1));
            else setClipping(new Rectangle(region.x / parentTexture.width,
                                           region.y / parentTexture.height,
                                           region.width / parentTexture.width,
                                           region.height / parentTexture.height));
        }
        
        /** Disposes the parent texture if this texture owns it. */
        public override function dispose():void
        {
            if (mOwnsParent) mParent.dispose();
            super.dispose();
        }
        
        private function setClipping(value:Rectangle):void
        {
            mClipping = value;
            mRootClipping = value.clone();
            
            var parentTexture:SubTexture = mParent as SubTexture;
            while (parentTexture)
            {
                var parentClipping:Rectangle = parentTexture.mClipping;
                mRootClipping.x = parentClipping.x + mRootClipping.x * parentClipping.width;
                mRootClipping.y = parentClipping.y + mRootClipping.y * parentClipping.height;
                mRootClipping.width  *= parentClipping.width;
                mRootClipping.height *= parentClipping.height;
                parentTexture = parentTexture.mParent as SubTexture;
            }
        }
        
        /** @inheritDoc */
        public override function adjustVertexData(vertexData:VertexData, vertexID:int, count:int):void
        {
            super.adjustVertexData(vertexData, vertexID, count);
            
            var clipX:Number = mRootClipping.x;
            var clipY:Number = mRootClipping.y;
            var clipWidth:Number  = mRootClipping.width;
            var clipHeight:Number = mRootClipping.height;
            var endIndex:int = vertexID + count;
            
            for (var i:int=vertexID; i<endIndex; ++i)
            {
                vertexData.getTexCoords(i, sTexCoords);
                vertexData.setTexCoords(i, clipX + sTexCoords.x * clipWidth,
                                           clipY + sTexCoords.y * clipHeight);
            }
        }
        
        /** The texture which the subtexture is based on. */ 
        public function get parent():Texture { return mParent; }
        
        /** Indicates if the parent texture is disposed when this object is disposed. */
        public function get ownsParent():Boolean { return mOwnsParent; }
        
        /** The clipping rectangle, which is the region provided on initialization 
         *  scaled into [0.0, 1.0]. */
        public function get clipping():Rectangle { return mClipping.clone(); }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mParent.base; }
        
        /** @inheritDoc */
        public override function get format():String { return mParent.format; }
        
        /** @inheritDoc */
        public override function get width():Number { return mParent.width * mClipping.width; }
        
        /** @inheritDoc */
        public override function get height():Number { return mParent.height * mClipping.height; }
        
        /** @inheritDoc */
        public override function get mipMapping():Boolean { return mParent.mipMapping; }
        
        /** @inheritDoc */
        public override function get premultipliedAlpha():Boolean { return mParent.premultipliedAlpha; }
        
        /** @inheritDoc */
        public override function get scale():Number { return mParent.scale; } 
        
    }
}