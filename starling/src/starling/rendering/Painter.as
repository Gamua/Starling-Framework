// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering
{
    import flash.display.Stage3D;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DStencilAction;
    import flash.display3D.Context3DTriangleFace;
    import flash.display3D.textures.TextureBase;
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    import flash.utils.Dictionary;

    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Mesh;
    import starling.display.MeshBatch;
    import starling.display.Quad;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.MathUtil;
    import starling.utils.MatrixUtil;
    import starling.utils.MeshSubset;
    import starling.utils.Pool;
    import starling.utils.RectangleUtil;
    import starling.utils.RenderUtil;
    import starling.utils.SystemUtil;

    /** A class that orchestrates rendering of all Starling display objects.
     *
     *  <p>A Starling instance contains exactly one 'Painter' instance that should be used for all
     *  rendering purposes. Each frame, it is passed to the render methods of all rendered display
     *  objects. To access it outside a render method, call <code>Starling.painter</code>.</p>
     *
     *  <p>The painter is responsible for drawing all display objects to the screen. At its
     *  core, it is a wrapper for many Context3D methods, but that's not all: it also provides
     *  a convenient state mechanism, supports masking and acts as middleman between display
     *  objects and renderers.</p>
     *
     *  <strong>The State Stack</strong>
     *
     *  <p>The most important concept of the Painter class is the state stack. A RenderState
     *  stores a combination of settings that are currently used for rendering, e.g. the current
     *  projection- and modelview-matrices and context-related settings. It can be accessed
     *  and manipulated via the <code>state</code> property. Use the methods
     *  <code>pushState</code> and <code>popState</code> to store a specific state and restore
     *  it later. That makes it easy to write rendering code that doesn't have any side effects.</p>
     *
     *  <listing>
     *  painter.pushState(); // save a copy of the current state on the stack
     *  painter.state.renderTarget = renderTexture;
     *  painter.state.transformModelviewMatrix(object.transformationMatrix);
     *  painter.state.alpha = 0.5;
     *  painter.prepareToDraw(); // apply all state settings at the render context
     *  drawSomething(); // insert Stage3D rendering code here
     *  painter.popState(); // restores previous state</listing>
     *
     *  @see RenderState
     */
    public class Painter
    {
        // members

        private var _stage3D:Stage3D;
        private var _context:Context3D;
        private var _shareContext:Boolean;
        private var _programs:Dictionary;
        private var _data:Dictionary;
        private var _drawCount:int;
        private var _frameID:uint;
        private var _pixelSize:Number;
        private var _enableErrorChecking:Boolean;
        private var _stencilReferenceValues:Dictionary;
        private var _clipRectStack:Vector.<Rectangle>;
        private var _batchProcessor:BatchProcessor;
        private var _batchCache:BatchProcessor;

        private var _actualRenderTarget:TextureBase;
        private var _actualCulling:String;
        private var _actualBlendMode:String;

        private var _backBufferWidth:Number;
        private var _backBufferHeight:Number;
        private var _backBufferScaleFactor:Number;

        private var _state:RenderState;
        private var _stateStack:Vector.<RenderState>;
        private var _stateStackPos:int;

        // helper objects
        private static var sMatrix:Matrix = new Matrix();
        private static var sPoint3D:Vector3D = new Vector3D();
        private static var sClipRect:Rectangle = new Rectangle();
        private static var sBufferRect:Rectangle = new Rectangle();
        private static var sScissorRect:Rectangle = new Rectangle();
        private static var sMeshSubset:MeshSubset = new MeshSubset();

        // construction
        
        /** Creates a new Painter object. Normally, it's not necessary to create any custom
         *  painters; instead, use the global painter found on the Starling instance. */
        public function Painter(stage3D:Stage3D)
        {
            _stage3D = stage3D;
            _stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 10, true);
            _context = _stage3D.context3D;
            _shareContext = _context && _context.driverInfo != "Disposed";
            _backBufferWidth  = _context ? _context.backBufferWidth  : 0;
            _backBufferHeight = _context ? _context.backBufferHeight : 0;
            _backBufferScaleFactor = _pixelSize = 1.0;
            _stencilReferenceValues = new Dictionary(true);
            _clipRectStack = new <Rectangle>[];
            _programs = new Dictionary();
            _data = new Dictionary();

            _batchProcessor = new BatchProcessor();
            _batchProcessor.onBatchComplete = drawBatch;

            _batchCache = new BatchProcessor();
            _batchCache.onBatchComplete = drawBatch;

            _state = new RenderState();
            _state.onDrawRequired = finishMeshBatch;
            _stateStack = new <RenderState>[];
            _stateStackPos = -1;
        }
        
        /** Disposes all quad batches, programs, and - if it is not being shared -
         *  the render context. */
        public function dispose():void
        {
            _batchProcessor.dispose();
            _batchCache.dispose();

            if (!_shareContext)
                _context.dispose(false);

            for each (var program:Program in _programs)
                program.dispose();
        }

        // context handling

        /** Requests a context3D object from the stage3D object.
         *  This is called by Starling internally during the initialization process.
         *  You normally don't need to call this method yourself. (For a detailed description
         *  of the parameters, look at the documentation of the method with the same name in the
         *  "RenderUtil" class.)
         *
         *  @see starling.utils.RenderUtil
         */
        public function requestContext3D(renderMode:String, profile:*):void
        {
            RenderUtil.requestContext3D(_stage3D, renderMode, profile);
        }

        private function onContextCreated(event:Object):void
        {
            _context = _stage3D.context3D;
            _context.enableErrorChecking = _enableErrorChecking;
            _actualBlendMode = null;
            _actualCulling = null;
        }

        /** Sets the viewport dimensions and other attributes of the rendering buffer.
         *  Starling will call this method internally, so most apps won't need to mess with this.
         *
         * @param viewPort                the position and size of the area that should be rendered
         *                                into, in pixels.
         * @param contentScaleFactor      only relevant for Desktop (!) HiDPI screens. If you want
         *                                to support high resolutions, pass the 'contentScaleFactor'
         *                                of the Flash stage; otherwise, '1.0'.
         * @param antiAlias               from 0 (none) to 16 (very high quality).
         * @param enableDepthAndStencil   indicates whether the depth and stencil buffers should
         *                                be enabled. Note that on AIR, you also have to enable
         *                                this setting in the app-xml (application descriptor);
         *                                otherwise, this setting will be silently ignored.
         */
        public function configureBackBuffer(viewPort:Rectangle, contentScaleFactor:Number,
                                            antiAlias:int, enableDepthAndStencil:Boolean):void
        {
            enableDepthAndStencil &&= SystemUtil.supportsDepthAndStencil;

            // Changing the stage3D position might move the back buffer to invalid bounds
            // temporarily. To avoid problems, we set it to the smallest possible size first.

            if (_context.profile == "baselineConstrained")
                _context.configureBackBuffer(32, 32, antiAlias, enableDepthAndStencil);

            _stage3D.x = viewPort.x;
            _stage3D.y = viewPort.y;

            _context.configureBackBuffer(viewPort.width, viewPort.height,
                    antiAlias, enableDepthAndStencil, contentScaleFactor != 1.0);

            _backBufferWidth  = viewPort.width;
            _backBufferHeight = viewPort.height;
            _backBufferScaleFactor = contentScaleFactor;
        }

        // program management

        /** Registers a program under a certain name.
         *  If the name was already used, the previous program is overwritten. */
        public function registerProgram(name:String, program:Program):void
        {
            deleteProgram(name);
            _programs[name] = program;
        }

        /** Deletes the program of a certain name. */
        public function deleteProgram(name:String):void
        {
            var program:Program = getProgram(name);
            if (program)
            {
                program.dispose();
                delete _programs[name];
            }
        }

        /** Returns the program registered under a certain name, or null if no program with
         *  this name has been registered. */
        public function getProgram(name:String):Program
        {
            if (name in _programs) return _programs[name];
            else return null;
        }

        /** Indicates if a program is registered under a certain name. */
        public function hasProgram(name:String):Boolean
        {
            return name in _programs;
        }

        // state stack

        /** Pushes the current render state to a stack from which it can be restored later.
         *
         *  <p>If you pass a BatchToken, it will be updated to point to the current location within
         *  the render cache. That way, you can later reference this location to render a subset of
         *  the cache.</p>
         */
        public function pushState(token:BatchToken=null):void
        {
            _stateStackPos++;

            if (_stateStack.length < _stateStackPos + 1) _stateStack[_stateStackPos] = new RenderState();
            if (token) _batchProcessor.fillToken(token);

            _stateStack[_stateStackPos].copyFrom(_state);
        }

        /** Modifies the current state with a transformation matrix, alpha factor, and blend mode.
         *
         *  @param transformationMatrix Used to transform the current <code>modelviewMatrix</code>.
         *  @param alphaFactor          Multiplied with the current alpha value.
         *  @param blendMode            Replaces the current blend mode; except for "auto", which
         *                              means the current value remains unchanged.
         */
        public function setStateTo(transformationMatrix:Matrix, alphaFactor:Number=1.0,
                                   blendMode:String="auto"):void
        {
            if (transformationMatrix) _state.transformModelviewMatrix(transformationMatrix);
            if (alphaFactor != 1.0) _state.alpha *= alphaFactor;
            if (blendMode != BlendMode.AUTO) _state.blendMode = blendMode;
        }

        /** Restores the render state that was last pushed to the stack. If this changes
         *  blend mode, clipping rectangle, render target or culling, the current batch
         *  will be drawn right away.
         *
         *  <p>If you pass a BatchToken, it will be updated to point to the current location within
         *  the render cache. That way, you can later reference this location to render a subset of
         *  the cache.</p>
         */
        public function popState(token:BatchToken=null):void
        {
            if (_stateStackPos < 0)
                throw new IllegalOperationError("Cannot pop empty state stack");

            _state.copyFrom(_stateStack[_stateStackPos]); // -> might cause 'finishMeshBatch'
            _stateStackPos--;

            if (token) _batchProcessor.fillToken(token);
        }

        // masks

        /** Draws a display object into the stencil buffer, incrementing the buffer on each
         *  used pixel. The stencil reference value is incremented as well; thus, any subsequent
         *  stencil tests outside of this area will fail.
         *
         *  <p>If 'mask' is part of the display list, it will be drawn at its conventional stage
         *  coordinates. Otherwise, it will be drawn with the current modelview matrix.</p>
         *
         *  <p>As an optimization, this method might update the clipping rectangle of the render
         *  state instead of utilizing the stencil buffer. This is possible when the mask object
         *  is of type <code>starling.display.Quad</code> and is aligned parallel to the stage
         *  axes.</p>
         */
        public function drawMask(mask:DisplayObject):void
        {
            if (_context == null) return;

            finishMeshBatch();

            if (isRectangularMask(mask, sMatrix))
            {
                mask.getBounds(mask, sClipRect);
                RectangleUtil.getBounds(sClipRect, sMatrix, sClipRect);
                pushClipRect(sClipRect);
            }
            else
            {
                _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);

                renderMask(mask);
                stencilReferenceValue++;

                _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
            }
        }

        /** Draws a display object into the stencil buffer, decrementing the
         *  buffer on each used pixel. This effectively erases the object from the stencil buffer,
         *  restoring the previous state. The stencil reference value will be decremented.
         *
         *  <p>Note: if the mask object meets the requirements of using the clipping rectangle,
         *  it will be assumed that this erase operation undoes the clipping rectangle change
         *  caused by the corresponding <code>drawMask()</code> call.</p>
         */
        public function eraseMask(mask:DisplayObject):void
        {
            if (_context == null) return;

            finishMeshBatch();

            if (isRectangularMask(mask, sMatrix))
            {
                popClipRect();
            }
            else
            {
                _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.DECREMENT_SATURATE);

                renderMask(mask);
                stencilReferenceValue--;

                _context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
            }
        }

        private function renderMask(mask:DisplayObject):void
        {
            pushState();
            _state.alpha = 0.0;

            if (mask.stage)
                mask.getTransformationMatrix(null, _state.modelviewMatrix);
            else
                _state.transformModelviewMatrix(mask.transformationMatrix);

            mask.render(this);
            finishMeshBatch();

            popState();
        }

        private function pushClipRect(clipRect:Rectangle):void
        {
            var stack:Vector.<Rectangle> = _clipRectStack;
            var stackLength:uint = stack.length;
            var intersection:Rectangle = Pool.getRectangle();

            if (stackLength)
                RectangleUtil.intersect(stack[stackLength - 1], clipRect, intersection);
            else
                intersection.copyFrom(clipRect);

            stack[stackLength] = intersection;
            _state.clipRect = intersection;
        }

        private function popClipRect():void
        {
            var stack:Vector.<Rectangle> = _clipRectStack;
            var stackLength:uint = stack.length;

            if (stackLength == 0)
                throw new Error("Trying to pop from empty clip rectangle stack");

            stackLength--;
            Pool.putRectangle(stack.pop());
            _state.clipRect = stackLength ? stack[stackLength - 1] : null;
        }

        /** Figures out if the mask can be represented by a scissor rectangle; this is possible
         *  if it's just a simple quad that is parallel to the stage axes. The 'out' parameter
         *  will be filled with the transformation matrix required to move the mask into stage
         *  coordinates. */
        private function isRectangularMask(mask:DisplayObject, out:Matrix):Boolean
        {
            var quad:Quad = mask as Quad;
            if (quad && !quad.is3D && quad.style.type == MeshStyle)
            {
                if (mask.stage) mask.getTransformationMatrix(null, out);
                else
                {
                    out.copyFrom(mask.transformationMatrix);
                    out.concat(_state.modelviewMatrix);
                }

                return (MathUtil.isEquivalent(out.a, 0) && MathUtil.isEquivalent(out.d, 0)) ||
                       (MathUtil.isEquivalent(out.b, 0) && MathUtil.isEquivalent(out.c, 0));
            }
            return false;
        }

        // mesh rendering
        
        /** Adds a mesh to the current batch of unrendered meshes. If the current batch is not
         *  compatible with the mesh, all previous meshes are rendered at once and the batch
         *  is cleared.
         *
         *  @param mesh    The mesh to batch.
         *  @param subset  The range of vertices to be batched. If <code>null</code>, the complete
         *                 mesh will be used.
         */
        public function batchMesh(mesh:Mesh, subset:MeshSubset=null):void
        {
            _batchProcessor.addMesh(mesh, _state, subset);
        }

        /** Finishes the current mesh batch and prepares the next one. */
        public function finishMeshBatch():void
        {
            _batchProcessor.finishBatch();
        }

        /** Completes all unfinished batches, cleanup procedures. */
        public function finishFrame():void
        {
            if (_frameID % 99 == 0) // odd number -> alternating processors
                _batchProcessor.trim();

            _batchProcessor.finishBatch();
            swapBatchProcessors();
            _batchProcessor.clear();
        }

        private function swapBatchProcessors():void
        {
            var tmp:BatchProcessor = _batchProcessor;
            _batchProcessor = _batchCache;
            _batchCache = tmp;
        }

        /** Resets the current state, state stack, batch processor, stencil reference value,
         *  clipping rectangle, and draw count. Furthermore, depth testing is disabled. */
        public function nextFrame():void
        {
            stencilReferenceValue = 0;
            _clipRectStack.length = 0;
            _drawCount = 0;
            _stateStackPos = -1;
            _batchProcessor.clear();
            _context.setDepthTest(false, Context3DCompareMode.ALWAYS);
            _state.reset();
        }

        /** Draws all meshes from the render cache between <code>startToken</code> and
         *  (but not including) <code>endToken</code>. The render cache contains all meshes
         *  rendered in the previous frame. */
        public function drawFromCache(startToken:BatchToken, endToken:BatchToken):void
        {
            var meshBatch:MeshBatch;
            var subset:MeshSubset = sMeshSubset;

            if (!startToken.equals(endToken))
            {
                pushState();

                for (var i:int = startToken.batchID; i <= endToken.batchID; ++i)
                {
                    meshBatch = _batchCache.getBatchAt(i);
                    subset.setTo(); // resets subset

                    if (i == startToken.batchID)
                    {
                        subset.vertexID = startToken.vertexID;
                        subset.indexID  = startToken.indexID;
                        subset.numVertices = meshBatch.numVertices - subset.vertexID;
                        subset.numIndices  = meshBatch.numIndices  - subset.indexID;
                    }

                    if (i == endToken.batchID)
                    {
                        subset.numVertices = endToken.vertexID - subset.vertexID;
                        subset.numIndices  = endToken.indexID  - subset.indexID;
                    }

                    if (subset.numVertices)
                    {
                        setStateTo(null, 1.0, meshBatch.blendMode);
                        _batchProcessor.addMesh(meshBatch, _state, subset, true);
                    }
                }

                popState();
            }
        }

        /** Removes all parts of the render cache past the given token. Beware that some display
         *  objects might still reference those parts of the cache! Only call it if you know
         *  exactly what you're doing. */
        public function rewindCacheTo(token:BatchToken):void
        {
            _batchProcessor.rewindTo(token);
        }

        private function drawBatch(meshBatch:MeshBatch):void
        {
            pushState();

            state.blendMode = meshBatch.blendMode;
            state.modelviewMatrix.identity();
            state.alpha = 1.0;

            meshBatch.render(this);

            popState();
        }

        // helper methods

        /** Applies all relevant state settings to at the render context. This includes
         *  blend mode, render target and clipping rectangle. Always call this method before
         *  <code>context.drawTriangles()</code>.
         */
        public function prepareToDraw():void
        {
            applyBlendMode();
            applyRenderTarget();
            applyClipRect();
            applyCulling();
        }

        /** Clears the render context with a certain color and alpha value. Since this also
         *  clears the stencil buffer, the stencil reference value is also reset to '0'. */
        public function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            applyRenderTarget();
            stencilReferenceValue = 0;
            RenderUtil.clear(rgb, alpha);
        }

        /** Resets the render target to the back buffer and displays its contents. */
        public function present():void
        {
            _state.renderTarget = null;
            _actualRenderTarget = null;
            _context.present();
        }

        private function applyBlendMode():void
        {
            var blendMode:String = _state.blendMode;

            if (blendMode != _actualBlendMode)
            {
                BlendMode.get(_state.blendMode).activate();
                _actualBlendMode = blendMode;
            }
        }

        private function applyCulling():void
        {
            var culling:String = _state.culling;

            if (culling != _actualCulling)
            {
                _context.setCulling(culling);
                _actualCulling = culling;
            }
        }

        private function applyRenderTarget():void
        {
            var target:TextureBase = _state.renderTargetBase;

            if (target != _actualRenderTarget)
            {
                if (target)
                {
                    var antiAlias:int  = _state.renderTargetAntiAlias;
                    var depthAndStencil:Boolean = _state.renderTargetSupportsDepthAndStencil;
                    _context.setRenderToTexture(target, depthAndStencil, antiAlias);
                }
                else
                    _context.setRenderToBackBuffer();

                _context.setStencilReferenceValue(stencilReferenceValue);
                _actualRenderTarget = target;
            }
        }

        private function applyClipRect():void
        {
            var clipRect:Rectangle = _state.clipRect;

            if (clipRect)
            {
                var width:int, height:int;
                var projMatrix:Matrix3D = _state.projectionMatrix3D;
                var renderTarget:Texture = _state.renderTarget;

                if (renderTarget)
                {
                    width  = renderTarget.root.nativeWidth;
                    height = renderTarget.root.nativeHeight;
                }
                else
                {
                    width  = _backBufferWidth;
                    height = _backBufferHeight;
                }

                // convert to pixel coordinates (matrix transformation ends up in range [-1, 1])
                MatrixUtil.transformCoords3D(projMatrix, clipRect.x, clipRect.y, 0.0, sPoint3D);
                sPoint3D.project(); // eliminate w-coordinate
                sClipRect.x = (sPoint3D.x * 0.5 + 0.5) * width;
                sClipRect.y = (0.5 - sPoint3D.y * 0.5) * height;

                MatrixUtil.transformCoords3D(projMatrix, clipRect.right, clipRect.bottom, 0.0, sPoint3D);
                sPoint3D.project(); // eliminate w-coordinate
                sClipRect.right  = (sPoint3D.x * 0.5 + 0.5) * width;
                sClipRect.bottom = (0.5 - sPoint3D.y * 0.5) * height;

                sBufferRect.setTo(0, 0, width, height);
                RectangleUtil.intersect(sClipRect, sBufferRect, sScissorRect);

                // an empty rectangle is not allowed, so we set it to the smallest possible size
                if (sScissorRect.width < 1 || sScissorRect.height < 1)
                    sScissorRect.setTo(0, 0, 1, 1);

                _context.setScissorRectangle(sScissorRect);
            }
            else
            {
                _context.setScissorRectangle(null);
            }
        }

        // properties
        
        /** Indicates the number of stage3D draw calls. */
        public function get drawCount():int { return _drawCount; }
        public function set drawCount(value:int):void { _drawCount = value; }

        /** The current stencil reference value of the active render target. This value
         *  is typically incremented when drawing a mask and decrementing when erasing it.
         *  The painter keeps track of one stencil reference value per render target.
         *  Only change this value if you know what you're doing!
         */
        public function get stencilReferenceValue():uint
        {
            var key:Object = _state.renderTarget ? _state.renderTargetBase : this;
            if (key in _stencilReferenceValues) return _stencilReferenceValues[key];
            else return 0;
        }

        public function set stencilReferenceValue(value:uint):void
        {
            var key:Object = _state.renderTarget ? _state.renderTargetBase : this;
            _stencilReferenceValues[key] = value;

            if (contextValid)
                _context.setStencilReferenceValue(value);
        }

        /** The current render state, containing some of the context settings, projection- and
         *  modelview-matrix, etc. Always returns the same instance, even after calls to "pushState"
         *  and "popState".
         *
         *  <p>When you change the current RenderState, and this change is not compatible with
         *  the current render batch, the batch will be concluded right away. Thus, watch out
         *  for changes of blend mode, clipping rectangle, render target or culling.</p>
         */
        public function get state():RenderState { return _state; }

        /** The Stage3D instance this painter renders into. */
        public function get stage3D():Stage3D { return _stage3D; }

        /** The Context3D instance this painter renders into. */
        public function get context():Context3D { return _context; }

        /** The number of frames that have been rendered with the current Starling instance. */
        public function get frameID():uint { return _frameID; }
        public function set frameID(value:uint):void { _frameID = value; }

        /** The size (in points) that represents one pixel in the back buffer. */
        public function get pixelSize():Number { return _pixelSize; }
        public function set pixelSize(value:Number):void { _pixelSize = value; }

        /** Indicates if another Starling instance (or another Stage3D framework altogether)
         *  uses the same render context. @default false */
        public function get shareContext():Boolean { return _shareContext; }
        public function set shareContext(value:Boolean):void { _shareContext = value; }

        /** Indicates if Stage3D render methods will report errors. Activate only when needed,
         *  as this has a negative impact on performance. @default false */
        public function get enableErrorChecking():Boolean { return _enableErrorChecking; }
        public function set enableErrorChecking(value:Boolean):void
        {
            _enableErrorChecking = value;
            if (_context) _context.enableErrorChecking = value;
        }

        /** Returns the current width of the back buffer. In most cases, this value is in pixels;
         *  however, if the app is running on an HiDPI display with an activated
         *  'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
         *  for the actual pixel count. Alternatively, use the Context3D-property with the
         *  same name: it will return the exact pixel values. */
        public function get backBufferWidth():int { return _backBufferWidth; }

        /** Returns the current height of the back buffer. In most cases, this value is in pixels;
         *  however, if the app is running on an HiDPI display with an activated
         *  'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
         *  for the actual pixel count. Alternatively, use the Context3D-property with the
         *  same name: it will return the exact pixel values. */
        public function get backBufferHeight():int { return _backBufferHeight; }

        /** The number of pixels per point returned by the 'backBufferWidth/Height' properties.
         *  Except for desktop HiDPI displays with an activated 'supportHighResolutions' setting,
         *  this will always return '1'. */
        public function get backBufferScaleFactor():Number { return _backBufferScaleFactor; }

        /** Indicates if the Context3D object is currently valid (i.e. it hasn't been lost or
         *  disposed). */
        public function get contextValid():Boolean
        {
            if (_context)
            {
                const driverInfo:String = _context.driverInfo;
                return driverInfo != null && driverInfo != "" && driverInfo != "Disposed";
            }
            else return false;
        }

        /** The Context3D profile of the current render context, or <code>null</code>
         *  if the context has not been created yet. */
        public function get profile():String
        {
            if (_context) return _context.profile;
            else return null;
        }

        /** A dictionary that can be used to save custom data related to the render context.
         *  If you need to share data that is bound to the render context (e.g. textures),
         *  use this dictionary instead of creating a static class variable.
         *  That way, the data will be available for all Starling instances that use this
         *  painter / stage3D / context. */
        public function get sharedData():Dictionary { return _data; }
    }
}