// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    
    import starling.utils.rad2deg;

    public class Sprite3D extends Sprite
    {
        private var mRotationX:Number;
        private var mRotationY:Number;
        private var mZ:Number;
        
        private var mTransformationMatrix:Matrix3D;
        private var mTransformationChanged:Boolean;
        
        public function Sprite3D()
        {
            mRotationX = mRotationY = mZ = 0.0;
            mTransformationMatrix = new Matrix3D();
        }

        /*
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.finishQuadBatch();
            super.render(support, parentAlpha);
            support.finishQuadBatch();
        }
        */
        
        public function get transformationMatrix3D():Matrix3D
        {
            if (mTransformationChanged)
            {
                mTransformationChanged = false;
                mTransformationMatrix.identity();
                mTransformationMatrix.appendScale(scaleX, scaleY, 1);
                mTransformationMatrix.appendRotation(rad2deg(mRotationX), Vector3D.X_AXIS);
                mTransformationMatrix.appendRotation(rad2deg(mRotationY), Vector3D.Y_AXIS);
                mTransformationMatrix.appendRotation(rad2deg( rotation ), Vector3D.Z_AXIS);
                mTransformationMatrix.appendTranslation(x, y, mZ);
            }
            
            return mTransformationMatrix; 
        }
        
        /** @inheritDoc */
        public override function set x(value:Number):void 
        { 
            super.x = value;
            mTransformationChanged = true;
        }
        
        /** @inheritDoc */
        public override function set y(value:Number):void 
        {
            super.y = value;
            mTransformationChanged = true;
        }
        
        /** The z coordinate of the object relative to the local coordinates of the parent. */
        public function get z():Number { return mZ; }
        public function set z(value:Number):void
        {
            mZ = value;
            mTransformationChanged = true;
        }
        
        /** @inheritDoc */
        public override function set pivotX(value:Number):void 
        {
            throw new Error("3D objects do not support pivot points");
            
            // super.pivotX = value;
            // mOrientationChanged = true;
        }
        
        /** @inheritDoc */
        public override function set pivotY(value:Number):void 
        {
            throw new Error("3D objects do not support pivot points");
            
            // super.pivotY = value;
            // mOrientationChanged = value;
        }
        
        /** @inheritDoc */
        public override function set scaleX(value:Number):void 
        {
            super.scaleX = value;
            mTransformationChanged = true;
        }
        
        /** @inheritDoc */
        public override function set scaleY(value:Number):void 
        {
            super.scaleY = value;
            mTransformationChanged = true;
        }
        
        /** @inheritDoc */
        public override function set skewX(value:Number):void 
        {
            throw new Error("3D objects do not support skewing");
            
            // super.skewX = value;
            // mOrientationChanged = true;
        }
        
        /** @inheritDoc */
        public override function set skewY(value:Number):void 
        {
            throw new Error("3D objects do not support skewing");
            
            // super.skewY = value;
            // mOrientationChanged = true;
        }
        
        /** The rotation of the object about the z axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public override function set rotation(value:Number):void 
        {
            super.rotation = value;
            mTransformationChanged = value;
        }
        
        /** The rotation of the object about the x axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationX():Number { return mRotationX; }
        public function set rotationX(value:Number):void
        { 
            mRotationX = value;
            mTransformationChanged = true;
        }
        
        /** The rotation of the object about the y axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationY():Number { return mRotationY; }
        public function set rotationY(value:Number):void
        {
            mRotationY = value;
            mTransformationChanged = true;
        }
        
        /** The rotation of the object about the z axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationZ():Number { return rotation; }
        public function set rotationZ(value:Number):void { rotation = value; }
    }
}