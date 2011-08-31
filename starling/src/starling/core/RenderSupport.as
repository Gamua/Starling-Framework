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
    import flash.display3D.*;
    import flash.geom.*;
    import flash.utils.*;
    
    import starling.display.*;
    import starling.errors.*;
    import starling.utils.*;

    public class RenderSupport
    {
        // members        
        
        private var mProjectionMatrix:Matrix3D;
        private var mModelViewMatrix:Matrix3D;        
        private var mMatrixStack:Vector.<Matrix3D>;
        
        // construction
        
        public function RenderSupport()
        {
            mMatrixStack = new <Matrix3D>[];
            mProjectionMatrix = new Matrix3D();
            mModelViewMatrix = new Matrix3D();
            
            loadIdentity();
            setOrthographicProjection(400, 300);
        }
        
        // matrix manipulation
        
        public function setOrthographicProjection(width:Number, height:Number, 
                                                  near:Number=-1.0, far:Number=1.0):void
        {
            var coords:Vector.<Number> = new <Number>[                
                2.0/width, 0.0, 0.0, 0.0,
                0.0, -2.0/height, 0.0, 0.0,
                0.0, 0.0, -2.0/(far-near), 0.0,
                -1.0, 1.0, -(far+near)/(far-near), 1.0                
            ];
            
            mProjectionMatrix.copyRawDataFrom(coords);
        }
        
        public function loadIdentity():void
        {
            mModelViewMatrix.identity();
        }
        
        public function translateMatrix(dx:Number, dy:Number, dz:Number=0):void
        {
            mModelViewMatrix.prependTranslation(dx, dy, dz);
        }
        
        public function rotateMatrix(angle:Number, axis:Vector3D=null):void
        {
            mModelViewMatrix.prependRotation(angle / Math.PI * 180.0, 
                                             axis == null ? Vector3D.Z_AXIS : axis);
        }
        
        public function scaleMatrix(sx:Number, sy:Number, sz:Number=1.0):void
        {
            mModelViewMatrix.prependScale(sx, sy, sz);    
        }
        
        public function transformMatrix(object:DisplayObject):void
        {
            transformMatrixForObject(mModelViewMatrix, object);   
        }
        
        public function pushMatrix():void
        {
            mMatrixStack.push(mModelViewMatrix.clone());
        }
        
        public function popMatrix():void
        {
            mModelViewMatrix = mMatrixStack.pop();
        }
        
        public function resetMatrix():void
        {
            if (mMatrixStack.length != 0)
                mMatrixStack = new <Matrix3D>[];
            
            loadIdentity();
        }
        
        public function get mvpMatrix():Matrix3D
        {
            var mvpMatrix:Matrix3D = new Matrix3D();
            mvpMatrix.append(mModelViewMatrix);
            mvpMatrix.append(mProjectionMatrix);
            return mvpMatrix;
        }
        
        public static function transformMatrixForObject(matrix:Matrix3D, object:DisplayObject):void
        {
            matrix.prependTranslation(object.x, object.y, 0.0);
            matrix.prependRotation(object.rotation / Math.PI * 180.0, Vector3D.Z_AXIS);
            matrix.prependScale(object.scaleX, object.scaleY, 1.0);
            matrix.prependTranslation(-object.pivotX, -object.pivotY, 0.0);
        }
        
        // other helper methods
        
        public function setDefaultBlendFactors(premultipliedAlpha:Boolean):void
        {
            var destFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            var sourceFactor:String = premultipliedAlpha ? Context3DBlendFactor.ONE :
                                                           Context3DBlendFactor.SOURCE_ALPHA;
            Starling.context.setBlendFactors(sourceFactor, destFactor);
        }
        
        public function clear(rgb:uint=0, alpha:Number=0.0):void
        {
            Starling.context.clear(
                Color.getRed(rgb)   / 255.0, 
                Color.getGreen(rgb) / 255.0, 
                Color.getBlue(rgb)  / 255.0,
                alpha);
        }
    }
}