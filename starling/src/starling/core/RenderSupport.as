// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.geom.*;
    
    import starling.display.*;
    import starling.textures.Texture;
    import starling.utils.*;

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
        private var mMvpMatrix3D:Matrix3D;
        private var mMatrixStack:Vector.<Matrix>;
        private var mMatrixStackSize:int;
        private var mDrawCount:int;
        
        private var mBlendMode:String;
        private var mBlendModeStack:Vector.<String>;
        
        private var mQuadBatches:Vector.<QuadBatch>;
        private var mCurrentQuadBatchID:int;
        
        /** Helper object. */
        private static var sHelperMatrix:Matrix = new Matrix();
        
        // construction
        
        /** Creates a new RenderSupport object with an empty matrix stack. */
        public function RenderSupport()
        {
            mProjectionMatrix = new Matrix();
            mModelViewMatrix = new Matrix();
            mMvpMatrix = new Matrix();
            mMvpMatrix3D = new Matrix3D();
            mMatrixStack = new <Matrix>[];
            mMatrixStackSize = 0;
            mDrawCount = 0;
            
            mBlendMode = BlendMode.NORMAL;
            mBlendModeStack = new <String>[];
            
            mCurrentQuadBatchID = 0;
            mQuadBatches = new <QuadBatch>[new QuadBatch()];
            
            loadIdentity();
            setOrthographicProjection(400, 300);
        }
        
        /** Disposes all quad batches. */
        public function dispose():void
        {
            for each (var quadBatch:QuadBatch in mQuadBatches)
                quadBatch.dispose();
        }
        
        // matrix manipulation
        
        /** Sets up the projection matrix for ortographic 2D rendering. */
        public function setOrthographicProjection(width:Number, height:Number):void
        {
            mProjectionMatrix.setTo(2.0/width, 0, 0, -2.0/height, -1.0, 1.0);
        }
        
        /** Changes the modelview matrix to the identity matrix. */
        public function loadIdentity():void
        {
            mModelViewMatrix.identity();
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
        
        /** Prepends translation, scale and rotation of an object to the modelview matrix. */
        public function transformMatrix(object:DisplayObject):void
        {
            transformMatrixForObject(mModelViewMatrix, object);   
        }
        
        /** Pushes the current modelview matrix to a stack from which it can be restored later. */
        public function pushMatrix():void
        {
            if (mMatrixStack.length < mMatrixStackSize + 1)
                mMatrixStack.push(new Matrix());
            
            mMatrixStack[mMatrixStackSize++].copyFrom(mModelViewMatrix);
        }
        
        /** Restores the modelview matrix that was last pushed to the stack. */
        public function popMatrix():void
        {
            mModelViewMatrix.copyFrom(mMatrixStack[--mMatrixStackSize]);
        }
        
        /** Empties the matrix stack, resets the modelview matrix to the identity matrix. */
        public function resetMatrix():void
        {
            mMatrixStackSize = 0;
            loadIdentity();
        }
        
        /** Calculates the product of modelview and projection matrix. 
         *  CAUTION: Don't save a reference to this object! Each call returns the same instance. */
        public function get mvpMatrix():Matrix
        {
			mMvpMatrix.copyFrom(mModelViewMatrix);
            mMvpMatrix.concat(mProjectionMatrix);
            return mMvpMatrix;
        }
        
        /** Calculates the product of modelview and projection matrix and saves it in a 3D matrix. 
         *  CAUTION: Don't save a reference to this object! Each call returns the same instance. */
        public function get mvpMatrix3D():Matrix3D
        {
            return MatrixUtil.convertTo3D(mvpMatrix, mMvpMatrix3D);
        }
        
        /** Prepends translation, scale and rotation of an object to a custom matrix. */
        public static function transformMatrixForObject(matrix:Matrix, object:DisplayObject):void
        {
            sHelperMatrix.copyFrom(object.transformationMatrix);
            sHelperMatrix.concat(matrix);
            matrix.copyFrom(sHelperMatrix);
        }
        
        // blending
        
        /** Pushes the current blend mode to a stack from which it can be restored later. */
        public function pushBlendMode():void
        {
            mBlendModeStack.push(mBlendMode);
        }
        
        /** Restores the blend mode that was last pushed to the stack. */
        public function popBlendMode():void
        {
            mBlendMode = mBlendModeStack.pop();
        }
        
        /** Clears the blend mode stack and restores NORMAL blend mode. */
        public function resetBlendMode():void
        {
            mBlendModeStack.length = 0;
            mBlendMode = BlendMode.NORMAL;
        }
        
        /** Activates the appropriate blend factors on the current rendering context. */
        public function applyBlendMode(premultipliedAlpha:Boolean):void
        {
            setBlendFactors(premultipliedAlpha, mBlendMode);
        }
        
        /** The blend mode to be used on rendering. */
        public function get blendMode():String { return mBlendMode; }
        public function set blendMode(value:String):void
        {
            if (value != BlendMode.AUTO) mBlendMode = value;
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
        
        /** Renders the current quad batch and resets it. */
        public function finishQuadBatch():void
        {
            var currentBatch:QuadBatch = mQuadBatches[mCurrentQuadBatchID];
            
            if (currentBatch.numQuads != 0)
            {
                currentBatch.renderCustom(mProjectionMatrix);
                currentBatch.reset();
                
                ++mCurrentQuadBatchID;
                ++mDrawCount;
                
                if (mQuadBatches.length <= mCurrentQuadBatchID)
                    mQuadBatches.push(new QuadBatch());
            }
        }
        
        /** Resets the matrix and blend mode stacks, the quad batch index, and the draw count. */
        public function nextFrame():void
        {
            resetMatrix();
            resetBlendMode();
            mCurrentQuadBatchID = 0;
            mDrawCount = 0;
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
        
        // statistics
        
        /** Raises the draw count by a specific value. Call this method in custom render methods
         *  to keep the statistics display in sync. */
        public function raiseDrawCount(value:uint=1):void { mDrawCount += value; }
        
        /** Indicates the number of stage3D draw calls. */
        public function get drawCount():int { return mDrawCount; }
        
    }
}