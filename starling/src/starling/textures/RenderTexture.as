// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
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

    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.filters.FragmentFilter;
    import starling.rendering.Painter;
    import starling.rendering.RenderState;
    import starling.utils.MathUtil;
    import starling.utils.SystemUtil;
    import starling.utils.execute;

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
     *  <strong>Persistence</strong>
     *
     *  <p>Persistent render textures (see the 'persistent' flag in the constructor) are more
     *  expensive, because they might have to use two render buffers internally. Disable this
     *  parameter if you don't need that.</p>
     *
     *  <p>On modern hardware, you can make use of the static 'optimizePersistentBuffers'
     *  property to overcome the need for double buffering. Use this feature with care, though!</p>
     *
     */
    public class RenderTexture extends SubTexture
    {
        private static const CONTEXT_POT_SUPPORT_KEY:String = "RenderTexture.supportsNonPotDimensions";
        private static const PMA:Boolean = true;
        
        private var _activeTexture:Texture;
        private var _bufferTexture:Texture;
        private var _helperImage:Image;
        private var _drawing:Boolean;
        private var _bufferReady:Boolean;
        private var _isPersistent:Boolean;

        /** helper object */
        private static var sClipRect:Rectangle = new Rectangle();
        
        /** Indicates if new persistent textures should use a single render buffer instead of
         *  the default double buffering approach. That's faster and requires less memory, but is
         *  not supported on all hardware.
         *
         *  <p>You can safely enable this property on all iOS and Desktop systems. On Android,
         *  it's recommended to enable it only on reasonably modern hardware, e.g. only when
         *  at least one of the 'Standard' profiles is supported.</p>
         *
         *  <p>Beware: this feature requires at least Flash/AIR version 15.</p>
         *
         *  @default false
         */
        public static var optimizePersistentBuffers:Boolean = false;

        /** Creates a new RenderTexture with a certain size (in points). If the texture is
         *  persistent, the contents of the texture remains intact after each draw call, allowing
         *  you to use the texture just like a canvas. If it is not, it will be cleared before each
         *  draw call.
         *
         *  <p>Beware that persistence requires an additional texture buffer (i.e. the required
         *  memory is doubled). You can avoid that via 'optimizePersistentBuffers', though.</p>
         */
        public function RenderTexture(width:int, height:int, persistent:Boolean=true,
                                      scale:Number=-1, format:String="bgra")
        {
            // TODO: when Adobe has fixed this bug on the iPad 1 (see 'supportsNonPotDimensions'),
            //       we can remove 'legalWidth/Height' and just pass on the original values.
            //
            // [Workaround]

            if (scale <= 0) scale = Starling.contentScaleFactor;

            var legalWidth:Number  = width;
            var legalHeight:Number = height;

            if (!supportsNonPotDimensions)
            {
                legalWidth  = MathUtil.getNextPowerOfTwo(width  * scale) / scale;
                legalHeight = MathUtil.getNextPowerOfTwo(height * scale) / scale;
            }

            // [/Workaround]

            _isPersistent = persistent;
            _activeTexture = Texture.empty(legalWidth, legalHeight, PMA, false, true, scale, format);
            _activeTexture.root.onRestore = _activeTexture.root.clear;

            super(_activeTexture, new Rectangle(0, 0, width, height), true, null, false);

            if (persistent && (!optimizePersistentBuffers || !SystemUtil.supportsRelaxedTargetClearRequirement))
            {
                _bufferTexture = Texture.empty(legalWidth, legalHeight, PMA, false, true, scale, format);
                _bufferTexture.root.onRestore = _bufferTexture.root.clear;
                _helperImage = new Image(_bufferTexture);
                // _helperImage.smoothing = TextureSmoothing.NONE; // solves some antialias-issues
            }
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            _activeTexture.dispose();
            
            if (isDoubleBuffered)
            {
                _bufferTexture.dispose();
                _helperImage.dispose();
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
            
            if (_drawing)
                render(object, matrix, alpha);
            else
                renderBundled(render, object, matrix, alpha, antiAliasing);
        }
        
        /** Bundles several calls to <code>draw</code> together in a block. This avoids buffer 
         *  switches and allows you to draw multiple objects into a non-persistent texture.
         *  Note that the 'antiAliasing' setting provided here overrides those provided in
         *  individual 'draw' calls.
         *  
         *  @param drawingBlock  a callback with the form: <pre>function():void;</pre>
         *  @param antiAliasing  Only supported beginning with AIR 13, and only on Desktop.
         *                       Values range from 0 (no antialiasing) to 4 (best quality). */
        public function drawBundled(drawingBlock:Function, antiAliasing:int=0):void
        {
            renderBundled(drawingBlock, null, null, 1.0, antiAliasing);
        }
        
        private function render(object:DisplayObject, matrix:Matrix=null, alpha:Number=1.0):void
        {
            var painter:Painter = Starling.painter;
            var state:RenderState = painter.state;
            var filter:FragmentFilter = object.filter;
            var mask:DisplayObject = object.mask;

            painter.pushState();

            state.alpha *= alpha;
            state.setModelviewMatricesToIdentity();
            state.blendMode = object.blendMode == BlendMode.AUTO ?
                BlendMode.NORMAL : object.blendMode;

            if (matrix) state.transformModelviewMatrix(matrix);
            else        state.transformModelviewMatrix(object.transformationMatrix);

            if (mask)   painter.drawMask(mask);

            if (filter) filter.render(object, painter);
            else        object.render(painter);

            if (mask)   painter.eraseMask(mask);

            painter.popState();
        }
        
        private function renderBundled(renderBlock:Function, object:DisplayObject=null,
                                       matrix:Matrix=null, alpha:Number=1.0,
                                       antiAliasing:int=0):void
        {
            var painter:Painter = Starling.painter;
            var state:RenderState = painter.state;

            if (!Starling.current.contextValid) return;

            // switch buffers
            if (isDoubleBuffered)
            {
                var tmpTexture:Texture = _activeTexture;
                _activeTexture = _bufferTexture;
                _bufferTexture = tmpTexture;
                _helperImage.texture = _bufferTexture;
            }

            painter.pushState();

            var rootTexture:Texture = _activeTexture.root;
            state.setProjectionMatrix(0, 0, rootTexture.width, rootTexture.height, width, height);

            // limit drawing to relevant area
            sClipRect.setTo(0, 0, _activeTexture.width, _activeTexture.height);

            state.clipRect = sClipRect;
            state.setRenderTarget(_activeTexture, antiAliasing);
            painter.prepareToDraw();
            
            if (isDoubleBuffered || !isPersistent || !_bufferReady)
                painter.clear();

            // draw buffer
            if (isDoubleBuffered && _bufferReady)
                _helperImage.render(painter);
            else
                _bufferReady = true;
            
            try
            {
                _drawing = true;
                execute(renderBlock, object, matrix, alpha);
            }
            finally
            {
                _drawing = false;
                painter.popState();
            }
        }
        
        /** Clears the render texture with a certain color and alpha value. Call without any
         *  arguments to restore full transparency. */
        public function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            if (!Starling.current.contextValid) return;

            var painter:Painter = Starling.painter;
            painter.pushState();
            painter.state.renderTarget = _activeTexture;
            painter.clear(rgb, alpha);
            painter.popState();

            _bufferReady = true;
        }
        
        /** On the iPad 1 (and maybe other hardware?) clearing a non-POT RectangleTexture causes
         *  an error in the next "createVertexBuffer" call. Thus, we're forced to make this
         *  really ... elegant check here. */
        private function get supportsNonPotDimensions():Boolean
        {
            var painter:Painter = Starling.painter;
            var context:Context3D = Starling.context;
            var support:Object = painter.sharedData[CONTEXT_POT_SUPPORT_KEY];

            if (support == null)
            {
                if (painter.profile != "baselineConstrained" && "createRectangleTexture" in context)
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

                painter.sharedData[CONTEXT_POT_SUPPORT_KEY] = support;
            }

            return support;
        }

        // properties

        /** Indicates if the render texture is using double buffering. This might be necessary for
         *  persistent textures, depending on the runtime version and the value of
         *  'forceDoubleBuffering'. */
        private function get isDoubleBuffered():Boolean { return _bufferTexture != null; }

        /** Indicates if the texture is persistent over multiple draw calls. */
        public function get isPersistent():Boolean { return _isPersistent; }
        
        /** @inheritDoc */
        public override function get base():TextureBase { return _activeTexture.base; }
        
        /** @inheritDoc */
        public override function get root():ConcreteTexture { return _activeTexture.root; }
    }
}