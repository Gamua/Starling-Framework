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
    import starling.events.Event;
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
        
        private var mProjectionMatrix:Matrix3D;
        private var mModelViewMatrix:Matrix3D;
        private var mMvpMatrix:Matrix3D;
        private var mMatrixStack:Vector.<Matrix3D>;
        private var mMatrixStackSize:int;
        
        private var mBlendMode:String;
        private var mBlendModeStack:Vector.<String>;
        
        private var mQuadBatches:Vector.<QuadBatch>;
        private var mCurrentQuadBatchID:int;
        
        /** Helper object. */
        private static var sMatrixCoords:Vector.<Number> = new Vector.<Number>(16, true);
        
        // construction
        
        /** Creates a new RenderSupport object with an empty matrix stack. */
        public function RenderSupport()
        {
            mProjectionMatrix = new Matrix3D();
            mModelViewMatrix = new Matrix3D();
            mMvpMatrix = new Matrix3D();
            mMatrixStack = new <Matrix3D>[];
            mMatrixStackSize = 0;
            
            mBlendMode = BlendMode.NORMAL;
            mBlendModeStack = new <String>[];
            
            mCurrentQuadBatchID = 0;
            mQuadBatches = new <QuadBatch>[new QuadBatch()];
            
            loadIdentity();
            setOrthographicProjection(400, 300);
            
            Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        }
        
        /** Disposes all quad batches. */
        public function dispose():void
        {
            for each (var quadBatch:QuadBatch in mQuadBatches)
                quadBatch.dispose();
            
            Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        }
        
        private function onContextCreated(event:Event):void
        {
            mQuadBatches = new <QuadBatch>[new QuadBatch()];
        }
        
        // matrix manipulation
        
        /** Sets up the projection matrix for ortographic 2D rendering. */
        public function setOrthographicProjection(width:Number, height:Number, 
                                                  near:Number=-1.0, far:Number=1.0):void
        {
            sMatrixCoords[0] = 2.0 / width;
            sMatrixCoords[1] = sMatrixCoords[2] = sMatrixCoords[3] = sMatrixCoords[4] = 0.0;
            sMatrixCoords[5] = -2.0 / height;
            sMatrixCoords[6] = sMatrixCoords[7] = sMatrixCoords[8] = sMatrixCoords[9] = 0.0;
            sMatrixCoords[10] = -2.0 / (far - near);
            sMatrixCoords[11] = 0.0;
            sMatrixCoords[12] = -1.0;
            sMatrixCoords[13] = 1.0;
            sMatrixCoords[14] = -(far+near) / (far-near);
            sMatrixCoords[15] = 1.0;
            
            mProjectionMatrix.copyRawDataFrom(sMatrixCoords);
        }
        
        /** Changes the modelview matrix to the identity matrix. */
        public function loadIdentity():void
        {
            mModelViewMatrix.identity();
        }
        
        /** Prepends a translation to the modelview matrix. */
        public function translateMatrix(dx:Number, dy:Number, dz:Number=0):void
        {
            mModelViewMatrix.prependTranslation(dx, dy, dz);
        }
        
        /** Prepends a rotation (angle in radians) to the modelview matrix. */
        public function rotateMatrix(angle:Number, axis:Vector3D=null):void
        {
            mModelViewMatrix.prependRotation(angle / Math.PI * 180.0, 
                                             axis == null ? Vector3D.Z_AXIS : axis);
        }
        
        /** Prepends an incremental scale change to the modelview matrix. */
        public function scaleMatrix(sx:Number, sy:Number, sz:Number=1.0):void
        {
            mModelViewMatrix.prependScale(sx, sy, sz);    
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
                mMatrixStack.push(new Matrix3D());
            
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
        public function get mvpMatrix():Matrix3D
        {
			mMvpMatrix.copyFrom(mModelViewMatrix);
            mMvpMatrix.append(mProjectionMatrix);
            return mMvpMatrix;
        }
        
        /** Prepends translation, scale and rotation of an object to a custom matrix. */
        public static function transformMatrixForObject(matrix:Matrix3D, object:DisplayObject):void
        {
            var x:Number = object.x; var y:Number = object.y;
            var rotation:Number = object.rotation;
            var scaleX:Number = object.scaleX; var scaleY:Number = object.scaleY;
            var pivotX:Number = object.pivotX; var pivotY:Number = object.pivotY;
            
            if (x != 0 || y != 0)           matrix.prependTranslation(x, y, 0.0);
            if (rotation != 0)              matrix.prependRotation(rotation / Math.PI * 180.0, Vector3D.Z_AXIS);
            if (scaleX != 1 || scaleY != 1) matrix.prependScale(scaleX, scaleY, 1.0);
            if (pivotX != 0 || pivotY != 0) matrix.prependTranslation(-pivotX, -pivotY, 0.0);
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
            if (currentQuadBatch.isStateChange(quad, parentAlpha, texture, smoothing, mBlendMode))
                finishQuadBatch();
            
            currentQuadBatch.addQuad(quad, parentAlpha, texture, smoothing, mModelViewMatrix, mBlendMode);
        }
        
        /** Renders the current quad batch and resets it. */
        public function finishQuadBatch():void
        {
            currentQuadBatch.renderCustom(mProjectionMatrix);
            currentQuadBatch.reset();
            
            ++mCurrentQuadBatchID;
            
            if (mQuadBatches.length <= mCurrentQuadBatchID)
                mQuadBatches.push(new QuadBatch());
        }
        
        /** Resets the matrix and blend mode stacks, and the quad batch index. */
        public function nextFrame():void
        {
            resetMatrix();
            resetBlendMode();
            mCurrentQuadBatchID = 0;
        }
        
        private function get currentQuadBatch():QuadBatch
        {
            return mQuadBatches[mCurrentQuadBatchID];
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
    }
}