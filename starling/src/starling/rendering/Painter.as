// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
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
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;
    import starling.utils.RenderUtil;
    import starling.utils.SystemUtil;

    /** A class that orchestrates rendering of all Starling display objects.
     *
     *  <p>A Starling instance contains exactly one 'Painter' instance that should be used for all
     *  rendering purposes. Each frame, it is passed to the render methods of all visible display
     *  objects. To access it outside a render method, call <code>Starling.current.painter</code>.
     *  </p>
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

        private var mStage3D:Stage3D;
        private var mContext:Context3D;
        private var mShareContext:Boolean;
        private var mPrograms:Dictionary;
        private var mData:Dictionary;
        private var mDrawCount:int;
        private var mFrameID:uint;
        private var mEnableErrorChecking:Boolean;
        private var mStencilReferenceValues:Dictionary;
        private var mBatchProcessor:BatchProcessor;

        private var mActualRenderTarget:TextureBase;
        private var mActualCulling:String;

        private var mBackBufferWidth:Number;
        private var mBackBufferHeight:Number;
        private var mBackBufferScaleFactor:Number;

        private var mState:RenderState;
        private var mStateStack:Vector.<RenderState>;
        private var mStateStackPos:int;

        // helper objects
        private static var sPoint3D:Vector3D = new Vector3D();
        private static var sClipRect:Rectangle = new Rectangle();
        private static var sBufferRect:Rectangle = new Rectangle();
        private static var sScissorRect:Rectangle = new Rectangle();

        // construction
        
        /** Creates a new Painter object. Normally, it's not necessary to create any custom
         *  painters; instead, use the global painter found on the Starling instance. */
        public function Painter(stage3D:Stage3D)
        {
            mStage3D = stage3D;
            mStage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 10, true);
            mContext = mStage3D.context3D;
            mShareContext = mContext && mContext.driverInfo != "Disposed";
            mBackBufferWidth  = mContext ? mContext.backBufferWidth  : 0;
            mBackBufferHeight = mContext ? mContext.backBufferHeight : 0;
            mBackBufferScaleFactor = 1.0;
            mStencilReferenceValues = new Dictionary(true);
            mPrograms = new Dictionary();
            mData = new Dictionary();

            mState = new RenderState();
            mStateStack = new <RenderState>[];
            mStateStackPos = -1;
            mBatchProcessor = new BatchProcessor();
            mBatchProcessor.onBatchComplete = renderBatch;

        }
        
        /** Disposes all quad batches, programs, and - if it is not being shared -
         *  the render context. */
        public function dispose():void
        {
            mBatchProcessor.dispose();

            if (!mShareContext)
                mContext.dispose(false);

            for each (var program:Program in mPrograms)
                program.dispose();
        }

        private function renderBatch(meshBatch:MeshBatch):void
        {
            pushState();

            state.blendMode = meshBatch.blendMode;
            state.modelviewMatrix.identity();
            state.alpha = 1.0;

            meshBatch.render(this);

            popState();
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
            RenderUtil.requestContext3D(mStage3D, renderMode, profile);
        }

        private function onContextCreated(event:Object):void
        {
            mContext = mStage3D.context3D;
            mContext.enableErrorChecking = mEnableErrorChecking;
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

            if (mContext.profile == "baselineConstrained")
                mContext.configureBackBuffer(32, 32, antiAlias, enableDepthAndStencil);

            mStage3D.x = viewPort.x;
            mStage3D.y = viewPort.y;

            mContext.configureBackBuffer(viewPort.width, viewPort.height,
                    antiAlias, enableDepthAndStencil, contentScaleFactor != 1.0);

            mBackBufferWidth  = viewPort.width;
            mBackBufferHeight = viewPort.height;
            mBackBufferScaleFactor = contentScaleFactor;
        }

        // program management

        /** Registers a program under a certain name.
         *  If the name was already used, the previous program is overwritten. */
        public function registerProgram(name:String, program:Program):void
        {
            deleteProgram(name);
            mPrograms[name] = program;
        }

        /** Deletes the program of a certain name. */
        public function deleteProgram(name:String):void
        {
            var program:Program = getProgram(name);
            if (program)
            {
                program.dispose();
                delete mPrograms[name];
            }
        }

        /** Returns the program registered under a certain name, or null if no program with
         *  this name has been registered. */
        public function getProgram(name:String):Program
        {
            if (name in mPrograms) return mPrograms[name];
            else return null;
        }

        /** Indicates if a program is registered under a certain name. */
        public function hasProgram(name:String):Boolean
        {
            return name in mPrograms;
        }

        // state stack

        /** Pushes the current render state to a stack from which it can be restored later.
         *  Optionally, you can immediately modify the new state with a transformation matrix,
         *  alpha factor, and blend mode.
         *
         *  <p>Note that any call to <code>drawTriangles</code> will use the currently set state.
         *  That means that if you're going to change clipping rectangle, render target or culling,
         *  you should call <code>finishQuadBatch</code> before pushing the new state, so that
         *  all batched objects are drawn with the intended settings.</p>
         *
         *  @param transformationMatrix Used to transform the current <code>modelviewMatrix</code>.
         *  @param alphaFactor          Multiplied with the current alpha value.
         *  @param blendMode            Replaces the current blend mode; except for "auto", which
         *                              means the current value remains unchanged.
         */
        public function pushState(transformationMatrix:Matrix=null, alphaFactor:Number=1.0,
                                  blendMode:String="auto"):void
        {
            mStateStackPos++;

            if (mStateStack.length < mStateStackPos + 1)
                mStateStack[mStateStackPos] = new RenderState();

            mStateStack[mStateStackPos].copyFrom(mState);

            if (transformationMatrix) mState.transformModelviewMatrix(transformationMatrix);
            if (alphaFactor != 1.0) mState.alpha *= alphaFactor;
            if (blendMode != BlendMode.AUTO) mState.blendMode = blendMode;
        }

        /** Restores the render state that was last pushed to the stack. If this changes
         *  clipping rectangle, render target or culling, the current batch will be drawn
         *  right away. */
        public function popState():void
        {
            if (mStateStackPos < 0)
                throw new IllegalOperationError("Cannot pop empty state stack");

            var nextState:RenderState = mStateStack[mStateStackPos];

            if (mState.switchRequiresDraw(nextState))
                finishMeshBatch();

            mState.copyFrom(nextState);
            mStateStackPos--;
        }

        // stencil masks

        /** Draws a display object into the stencil buffer, incrementing the buffer on each
         *  used pixel. The stencil reference value is incremented as well; thus, any subsequent
         *  stencil tests outside of this area will fail.
         *
         *  <p>If 'mask' is part of the display list, it will be drawn at its conventional stage
         *  coordinates. Otherwise, it will be drawn with the current modelview matrix.</p>
         */
        public function drawMask(mask:DisplayObject):void
        {
            if (mContext == null) return;

            finishMeshBatch();

            mContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);

            renderMask(mask);
            stencilReferenceValue++;

            mContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
        }

        /** Draws a display object into the stencil buffer, decrementing the
         *  buffer on each used pixel. This effectively erases the object from the stencil buffer,
         *  restoring the previous state. The stencil reference value will be decremented.
         */
        public function eraseMask(mask:DisplayObject):void
        {
            if (mContext == null) return;

            finishMeshBatch();

            mContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.DECREMENT_SATURATE);

            renderMask(mask);
            stencilReferenceValue--;

            mContext.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
        }

        private function renderMask(mask:DisplayObject):void
        {
            pushState();
            mState.alpha = 0.0;

            if (mask.stage)
                mask.getTransformationMatrix(null, mState.modelviewMatrix);
            else
                mState.transformModelviewMatrix(mask.transformationMatrix);

            mask.render(this);
            finishMeshBatch();

            popState();
        }

        // mesh rendering
        
        /** Adds a mesh to the current batch of unrendered meshes. If the current batch is not
         *  compatible with the mesh, all previous meshes are rendered at once and the batch
         *  is cleared.
         *
         *  @param mesh        the mesh to add to the current (or new) batch.
         *  @param batchClass  the class that should be used to batch/render the mesh;
         *                     must implement <code>IMeshBatch</code>.
         */
        public function batchMesh(mesh:Mesh, batchClass:Class):void
        {
            mBatchProcessor.addMesh(mesh, batchClass,
                    mState.modelviewMatrix, mState.alpha, mState.blendMode);
        }

        /** Finishes the current mesh batch and prepares the next one. */
        public function finishMeshBatch():void
        {
            mBatchProcessor.finishBatch();
        }

        public function finishFrame():void
        {
            if (mFrameID % 60 == 0)
                mBatchProcessor.trim();

            mBatchProcessor.finishBatch();
            mBatchProcessor.clear();
        }

        /** Resets the current state, the state stack, mesh batch index, stencil reference value,
         *  and draw count. Furthermore, depth testing is disabled. */
        public function nextFrame():void
        {
            stencilReferenceValue = 0;
            mFrameID++;
            mDrawCount = 0;
            mStateStackPos = -1;
            mContext.setDepthTest(false, Context3DCompareMode.ALWAYS);
            mState.reset();
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
            mState.renderTarget = null;
            mActualRenderTarget = null;
            mContext.present();
        }

        private function applyBlendMode():void
        {
            BlendMode.get(mState.blendMode).activate();
        }

        private function applyCulling():void
        {
            var culling:String = mState.culling;

            if (culling != mActualCulling)
            {
                mContext.setCulling(culling);
                mActualCulling = culling;
            }
        }

        private function applyRenderTarget():void
        {
            var target:TextureBase = mState.renderTargetBase;
            var antiAlias:int  = mState.renderTargetAntiAlias;

            if (target != mActualRenderTarget)
            {
                if (target)
                    mContext.setRenderToTexture(target, SystemUtil.supportsDepthAndStencil, antiAlias);
                else
                    mContext.setRenderToBackBuffer();

                mContext.setStencilReferenceValue(stencilReferenceValue);
                mActualRenderTarget = target;
            }
        }

        private function applyClipRect():void
        {
            var clipRect:Rectangle = mState.clipRect;

            if (clipRect)
            {
                var width:int, height:int;
                var projMatrix:Matrix3D = mState.projectionMatrix3D;
                var renderTarget:Texture = mState.renderTarget;

                if (renderTarget)
                {
                    width  = renderTarget.root.nativeWidth;
                    height = renderTarget.root.nativeHeight;
                }
                else
                {
                    width  = mBackBufferWidth;
                    height = mBackBufferHeight;
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

                mContext.setScissorRectangle(sScissorRect);
            }
            else
            {
                mContext.setScissorRectangle(null);
            }
        }

        // properties
        
        /** Indicates the number of stage3D draw calls. */
        public function get drawCount():int { return mDrawCount; }
        public function set drawCount(value:int):void { mDrawCount = value; }

        /** The current stencil reference value of the active render target. This value
         *  is typically incremented when drawing a mask and decrementing when erasing it.
         *  The painter keeps track of one stencil reference value per render target.
         *  Only change this value if you know what you're doing!
         */
        public function get stencilReferenceValue():uint
        {
            var key:Object = mState.renderTarget ? mState.renderTargetBase : this;
            if (key in mStencilReferenceValues) return mStencilReferenceValues[key];
            else return 0;
        }

        public function set stencilReferenceValue(value:uint):void
        {
            var key:Object = mState.renderTarget ? mState.renderTargetBase : this;
            mStencilReferenceValues[key] = value;

            if (contextValid)
                mContext.setStencilReferenceValue(value);
        }

        /** The current render state, containing some of the context settings, projection- and
         *  modelview-matrix, etc. Always returns the same instance, even after calls to "pushState"
         *  and "popState".
         */
        public function get state():RenderState { return mState; }

        /** The Stage3D instance this painter renders into. */
        public function get stage3D():Stage3D { return mStage3D; }

        /** The Context3D instance this painter renders into. */
        public function get context():Context3D { return mContext; }

        /** Indicates if another Starling instance (or another Stage3D framework altogether)
         *  uses the same render context. @default false */
        public function get shareContext():Boolean { return mShareContext; }
        public function set shareContext(value:Boolean):void { mShareContext = value; }

        /** Indicates if Stage3D render methods will report errors. Activate only when needed,
         *  as this has a negative impact on performance. @default false */
        public function get enableErrorChecking():Boolean { return mEnableErrorChecking; }
        public function set enableErrorChecking(value:Boolean):void
        {
            mEnableErrorChecking = value;
            if (mContext) mContext.enableErrorChecking = value;
        }

        /** Returns the current width of the back buffer. In most cases, this value is in pixels;
         *  however, if the app is running on an HiDPI display with an activated
         *  'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
         *  for the actual pixel count. Alternatively, use the Context3D-property with the
         *  same name: it will return the exact pixel values. */
        public function get backBufferWidth():int { return mBackBufferWidth; }

        /** Returns the current height of the back buffer. In most cases, this value is in pixels;
         *  however, if the app is running on an HiDPI display with an activated
         *  'supportHighResolutions' setting, you have to multiply with 'backBufferPixelsPerPoint'
         *  for the actual pixel count. Alternatively, use the Context3D-property with the
         *  same name: it will return the exact pixel values. */
        public function get backBufferHeight():int { return mBackBufferHeight; }

        /** The number of pixels per point returned by the 'backBufferWidth/Height' properties.
         *  Except for desktop HiDPI displays with an activated 'supportHighResolutions' setting,
         *  this will always return '1'. */
        public function get backBufferScaleFactor():Number { return mBackBufferScaleFactor; }

        /** Indicates if the Context3D object is currently valid (i.e. it hasn't been lost or
         *  disposed). */
        public function get contextValid():Boolean
        {
            if (mContext)
            {
                const driverInfo:String = mContext.driverInfo;
                return driverInfo != null && driverInfo != "" && driverInfo != "Disposed";
            }
            else return false;
        }

        /** The Context3D profile of the current render context, or <code>null</code>
         *  if the context has not been created yet. */
        public function get profile():String
        {
            if (mContext) return mContext.profile;
            else return null;
        }

        /** A dictionary that can be used to save custom data related to the render context.
         *  If you need to share data that is bound to the render context (e.g. textures),
         *  use this dictionary instead of creating a static class variable.
         *  That way, the data will be available for all Starling instances that use this
         *  painter / stage3D / context. */
        public function get sharedData():Dictionary { return mData; }
    }
}