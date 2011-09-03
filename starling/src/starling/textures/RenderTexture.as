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
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    public class RenderTexture extends Texture
    {
        private var mActiveTexture:Texture;
        private var mBufferTexture:Texture;
        private var mHelperImage:Image;
        private var mDrawing:Boolean;
        
        private var mNativeWidth:int;
        private var mNativeHeight:int;
        private var mSupport:RenderSupport;
        
        public function RenderTexture(width:int, height:int, persistent:Boolean=true)
        {
            mSupport = new RenderSupport();
            mNativeWidth  = getNextPowerOfTwo(width);
            mNativeHeight = getNextPowerOfTwo(height);
            mActiveTexture = Texture.empty(width, height, 0x0, true);
            
            if (persistent)
            {
                mBufferTexture = Texture.empty(width, height, 0x0, true);
                mHelperImage = new Image(mBufferTexture);
            }
        }
        
        public override function dispose():void
        {
            mActiveTexture.dispose();
            
            if (isPersistent) 
            {
                mBufferTexture.dispose();
                mHelperImage.dispose();
            }
            
            super.dispose();
        }
        
        public function draw(object:DisplayObject, antiAliasing:int=0):void
        {
            if (object == null) return;
            
            if (mDrawing)
                render();
            else
                drawBundled(render, antiAliasing);
            
            function render():void
            {
                mSupport.pushMatrix();
                mSupport.transformMatrix(object);            
                object.render(mSupport, 1.0);
                mSupport.popMatrix();
            }
        }
        
        public function drawBundled(drawingBlock:Function, antiAliasing:int=0):void
        {
            // limit drawing to relevant area
            Starling.context.setScissorRectangle(
                new Rectangle(0, 0, mActiveTexture.width, mActiveTexture.height));
            
            // persistent drawing uses double buffering, as Molehill forces us to call 'clear'
            // on every render target once per update.
            
            // switch buffers
            if (isPersistent)
            {
                var tmpTexture:Texture = mActiveTexture;
                mActiveTexture = mBufferTexture;
                mBufferTexture = tmpTexture;
                mHelperImage.texture = mBufferTexture;
            }
            
            Starling.context.setRenderToTexture(mActiveTexture.base, false, antiAliasing);
            
            mSupport.setOrthographicProjection(mNativeWidth, mNativeHeight);
            mSupport.setDefaultBlendFactors(true);
            mSupport.clear();
            
            // draw buffer
            if (isPersistent)
                mHelperImage.render(mSupport, 1.0);
                        
            try
            {
                mDrawing = true;
                
                // draw new objects
                if (drawingBlock != null)
                    drawingBlock();
            }
            finally
            { 
                mDrawing = false;
                mSupport.resetMatrix();
                Starling.context.setScissorRectangle(null);
                Starling.context.setRenderToBackBuffer();
            }
        }
        
        public function clear():void
        {
            Starling.context.setRenderToTexture(mActiveTexture.base);
            mSupport.clear();

            if (isPersistent)
            {
                Starling.context.setRenderToTexture(mActiveTexture.base);
                mSupport.clear();
            }
            
            Starling.context.setRenderToBackBuffer();
        }
        
        public override function adjustVertexData(vertexData:VertexData):VertexData
        {
            return mActiveTexture.adjustVertexData(vertexData);   
        }
        
        public function get isPersistent():Boolean { return mBufferTexture != null; }
        
        public override function get width():Number { return mActiveTexture.width; }        
        public override function get height():Number { return mActiveTexture.height; }        
        
        public override function get premultipliedAlpha():Boolean 
        { 
            return mActiveTexture.premultipliedAlpha; 
        }
        
        public override function get base():TextureBase 
        { 
            return mActiveTexture.base; 
        }
    }
}