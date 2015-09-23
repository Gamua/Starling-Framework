// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DStencilAction;
    import flash.display3D.Context3DTriangleFace;
    import flash.display3D.textures.TextureBase;
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.textures.Texture;
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;
    import starling.utils.RenderUtil;
    import starling.utils.SystemUtil;

    /** A class that orchestrates rendering of all Starling display objects.
     *
     *  <p>A Starling instance contains exactly one 'Painter' instance that should be used for all
     *  rendering purposes. Each frame, it is passed to the render methods of all visible display
     *  objects.</p>
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

        private var mDrawCount:int;
        private var mStencilReferenceValues:Dictionary;
        private var mActualRenderTarget:TextureBase;
        private var mActualCulling:String;

        private var mState:RenderState;
        private var mStateStack:Vector.<RenderState>;
        private var mStateStackPos:int;

        private var mQuadBatch:QuadBatch;
        private var mQuadBatchList:Vector.<QuadBatch>;
        private var mQuadBatchListPos:int;

        // helper objects
        private static var sPoint:Point = new Point();
        private static var sClipRect:Rectangle = new Rectangle();
        private static var sBufferRect:Rectangle = new Rectangle();
        private static var sScissorRect:Rectangle = new Rectangle();
        private static var sMatrix:Matrix = new Matrix();
        private static var sMatrix3D:Matrix3D = new Matrix3D();

        // construction
        
        /** Creates a new Painter object. */
        public function Painter()
        {
            mState = new RenderState();
            mStateStack = new <RenderState>[];
            mStateStackPos = -1;

            mQuadBatch = createQuadBatch();
            mQuadBatchList = new <QuadBatch>[mQuadBatch];
            mQuadBatchListPos = 0;

            mStencilReferenceValues = new Dictionary(true);

            // todo make sure there's only one state (or painter?) per context
        }
        
        /** Disposes all quad batches. */
        public function dispose():void
        {
            for each (var quadBatch:QuadBatch in mQuadBatchList)
                quadBatch.dispose();
        }
        
        // state stack

        /** Pushes the current render state to a stack from which it can be restored later.
         *  Optionally, you can immediately modify the new state with a transformation matrix,
         *  alpha factor, and blend mode.
         *
         * @param transformationMatrix Used to transform the current <code>modelviewMatrix</code>.
         * @param alphaFactor          Multiplied with the current alpha value.
         * @param blendMode            Replaces the current blend mode; except for "auto", which
         *                             means the current value remains unchanged.
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

        /** Restores the render state that was last pushed to the stack. */
        public function popState():void
        {
            if (mStateStackPos < 0)
                throw new IllegalOperationError("Cannot pop empty state stack");

            mState.copyFrom(mStateStack[mStateStackPos]);
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
            var context:Context3D = Starling.context;
            if (context == null) return;

            finishQuadBatch();

            context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);

            renderMask(mask);
            stencilReferenceValue++;

            context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
        }

        /** Draws a display object into the stencil buffer, decrementing the
         *  buffer on each used pixel. This effectively erases the object from the stencil buffer,
         *  restoring the previous state. The stencil reference value will be decremented.
         */
        public function eraseMask(mask:DisplayObject):void
        {
            var context:Context3D = Starling.context;
            if (context == null) return;

            finishQuadBatch();

            context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
                    Context3DCompareMode.EQUAL, Context3DStencilAction.DECREMENT_SATURATE);

            renderMask(mask);
            stencilReferenceValue--;

            context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
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
            finishQuadBatch();

            popState();
        }

        // quad rendering
        
        /** Adds a quad to the current batch of unrendered quads. If there is a state change,
         *  all previous quads are rendered at once, and the batch is reset. */
        public function batchQuad(quad:Quad, texture:Texture=null, smoothing:String=null):void
        {
            var alpha:Number = mState.alpha;
            var blendMode:String = mState.blendMode;
            var modelviewMatrix:Matrix = mState.modelviewMatrix;

            if (mQuadBatch.isStateChange(quad.tinted, alpha, texture, smoothing, blendMode))
                finishQuadBatch();

            mQuadBatch.addQuad(quad, alpha, texture, smoothing, modelviewMatrix, blendMode);
        }
        
        /** Adds a batch of quads to the current batch of unrendered quads. If there is a state
         *  change, all previous quads are rendered at once. 
         *
         *  <p>Note that copying the contents of the QuadBatch to the current "cumulative"
         *  batch takes some time. If the batch consists of more than just a few quads,
         *  you may be better off calling the "render(Custom)" method on the batch instead.
         *  Otherwise, the additional CPU effort will be more expensive than what you save by
         *  avoiding the draw call. (Rule of thumb: no more than 16-20 quads.)</p> */
        public function batchQuadBatch(quadBatch:QuadBatch):void
        {
            var alpha:Number = mState.alpha;
            var blendMode:String = mState.blendMode;
            var modelviewMatrix:Matrix = mState.modelviewMatrix;

            if (mQuadBatch.isStateChange(
                    quadBatch.tinted, alpha, quadBatch.texture, quadBatch.smoothing,
                    blendMode, quadBatch.numQuads))
            {
                finishQuadBatch();
            }
            
            mQuadBatch.addQuadBatch(quadBatch, alpha, modelviewMatrix, blendMode);
        }
        
        /** Renders the current quad batch and resets it. */
        public function finishQuadBatch():void
        {
            if (mQuadBatch.numQuads != 0)
            {
                sMatrix3D.copyFrom(mState.projectionMatrix3D);

                if (mState.is3D)
                    sMatrix3D.prepend(mState.modelviewMatrix3D);

                // TODO this should move to the batch object's "render" method
                prepareToDraw(mQuadBatch.premultipliedAlpha);

                mQuadBatch.renderCustom(sMatrix3D);
                mQuadBatch.reset();

                mQuadBatchListPos++;
                mDrawCount++;

                if (mQuadBatchList.length < mQuadBatchListPos + 1)
                    mQuadBatchList[mQuadBatchListPos] = createQuadBatch();

                mQuadBatch = mQuadBatchList[mQuadBatchListPos];
            }
        }
        
        /** Resets the current state, the state stack, quad batch index, stencil reference value,
         *  and draw count. */
        public function nextFrame():void
        {
            trimQuadBatches();
            stencilReferenceValue = 0;

            mState.reset();
            mDrawCount = 0;
            mStateStackPos = -1;
            mQuadBatchListPos = 0;
            mQuadBatch = mQuadBatchList[0];
        }

        // helper methods

        /** Applies all relevant state settings to at the render context. This includes
         *  blend mode, render target and clipping rectangle. Always call this method before
         *  <code>context.drawTriangles()</code>.
         */
        public function prepareToDraw(premultipliedAlpha:Boolean):void
        {
            applyBlendMode(premultipliedAlpha);
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

        private static function createQuadBatch():QuadBatch
        {
            var profile:String = Starling.current.profile;
            var forceTinted:Boolean = (profile != "baselineConstrained" && profile != "baseline");
            var quadBatch:QuadBatch = new QuadBatch();
            quadBatch.forceTinted = forceTinted;
            return quadBatch;
        }

        /** Disposes redundant quad batches if the number of allocated batches is more than
         *  twice the number of used batches. Only executed when there are at least 16 batches. */
        private function trimQuadBatches():void
        {
            var numUsedBatches:int  = mQuadBatchListPos + 1;
            var numTotalBatches:int = mQuadBatchList.length;

            if (numTotalBatches >= 16 && numTotalBatches > 2*numUsedBatches)
            {
                var numToRemove:int = numTotalBatches - numUsedBatches;
                for (var i:int=0; i<numToRemove; ++i)
                    mQuadBatchList.pop().dispose();
            }
        }

        private function applyBlendMode(premultipliedAlpha:Boolean):void
        {
            RenderUtil.setBlendFactors(premultipliedAlpha, mState.blendMode);
        }

        private function applyCulling():void
        {
            var culling:String = mState.culling;

            if (culling != mActualCulling)
            {
                Starling.context.setCulling(culling);
                mActualCulling = culling;
            }
        }

        private function applyRenderTarget():void
        {
            var target:TextureBase = mState.renderTarget ? mState.renderTarget.base : null;
            var antiAlias:int  = mState.renderTargetAntiAlias;
            var context:Context3D = Starling.context;

            if (target != mActualRenderTarget)
            {
                if (target)
                    context.setRenderToTexture(target, SystemUtil.supportsDepthAndStencil, antiAlias);
                else
                    context.setRenderToBackBuffer();

                context.setStencilReferenceValue(stencilReferenceValue);
                mActualRenderTarget = target;
            }
        }

        private function applyClipRect():void
        {
            var context:Context3D = Starling.context;
            var clipRect:Rectangle = mState.clipRect;

            if (context == null) return;
            if (clipRect)
            {
                var width:int, height:int;
                var renderTarget:Texture = mState.renderTarget;

                if (renderTarget)
                {
                    width  = renderTarget.root.nativeWidth;
                    height = renderTarget.root.nativeHeight;
                }
                else
                {
                    width  = Starling.current.backBufferWidth;
                    height = Starling.current.backBufferHeight;
                }

                // clipping only works in 2D, anyway
                MatrixUtil.convertTo2D(mState.projectionMatrix3D, sMatrix);

                // convert to pixel coordinates (matrix transformation ends up in range [-1, 1])
                MatrixUtil.transformCoords(sMatrix, clipRect.x, clipRect.y, sPoint);
                sClipRect.x = (sPoint.x * 0.5 + 0.5) * width;
                sClipRect.y = (0.5 - sPoint.y * 0.5) * height;

                MatrixUtil.transformCoords(sMatrix, clipRect.right, clipRect.bottom, sPoint);
                sClipRect.right  = (sPoint.x * 0.5 + 0.5) * width;
                sClipRect.bottom = (0.5 - sPoint.y * 0.5) * height;

                sBufferRect.setTo(0, 0, width, height);
                RectangleUtil.intersect(sClipRect, sBufferRect, sScissorRect);

                // an empty rectangle is not allowed, so we set it to the smallest possible size
                if (sScissorRect.width < 1 || sScissorRect.height < 1)
                    sScissorRect.setTo(0, 0, 1, 1);

                context.setScissorRectangle(sScissorRect);
            }
            else
            {
                context.setScissorRectangle(null);
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
            var key:Object = mState.renderTarget ? mState.renderTarget.base : this;
            if (key in mStencilReferenceValues) return mStencilReferenceValues[key];
            else return 0;
        }

        public function set stencilReferenceValue(value:uint):void
        {
            var key:Object = mState.renderTarget ? mState.renderTarget.base : this;
            mStencilReferenceValues[key] = value;

            if (Starling.current.contextValid)
                Starling.context.setStencilReferenceValue(value);
        }

        /** The current render state, containing some of the context settings, projection- and
         *  modelview-matrix, etc.
         */
        public function get state():RenderState { return mState; }
    }
}