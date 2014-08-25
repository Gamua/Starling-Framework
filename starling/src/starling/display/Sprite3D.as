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
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    import starling.core.RenderSupport;
    import starling.events.Event;
    import starling.utils.MathUtil;
    import starling.utils.MatrixUtil;
    import starling.utils.rad2deg;

    public class Sprite3D extends DisplayObjectContainer
    {
        private var mRotationX:Number;
        private var mRotationY:Number;
        private var mZ:Number;

        private var mTransformationMatrix:Matrix;
        private var mTransformationMatrix3D:Matrix3D;
        private var mTransformationChanged:Boolean;

        /** Helper objects. */
        private static var sHelperPoint:Vector3D    = new Vector3D();
        private static var sHelperPointAlt:Vector3D = new Vector3D();
        private static var sHelperMatrix:Matrix3D   = new Matrix3D();

        public function Sprite3D()
        {
            mRotationX = mRotationY = mZ = 0.0;
            mTransformationMatrix = new Matrix();
            mTransformationMatrix3D = new Matrix3D();
            setIs3D(true);

            addEventListener(Event.ADDED, onAddedChild);
            addEventListener(Event.REMOVED, onRemovedChild);
        }

        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.finishQuadBatch();
            support.pushMatrix3D();
            support.transformMatrix3D(this);

            super.render(support, parentAlpha);

            support.finishQuadBatch();
            support.popMatrix3D();
        }

        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;

            // We calculate the interception point between the 3D plane that is spawned up
            // by this sprite3D and the straight line between the camera and the hit point.

            sHelperMatrix.copyFrom(transformationMatrix3D);
            sHelperMatrix.invert();

            var camPos:Vector3D = stage.getCameraPosition(this, sHelperPoint);
            var localPoint3D:Vector3D = MatrixUtil.transformCoords3D(
                sHelperMatrix, localPoint.x, localPoint.y, 0, sHelperPointAlt);

            MathUtil.intersectLineWithXYPlane(localPoint3D, camPos, localPoint);

            return super.hitTest(localPoint, forTouch);
        }

        // helpers

        private function onAddedChild(event:Event):void
        {
            recursivelySetIs3D(event.target as DisplayObject, true);
        }

        private function onRemovedChild(event:Event):void
        {
            recursivelySetIs3D(event.target as DisplayObject, false);
        }

        private function recursivelySetIs3D(object:DisplayObject, value:Boolean):void
        {
            if (object is Sprite3D)
                return;

            if (object is DisplayObjectContainer)
            {
                var container:DisplayObjectContainer = object as DisplayObjectContainer;
                var numChildren:int = container.numChildren;

                for (var i:int=0; i<numChildren; ++i)
                    recursivelySetIs3D(container.getChildAt(i), value);
            }

            object.setIs3D(value);
        }

        // properties

        /** Always returns the identity matrix. The actual transformation of a Sprite3D is stored
         *  in 'transformationMatrix3D' (a 2D matrix cannot represent 3D transformations). */
        public override function get transformationMatrix():Matrix
        {
            return mTransformationMatrix;
        }

        public override function set transformationMatrix(value:Matrix):void
        {
            // todo: test this.

            super.transformationMatrix = value;
            mTransformationChanged = true;
        }

        public override function get transformationMatrix3D():Matrix3D
        {
            if (mTransformationChanged)
            {
                mTransformationChanged = false;
                mTransformationMatrix3D.identity();
                mTransformationMatrix3D.appendScale(scaleX, scaleY, 1);
                mTransformationMatrix3D.appendRotation(rad2deg(mRotationX), Vector3D.X_AXIS);
                mTransformationMatrix3D.appendRotation(rad2deg(mRotationY), Vector3D.Y_AXIS);
                mTransformationMatrix3D.appendRotation(rad2deg( rotation ), Vector3D.Z_AXIS);
                mTransformationMatrix3D.appendTranslation(x, y, mZ);
            }

            return mTransformationMatrix3D;
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
            mTransformationChanged = true;
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