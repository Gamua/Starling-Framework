// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.Program3D;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.QuadBatch;
    import starling.display.Stage;
    import starling.errors.MissingContextError;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.Color;
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;

    /** A class that contains helper methods simplifying Stage3D rendering.
     *
     *  A RenderSupport instance is passed to any "render" method of display objects. 
     *  It allows manipulation of the current transformation matrix (similar to the matrix 
     *  manipulation methods of OpenGL 1.x) and other helper methods.
     */
    public class RenderSupport
    {
        // members
        
        private var mProjectionMatrix:Matrix;
        private var mModelViewMatrix:Matrix;
        private var mMvpMatrix:Matrix;
        
        private var mMatrixStack:Vector.<Matrix>;
        private var mMatrixStackSize:int;
        
        private var mProjectionMatrix3D:Matrix3D;
        private var mModelViewMatrix3D:Matrix3D;
        private var mMvpMatrix3D:Matrix3D;
        
        private var mMatrixStack3D:Vector.<Matrix3D>;
        private var mMatrixStack3DSize:int;

        private var mDrawCount:int;
        private var mBlendMode:String;
        private var mRenderTarget:Texture;
        
        private var mClipRectStack:Vector.<Rectangle>;
        private var mClipRectStackSize:int;
        
        private var mQuadBatches:Vector.<QuadBatch>;
        private var mCurrentQuadBatchID:int;
        
        /** helper objects */
        private static var sPoint:Point = new Point();
        private static var sPoint3D:Vector3D = new Vector3D();
        private static var sClipRect:Rectangle = new Rectangle();
        private static var sBufferRect:Rectangle = new Rectangle();
        private static var sScissorRect:Rectangle = new Rectangle();
        private static var sAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        private static var sMatrix3D:Matrix3D = new Matrix3D();
        private static var sMatrixData:Vector.<Number> = 
            new <Number>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        
        // construction
        
        /** Creates a new RenderSupport object with an empty matrix stack. */
        public function RenderSupport()
        {
            mProjectionMatrix = new Matrix();
            mModelViewMatrix = new Matrix();
            mMvpMatrix = new Matrix();
            mMatrixStack = new <Matrix>[];
            mMatrixStackSize = 0;
            
            mProjectionMatrix3D = new Matrix3D();
            mModelViewMatrix3D = new Matrix3D();
            mMvpMatrix3D = new Matrix3D();
            mMatrixStack3D = new <Matrix3D>[];
            mMatrixStack3DSize = 0;
            
            mDrawCount = 0;
            mRenderTarget = null;
            mBlendMode = BlendMode.NORMAL;
            mClipRectStack = new <Rectangle>[];
            
            mCurrentQuadBatchID = 0;
            mQuadBatches = new <QuadBatch>[new QuadBatch()];
            
            loadIdentity();
            setProjectionMatrix(0, 0, 400, 300);
        }
        
        /** Disposes all quad batches. */
        public function dispose():void
        {
            for each (var quadBatch:QuadBatch in mQuadBatches)
                quadBatch.dispose();
        }
        
        // matrix manipulation

        /** Sets up the projection matrices for 2D and 3D rendering.
         *
         *  <p>The first 4 parameters define which area of the stage you want to view. The camera
         *  will 'zoom' to exactly this region. The perspective in which you're looking at the
         *  stage is determined by the final 3 parameters.</p>
         *
         *  <p>The stage is always on the rectangle that is spawned up between x- and y-axis (with
         *  the given size). All objects that are exactly on that rectangle (z equals zero) will be
         *  rendered in their true size, without any distortion.</p>
         */
        public function setProjectionMatrix(x:Number, y:Number, width:Number, height:Number,
                                            stageWidth:Number=0, stageHeight:Number=0,
                                            cameraPos:Vector3D=null):void
        {
            if (stageWidth  <= 0) stageWidth = width;
            if (stageHeight <= 0) stageHeight = height;
            if (cameraPos == null)
            {
                cameraPos = sPoint3D;
                cameraPos.setTo(
                    stageWidth / 2, stageHeight / 2,   // -> center of stage
                    stageWidth / Math.tan(0.5) * 0.5); // -> fieldOfView = 1.0 rad
            }

            // set up 2d (orthographic) projection
            mProjectionMatrix.setTo(2.0/width, 0, 0, -2.0/height,
                -(2*x + width) / width, (2*y + height) / height);

            const focalLength:Number = Math.abs(cameraPos.z);
            const offsetX:Number = cameraPos.x - stageWidth  / 2;
            const offsetY:Number = cameraPos.y - stageHeight / 2;
            const far:Number    = focalLength * 20;
            const near:Number   = 1;
            const scaleX:Number = stageWidth  / width;
            const scaleY:Number = stageHeight / height;

            // set up general perspective
            sMatrixData[ 0] =  2 * focalLength / stageWidth;  // 0,0
            sMatrixData[ 5] = -2 * focalLength / stageHeight; // 1,1  [negative to invert y-axis]
            sMatrixData[10] =  far / (far - near);            // 2,2
            sMatrixData[14] = -far * near / (far - near);     // 2,3
            sMatrixData[11] =  1;                             // 3,2

            // now zoom in to visible area
            sMatrixData[0] *=  scaleX;
            sMatrixData[5] *=  scaleY;
            sMatrixData[8]  =  scaleX - 1 - 2 * scaleX * (x - offsetX) / stageWidth;
            sMatrixData[9]  = -scaleY + 1 + 2 * scaleY * (y - offsetY) / stageHeight;

            mProjectionMatrix3D.copyRawDataFrom(sMatrixData);
            mProjectionMatrix3D.prependTranslation(
                -stageWidth /2.0 - offsetX,
                -stageHeight/2.0 - offsetY,
                focalLength);

            applyClipRect();
        }

        /** Sets up the projection matrix for ortographic 2D rendering. */
        [Deprecated(replacement="setProjectionMatrix")] 
        public function setOrthographicProjection(x:Number, y:Number, width:Number, height:Number):void
        {
            var stage:Stage = Starling.current.stage;
            sClipRect.setTo(x, y, width, height);
            setProjectionMatrix(x, y, width, height,
                stage.stageWidth, stage.stageHeight, stage.cameraPosition);
        }
        
        /** Changes the modelview matrix to the identity matrix. */
        public function loadIdentity():void
        {
            mModelViewMatrix.identity();
            mModelViewMatrix3D.identity();
        }
        
        /** Prepends a translation to the modelview matrix. */
        public function translateMatrix(dx:Number, dy:Number):void
        {
            MatrixUtil.prependTranslation(mModelViewMatrix, dx, dy);
        }
        
        /** Prepends a rotation (angle in radians) to the modelview matrix. */
        public function rotateMatrix(angle:Number):void
        {
            MatrixUtil.prependRotation(mModelViewMatrix, angle);
        }
        
        /** Prepends an incremental scale change to the modelview matrix. */
        public function scaleMatrix(sx:Number, sy:Number):void
        {
            MatrixUtil.prependScale(mModelViewMatrix, sx, sy);
        }
        
        /** Prepends a matrix to the modelview matrix by multiplying it with another matrix. */
        public function prependMatrix(matrix:Matrix):void
        {
            MatrixUtil.prependMatrix(mModelViewMatrix, matrix);
        }
        
        /** Prepends translation, scale and rotation of an object to the modelview matrix. */
        public function transformMatrix(object:DisplayObject):void
        {
            MatrixUtil.prependMatrix(mModelViewMatrix, object.transformationMatrix);
        }
        
        /** Pushes the current modelview matrix to a stack from which it can be restored later. */
        public function pushMatrix():void
        {
            if (mMatrixStack.length < mMatrixStackSize + 1)
                mMatrixStack.push(new Matrix());
        
            mMatrixStack[int(mMatrixStackSize++)].copyFrom(mModelViewMatrix);
        }
        
        /** Restores the modelview matrix that was last pushed to the stack. */
        public function popMatrix():void
        {
            mModelViewMatrix.copyFrom(mMatrixStack[int(--mMatrixStackSize)]);
        }
        
        /** Empties the matrix stack, resets the modelview matrix to the identity matrix. */
        public function resetMatrix():void
        {
            mMatrixStackSize = 0;
            mMatrixStack3DSize = 0;
            loadIdentity();
        }
        
        /** Prepends translation, scale and rotation of an object to a custom matrix. */
        public static function transformMatrixForObject(matrix:Matrix, object:DisplayObject):void
        {
            MatrixUtil.prependMatrix(matrix, object.transformationMatrix);
        }
        
        /** Calculates the product of modelview and projection matrix. 
         *  CAUTION: Use with care! Each call returns the same instance. */
        public function get mvpMatrix():Matrix
        {
            mMvpMatrix.copyFrom(mModelViewMatrix);
            mMvpMatrix.concat(mProjectionMatrix);
            return mMvpMatrix;
        }
        
        /** Returns the current modelview matrix.
         *  CAUTION: Use with care! Each call returns the same instance. */
        public function get modelViewMatrix():Matrix { return mModelViewMatrix; }
        
        /** Returns the current projection matrix.
         *  CAUTION: Use with care! Each call returns the same instance. */
        public function get projectionMatrix():Matrix { return mProjectionMatrix; }
        public function set projectionMatrix(value:Matrix):void 
        {
            mProjectionMatrix.copyFrom(value);
            applyClipRect();
        }
        
        // 3d transformations
        
        /** Prepends translation, scale and rotation of an object to the 3D modelview matrix.
         *  The current contents of the 2D modelview matrix is stored in the 3D modelview matrix
         *  before doing so; the 2D modelview matrix is then reset to the identity matrix. */
        public function transformMatrix3D(object:DisplayObject):void
        {
            mModelViewMatrix3D.prepend(MatrixUtil.convertTo3D(mModelViewMatrix, sMatrix3D));
            mModelViewMatrix3D.prepend(object.transformationMatrix3D);
            mModelViewMatrix.identity();
        }
        
        /** Pushes the current 3D modelview matrix to a stack from which it can be restored later. */
        public function pushMatrix3D():void
        {
            if (mMatrixStack3D.length < mMatrixStack3DSize + 1)
                mMatrixStack3D.push(new Matrix3D());
            
            mMatrixStack3D[int(mMatrixStack3DSize++)].copyFrom(mModelViewMatrix3D);
        }
        
        /** Restores the 3D modelview matrix that was last pushed to the stack. */
        public function popMatrix3D():void
        {
            mModelViewMatrix3D.copyFrom(mMatrixStack3D[int(--mMatrixStack3DSize)]);
        }
        
        /** Calculates the product of modelview and projection matrix and stores it in a 3D matrix.
         *  Different to 'mvpMatrix', this also takes 3D transformations into account. 
         *  CAUTION: Use with care! Each call returns the same instance. */
        public function get mvpMatrix3D():Matrix3D
        {
            if (mMatrixStack3DSize == 0)
            {
                MatrixUtil.convertTo3D(mvpMatrix, mMvpMatrix3D);
            }
            else
            {
                mMvpMatrix3D.copyFrom(mProjectionMatrix3D);
                mMvpMatrix3D.prepend(mModelViewMatrix3D);
                mMvpMatrix3D.prepend(MatrixUtil.convertTo3D(mModelViewMatrix, sMatrix3D));
            }
            
            return mMvpMatrix3D;
        }
        
        /** Returns the current 3D projection matrix.
         *  CAUTION: Use with care! Each call returns the same instance. */
        public function get projectionMatrix3D():Matrix3D { return mProjectionMatrix3D; }
        public function set projectionMatrix3D(value:Matrix3D):void
        {
            mProjectionMatrix3D.copyFrom(value);
        }

        // blending
        
        /** Activates the current blend mode on the active rendering context. */
        public function applyBlendMode(premultipliedAlpha:Boolean):void
        {
            setBlendFactors(premultipliedAlpha, mBlendMode);
        }
        
        /** The blend mode to be used on rendering. To apply the factor, you have to manually call
         *  'applyBlendMode' (because the actual blend factors depend on the PMA mode). */
        public function get blendMode():String { return mBlendMode; }
        public function set blendMode(value:String):void
        {
            if (value != BlendMode.AUTO) mBlendMode = value;
        }
        
        // render targets
        
        /** The texture that is currently being rendered into, or 'null' to render into the 
         *  back buffer. If you set a new target, it is immediately activated. */
        public function get renderTarget():Texture { return mRenderTarget; }
        public function set renderTarget(target:Texture):void 
        {
            setRenderTarget(target);
        }

        /** Changes the the current render target.
         *  @param target       Either a texture or 'null' to render into the back buffer.
         *  @param antiAliasing Only supported for textures, beginning with AIR 13, and only on
         *                      Desktop. Values range from 0 (no antialiasing) to 4 (best quality).
         */
        public function setRenderTarget(target:Texture, antiAliasing:int=0):void
        {
            mRenderTarget = target;
            applyClipRect();
            
            if (target) Starling.context.setRenderToTexture(target.base, false, antiAliasing);
            else        Starling.context.setRenderToBackBuffer();
        }
        
        // clipping
        
        /** The clipping rectangle can be used to limit rendering in the current render target to
         *  a certain area. This method expects the rectangle in stage coordinates. Internally,
         *  it uses the 'scissorRectangle' of stage3D, which works with pixel coordinates. 
         *  Any pushed rectangle is intersected with the previous rectangle; the method returns
         *  that intersection. */ 
        public function pushClipRect(rectangle:Rectangle):Rectangle
        {
            if (mClipRectStack.length < mClipRectStackSize + 1)
                mClipRectStack.push(new Rectangle());
            
            mClipRectStack[mClipRectStackSize].copyFrom(rectangle);
            rectangle = mClipRectStack[mClipRectStackSize];
            
            // intersect with the last pushed clip rect
            if (mClipRectStackSize > 0)
                RectangleUtil.intersect(rectangle, mClipRectStack[mClipRectStackSize-1], 
                                        rectangle);
            
            ++mClipRectStackSize;
            applyClipRect();
            
            // return the intersected clip rect so callers can skip draw calls if it's empty
            return rectangle;
        }
        
        /** Restores the clipping rectangle that was last pushed to the stack. */
        public function popClipRect():void
        {
            if (mClipRectStackSize > 0)
            {
                --mClipRectStackSize;
                applyClipRect();
            }
        }
        
        /** Updates the context3D scissor rectangle using the current clipping rectangle. This
         *  method is called automatically when either the render target, the projection matrix,
         *  or the clipping rectangle changes. */
        public function applyClipRect():void
        {
            finishQuadBatch();
            
            var context:Context3D = Starling.context;
            if (context == null) return;
            
            if (mClipRectStackSize > 0)
            {
                var width:int, height:int;
                var rect:Rectangle = mClipRectStack[mClipRectStackSize-1];
                
                if (mRenderTarget)
                {
                    width  = mRenderTarget.root.nativeWidth;
                    height = mRenderTarget.root.nativeHeight;
                }
                else
                {
                    width  = Starling.current.backBufferWidth;
                    height = Starling.current.backBufferHeight;
                }
                
                // convert to pixel coordinates (matrix transformation ends up in range [-1, 1])
                MatrixUtil.transformCoords(mProjectionMatrix, rect.x, rect.y, sPoint);
                sClipRect.x = (sPoint.x * 0.5 + 0.5) * width;
                sClipRect.y = (0.5 - sPoint.y * 0.5) * height;
                
                MatrixUtil.transformCoords(mProjectionMatrix, rect.right, rect.bottom, sPoint);
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
        
        // optimized quad rendering
        
        /** Adds a quad to the current batch of unrendered quads. If there is a state change,
         *  all previous quads are rendered at once, and the batch is reset. */
        public function batchQuad(quad:Quad, parentAlpha:Number, 
                                  texture:Texture=null, smoothing:String=null):void
        {
            if (mQuadBatches[mCurrentQuadBatchID].isStateChange(quad.tinted, parentAlpha, texture, 
                                                                smoothing, mBlendMode))
            {
                finishQuadBatch();
            }
            
            mQuadBatches[mCurrentQuadBatchID].addQuad(quad, parentAlpha, texture, smoothing, 
                                                      mModelViewMatrix, mBlendMode);
        }
        
        /** Adds a batch of quads to the current batch of unrendered quads. If there is a state 
         *  change, all previous quads are rendered at once. 
         *  
         *  <p>Note that you should call this method only for objects with a small number of quads 
         *  (we recommend no more than 16). Otherwise, the additional CPU effort will be more
         *  expensive than what you save by avoiding the draw call.</p> */
        public function batchQuadBatch(quadBatch:QuadBatch, parentAlpha:Number):void
        {
            if (mQuadBatches[mCurrentQuadBatchID].isStateChange(
                quadBatch.tinted, parentAlpha, quadBatch.texture, quadBatch.smoothing, mBlendMode))
            {
                finishQuadBatch();
            }
            
            mQuadBatches[mCurrentQuadBatchID].addQuadBatch(quadBatch, parentAlpha, 
                                                           mModelViewMatrix, mBlendMode);
        }
        
        /** Renders the current quad batch and resets it. */
        public function finishQuadBatch():void
        {
            var currentBatch:QuadBatch = mQuadBatches[mCurrentQuadBatchID];
            
            if (currentBatch.numQuads != 0)
            {
                if (mMatrixStack3DSize == 0)
                {
                    currentBatch.renderCustom(mProjectionMatrix3D);
                }
                else
                {
                    mMvpMatrix3D.copyFrom(mProjectionMatrix3D);
                    mMvpMatrix3D.prepend(mModelViewMatrix3D);
                    currentBatch.renderCustom(mMvpMatrix3D);
                }
                
                currentBatch.reset();
                
                ++mCurrentQuadBatchID;
                ++mDrawCount;
                
                if (mQuadBatches.length <= mCurrentQuadBatchID)
                    mQuadBatches.push(new QuadBatch());
            }
        }
        
        /** Resets matrix stack, blend mode, quad batch index, and draw count. */
        public function nextFrame():void
        {
            resetMatrix();
            trimQuadBatches();
            
            mCurrentQuadBatchID = 0;
            mBlendMode = BlendMode.NORMAL;
            mDrawCount = 0;
        }

        /** Disposes redundant quad batches if the number of allocated batches is more than
         *  twice the number of used batches. Only executed when there are at least 16 batches. */
        private function trimQuadBatches():void
        {
            var numUsedBatches:int  = mCurrentQuadBatchID + 1;
            var numTotalBatches:int = mQuadBatches.length;
            
            if (numTotalBatches >= 16 && numTotalBatches > 2*numUsedBatches)
            {
                var numToRemove:int = numTotalBatches - numUsedBatches;
                for (var i:int=0; i<numToRemove; ++i)
                    mQuadBatches.pop().dispose();
            }
        }
        
        // other helper methods
        
        /** Deprecated. Call 'setBlendFactors' instead. */
        public static function setDefaultBlendFactors(premultipliedAlpha:Boolean):void
        {
            setBlendFactors(premultipliedAlpha);
        }
        
        /** Sets up the blending factors that correspond with a certain blend mode. */
        public static function setBlendFactors(premultipliedAlpha:Boolean, blendMode:String="normal"):void
        {
            var blendFactors:Array = BlendMode.getBlendFactors(blendMode, premultipliedAlpha); 
            Starling.context.setBlendFactors(blendFactors[0], blendFactors[1]);
        }
        
        /** Clears the render context with a certain color and alpha value. */
        public static function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            Starling.context.clear(
                Color.getRed(rgb)   / 255.0, 
                Color.getGreen(rgb) / 255.0, 
                Color.getBlue(rgb)  / 255.0,
                alpha);
        }
        
        /** Clears the render context with a certain color and alpha value. */
        public function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            RenderSupport.clear(rgb, alpha);
        }
        
        /** Assembles fragment- and vertex-shaders, passed as Strings, to a Program3D. If you
         *  pass a 'resultProgram', it will be uploaded to that program; otherwise, a new program
         *  will be created on the current Stage3D context. */ 
        public static function assembleAgal(vertexShader:String, fragmentShader:String,
                                            resultProgram:Program3D=null):Program3D
        {
            if (resultProgram == null) 
            {
                var context:Context3D = Starling.context;
                if (context == null) throw new MissingContextError();
                resultProgram = context.createProgram();
            }
            
            resultProgram.upload(
                sAssembler.assemble(Context3DProgramType.VERTEX, vertexShader),
                sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader));
            
            return resultProgram;
        }
        
        /** Returns the flags that are required for AGAL texture lookup, 
         *  including the '&lt;' and '&gt;' delimiters. */
        public static function getTextureLookupFlags(format:String, mipMapping:Boolean,
                                                     repeat:Boolean=false,
                                                     smoothing:String="bilinear"):String
        {
            var options:Array = ["2d", repeat ? "repeat" : "clamp"];
            
            if (format == Context3DTextureFormat.COMPRESSED)
                options.push("dxt1");
            else if (format == "compressedAlpha")
                options.push("dxt5");
            
            if (smoothing == TextureSmoothing.NONE)
                options.push("nearest", mipMapping ? "mipnearest" : "mipnone");
            else if (smoothing == TextureSmoothing.BILINEAR)
                options.push("linear", mipMapping ? "mipnearest" : "mipnone");
            else
                options.push("linear", mipMapping ? "miplinear" : "mipnone");
            
            return "<" + options.join() + ">";
        }
        
        // statistics
        
        /** Raises the draw count by a specific value. Call this method in custom render methods
         *  to keep the statistics display in sync. */
        public function raiseDrawCount(value:uint=1):void { mDrawCount += value; }
        
        /** Indicates the number of stage3D draw calls. */
        public function get drawCount():int { return mDrawCount; }
    }
}