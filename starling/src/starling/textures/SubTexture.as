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

    public class SubTexture extends Texture
    {
        private var mParent:Texture;
        private var mClipping:Rectangle;
        private var mRootClipping:Rectangle;
        
        public function SubTexture(parentTexture:Texture, region:Rectangle)
        {
            mParent = parentTexture;
            this.clipping = new Rectangle(region.x / parentTexture.width,
                                          region.y / parentTexture.height,
                                          region.width / parentTexture.width,
                                          region.height / parentTexture.height);
        }
        
        public override function adjustVertexData(vertexData:VertexData):VertexData
        {
            var newData:VertexData = super.adjustVertexData(vertexData);
            var numVertices:int = vertexData.numVertices;
            
            var clipX:Number = mRootClipping.x;
            var clipY:Number = mRootClipping.y;
            var clipWidth:Number  = mRootClipping.width;
            var clipHeight:Number = mRootClipping.height;
            
            for (var i:int=0; i<numVertices; ++i)
            {
                var texCoords:Point = vertexData.getTexCoords(i);
                newData.setTexCoords(i, clipX + texCoords.x * clipWidth,
                                        clipY + texCoords.y * clipHeight);
            }
            
            return newData;
        }
        
        public function get parent():Texture { return mParent; }
        
        public function get clipping():Rectangle { return mClipping.clone(); }
        public function set clipping(value:Rectangle):void
        {
            mClipping = value.clone();
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
        
        public override function get base():TextureBase { return mParent.base; }
        public override function get width():Number { return mParent.width * mClipping.width; }
        public override function get height():Number { return mParent.height * mClipping.height; }
        public override function get mipMapping():Boolean { return mParent.mipMapping; }
        public override function get premultipliedAlpha():Boolean { return mParent.premultipliedAlpha; }
    }
}