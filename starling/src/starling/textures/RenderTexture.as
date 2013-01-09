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
    import flash.display3D.Context3D;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.errors.MissingContextError;
    import starling.utils.getNextPowerOfTwo;

    /** A RenderTexture is a dynamic texture onto which you can draw any display object.
     * 
     *  <p>After creating a render texture, just call the <code>drawObject</code> method to render 
     *  an object directly onto the texture. The object will be drawn onto the texture at its current
     *  position, adhering its current rotation, scale and alpha properties.</p> 
     *  
     *  <p>Drawing is done very efficiently, as it is happening directly in graphics memory. After 
     *  you have drawn objects onto the texture, the performance will be just like that of a normal 
     *  texture - no matter how many objects you have drawn.</p>
     *  
     *  <p>If you draw lots of objects at once, it is recommended to bundle the drawing calls in 
     *  a block via the <code>drawBundled</code> method, like shown below. That will speed it up 
     *  immensely, allowing you to draw hundreds of objects very quickly.</p>
     *  
     * 	<pre>
     *  renderTexture.drawBundled(function():void
     *  {
     *     for (var i:int=0; i&lt;numDrawings; ++i)
     *     {
     *         image.rotation = (2 &#42; Math.PI / numDrawings) &#42; i;
     *         renderTexture.draw(image);
     *     }   
     *  });
     *  </pre>
     *  
     *  <p>To erase parts of a render texture, you can use any display object like a "rubber" by
     *  setting its blending mode to "BlendMode.ERASE".</p>
     * 
     *  <p>Beware that render textures can't be restored when the Starling's render context is lost.
     *  </p>
     *     
     */
    public class RenderTexture extends SubTexture
    {
        private const PMA:Boolean = true;
        
        private var mActiveTexture:Texture;
        private var mBufferTexture:Texture;
        private var mHelperImage:Image;
        private var mDrawing:Boolean;
        private var mBufferReady:Boolean;
        private var mSupport:RenderSupport;
        
        /** helper object */
        private static var sScissorRect:Rectangle = new Rectangle();
        
        /** Creates a new RenderTexture with a certain size. If the texture is persistent, the
         *  contents of the texture remains intact after each draw call, allowing you to use the
         *  texture just like a canvas. If it is not, it will be cleared before each draw call.
         *  Persistancy doubles the required graphics memory! Thus, if you need the texture only 
         *  for one draw (or drawBundled) call, you should deactivate it. */
        public function RenderTexture(width:int, height:int, persistent:Boolean=true, scale:Number=-1)
        {
            if (scale <= 0) scale = Starling.contentScaleFactor; 
            
            var nativeWidth:int  = getNextPowerOfTwo(width  * scale);
            var nativeHeight:int = getNextPowerOfTwo(height * scale);
            mActiveTexture = Texture.empty(width, height, PMA, true, scale);
            
            super(mActiveTexture, new Rectangle(0, 0, width, height), true);
            
            mSupport = new RenderSupport();
            mSupport.setOrthographicProjection(0, 0, nativeWidth/scale, nativeHeight/scale);
            
            if (persistent)
            {
                mBufferTexture = Texture.empty(width, height, PMA, true, scale);
                mHelperImage = new Image(mBufferTexture);
                mHelperImage.smoothing = TextureSmoothing.NONE; // solves some antialias-issues
            }
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            mSupport.dispose();
            
            if (isPersistent) 
            {
                mBufferTexture.dispose();
                mHelperImage.dispose();
            }
            
            super.dispose();
        }
        
        /** Draws an object into the texture. Note that any filters on the object will currently
         *  be ignored.
         * 
         *  @param object       The object to draw.
         *  @param matrix       If 'matrix' is null, the object will be drawn adhering its 
         *                      properties for position, scale, and rotation. If it is not null,
         *                      the object will be drawn in the orientation depicted by the matrix.
         *  @param alpha        The object's alpha value will be multiplied with this value.
         *  @param antiAliasing This parameter is currently ignored by Stage3D.
         */
        public function draw(object:DisplayObject, matrix:Matrix=null, alpha:Number=1.0, 
                             antiAliasing:int=0):void
        {
            if (object == null) return;
            
            if (mDrawing)
                render();
            else
                drawBundled(render, antiAliasing);
            
            function render():void
            {
                mSupport.loadIdentity();
                mSupport.blendMode = object.blendMode;
                
                if (matrix) mSupport.prependMatrix(matrix);
                else        mSupport.transformMatrix(object);
                
                object.render(mSupport, alpha);
            }
        }
        
        /** Bundles several calls to <code>draw</code> together in a block. This avoids buffer 
         *  switches and allows you to draw multiple objects into a non-persistent texture. */
        public function drawBundled(drawingBlock:Function, antiAliasing:int=0):void
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
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
            
            // limit drawing to relevant area
            sScissorRect.setTo(0, 0, mActiveTexture.nativeWidth, mActiveTexture.nativeHeight);

            mSupport.scissorRectangle = sScissorRect;
            mSupport.renderTarget = mActiveTexture;
            mSupport.clear();
            
            // draw buffer
            if (isPersistent && mBufferReady)
                mHelperImage.render(mSupport, 1.0);
            else
                mBufferReady = true;
            
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
                mSupport.finishQuadBatch();
                mSupport.nextFrame();
                mSupport.renderTarget = null;
                mSupport.scissorRectangle = null;
            }
        }
        
        /** Clears the texture (restoring full transparency). */
        public function clear():void
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            mSupport.renderTarget = mActiveTexture;
            mSupport.clear();
            mSupport.renderTarget = null;
        }
        
        /** Indicates if the texture is persistent over multiple draw calls. */
        public function get isPersistent():Boolean { return mBufferTexture != null; }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mActiveTexture.base; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return mActiveTexture.root; }
    }
}