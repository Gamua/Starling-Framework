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
    import flash.display3D.VertexBuffer3D;
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
        private const CONTEXT_POT_SUPPORT_KEY:String = "RenderTexture.supportsNonPotDimensions";
        private const PMA:Boolean = true;
        
        private var mActiveTexture:Texture;
        private var mBufferTexture:Texture;
        private var mHelperImage:Image;
        private var mDrawing:Boolean;
        private var mBufferReady:Boolean;
        private var mSupport:RenderSupport;
        
        /** helper object */
        private static var sClipRect:Rectangle = new Rectangle();
        
        /** Creates a new RenderTexture with a certain size (in points). If the texture is
         *  persistent, the contents of the texture remains intact after each draw call, allowing
         *  you to use the texture just like a canvas. If it is not, it will be cleared before each
         *  draw call. Persistancy doubles the required graphics memory! Thus, if you need the
         *  texture only for one draw (or drawBundled) call, you should deactivate it. */
        public function RenderTexture(width:int, height:int, persistent:Boolean=true, scale:Number=-1)
        {
            // TODO: when Adobe has fixed this bug on the iPad 1, we can remove 'legalWidth/Height'
            //       and just pass on the original values.

            var legalWidth:int  = width;
            var legalHeight:int = height;

            if (!supportsNonPotDimensions)
            {
                legalWidth  = getNextPowerOfTwo(width);
                legalHeight = getNextPowerOfTwo(height);
            }

            mActiveTexture = Texture.empty(legalWidth, legalHeight, PMA, false, true, scale);
            mActiveTexture.root.onRestore = mActiveTexture.root.clear;
            
            super(mActiveTexture, new Rectangle(0, 0, width, height), true, null, false);
            
            var rootWidth:Number  = mActiveTexture.root.width;
            var rootHeight:Number = mActiveTexture.root.height;
            
            mSupport = new RenderSupport();
            mSupport.setOrthographicProjection(0, 0, rootWidth, rootHeight);
            
            if (persistent)
            {
                mBufferTexture = Texture.empty(legalWidth, legalHeight, PMA, false, true, scale);
                mBufferTexture.root.onRestore = mBufferTexture.root.clear;
                mHelperImage = new Image(mBufferTexture);
                mHelperImage.smoothing = TextureSmoothing.NONE; // solves some antialias-issues
            }
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            mSupport.dispose();
            mActiveTexture.dispose();
            
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
         *  @param antiAliasing Only supported beginning with AIR 13, and only on Desktop.
         *                      Values range from 0 (no antialiasing) to 4 (best quality).
         */
        public function draw(object:DisplayObject, matrix:Matrix=null, alpha:Number=1.0,
                             antiAliasing:int=0):void
        {
            if (object == null) return;
            
            if (mDrawing)
                render(object, matrix, alpha);
            else
                renderBundled(render, object, matrix, alpha, antiAliasing);
        }
        
        /** Bundles several calls to <code>draw</code> together in a block. This avoids buffer 
         *  switches and allows you to draw multiple objects into a non-persistent texture.
         *  Note that the 'antiAliasing' setting provided here overrides those provided in
         *  individual 'draw' calls.
         *  
         *  @param drawingBlock: a callback with the form: <pre>function():void;</pre>
         *  @param antiAliasing: Only supported beginning with AIR 13, and only on Desktop.
         *                       Values range from 0 (no antialiasing) to 4 (best quality). */
        public function drawBundled(drawingBlock:Function, antiAliasing:int=0):void
        {
            renderBundled(drawingBlock, null, null, 1.0, antiAliasing);
        }
        
        private function render(object:DisplayObject, matrix:Matrix=null, alpha:Number=1.0):void
        {
            mSupport.loadIdentity();
            mSupport.blendMode = object.blendMode;
            
            if (matrix) mSupport.prependMatrix(matrix);
            else        mSupport.transformMatrix(object);
            
            object.render(mSupport, alpha);
        }
        
        private function renderBundled(renderBlock:Function, object:DisplayObject=null,
                                       matrix:Matrix=null, alpha:Number=1.0,
                                       antiAliasing:int=0):void
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
            sClipRect.setTo(0, 0, mActiveTexture.width, mActiveTexture.height);

            mSupport.pushClipRect(sClipRect);
            mSupport.setRenderTarget(mActiveTexture, antiAliasing);
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
                if (renderBlock != null)
                    renderBlock(object, matrix, alpha);
            }
            finally
            {
                mDrawing = false;
                mSupport.finishQuadBatch();
                mSupport.nextFrame();
                mSupport.renderTarget = null;
                mSupport.popClipRect();
            }
        }
        
        /** Clears the render texture with a certain color and alpha value. Call without any
         *  arguments to restore full transparency. */
        public function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            mSupport.renderTarget = mActiveTexture;
            mSupport.clear(rgb, alpha);
            mSupport.renderTarget = null;
        }
        
        // workaround for iPad 1

        /** On the iPad 1 (and maybe other hardware?) clearing a non-POT RectangleTexture causes
         *  an error in the next "createVertexBuffer" call. Thus, we're forced to make this
         *  really ... elegant check here. */
        private function get supportsNonPotDimensions():Boolean
        {
            var target:Starling = Starling.current;
            var context:Context3D = Starling.context;
            var support:Object = target.contextData[CONTEXT_POT_SUPPORT_KEY];

            if (support == null)
            {
                if (target.profile != "baselineConstrained" && "createRectangleTexture" in context)
                {
                    var texture:TextureBase;
                    var buffer:VertexBuffer3D;

                    try
                    {
                        texture = context["createRectangleTexture"](2, 3, "bgra", true);
                        context.setRenderToTexture(texture);
                        context.clear();
                        context.setRenderToBackBuffer();
                        context.createVertexBuffer(1, 1);
                        support = true;
                    }
                    catch (e:Error)
                    {
                        support = false;
                    }
                    finally
                    {
                        if (texture) texture.dispose();
                        if (buffer) buffer.dispose();
                    }
                }
                else
                {
                    support = false;
                }

                target.contextData[CONTEXT_POT_SUPPORT_KEY] = support;
            }

            return support;
        }

        // properties

        /** Indicates if the texture is persistent over multiple draw calls. */
        public function get isPersistent():Boolean { return mBufferTexture != null; }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return mActiveTexture.base; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return mActiveTexture.root; }
    }
}