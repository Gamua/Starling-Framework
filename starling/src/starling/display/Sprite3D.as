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
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;

    import starling.core.RenderSupport;
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
        private static var sAncestors:Vector.<DisplayObject> = new <DisplayObject>[];
        private static var sHelperPoint:Vector3D   = new Vector3D();
        private static var sHelperPoint2:Vector3D  = new Vector3D();
        private static var sHelperMatrix:Matrix3D  = new Matrix3D();
        private static var sHelperMatrix2:Matrix3D = new Matrix3D();
        private static var sMatrixData:Vector.<Number> =
            new <Number>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];


        public function Sprite3D()
        {
            mRotationX = mRotationY = mZ = 0.0;
            mTransformationMatrix = new Matrix();
            mTransformationMatrix3D = new Matrix3D();
        }

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
        public override function getBounds(targetSpace:DisplayObject,
                                           resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();

            // todo

            return resultRect;
        }

        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;

            // We calculate the interception point between the 3D plane that is spawned up
            // by this sprite3D and the straight line between the camera and the hit point.

            // todo: this should be a property on the stage
            var camPosGlobal:Vector3D = new Vector3D(stage.stageWidth  / 2,
                                                     stage.stageHeight / 2, -500);
            var camPosLocal:Vector3D = globalToLocal3D(camPosGlobal, sHelperPoint);

            // do not move these lines up! 'sHelperMatrix' is also used by 'globalToLocal3D'.
            sHelperMatrix.copyFrom(transformationMatrix3D);
            sHelperMatrix.invert();

            var localPoint3D:Vector3D = MatrixUtil.transformCoords3D(
                sHelperMatrix, localPoint.x, localPoint.y, 0, sHelperPoint2);
            var camRay3D_x:Number = localPoint3D.x - camPosLocal.x;
            var camRay3D_y:Number = localPoint3D.y - camPosLocal.y;
            var camRay3D_z:Number = localPoint3D.z - camPosLocal.z;
            var lambda:Number = -camPosLocal.z / camRay3D_z;

            localPoint.x = camPosLocal.x + lambda * camRay3D_x;
            localPoint.y = camPosLocal.y + lambda * camRay3D_y;

            return super.hitTest(localPoint, forTouch);
        }

        /** Creates a matrix that represents the transformation from the local coordinate system
         *  to another. If you pass a 'resultMatrix', the result will be stored in this matrix
         *  instead of creating a new object. */
        public function getTransformationMatrix3D(targetSpace:DisplayObject,
                                                  resultMatrix:Matrix3D=null):Matrix3D
        {
            var commonParent:DisplayObject;
            var currentObject:DisplayObject;

            if (resultMatrix) resultMatrix.identity();
            else resultMatrix = new Matrix3D();

            if (targetSpace == this)
            {
                return resultMatrix;
            }
            else if (targetSpace == parent || (targetSpace == null && parent == null))
            {
                resultMatrix.copyFrom(transformationMatrix3D);
                return resultMatrix;
            }
            else if (targetSpace == null || targetSpace == base)
            {
                // targetCoordinateSpace 'null' represents the target space of the base object.
                // -> move up from this to base

                currentObject = this;
                while (currentObject != targetSpace)
                {
                    resultMatrix.append(getTransformationMatrixFrom(currentObject));
                    currentObject = currentObject.parent;
                }

                return resultMatrix;
            }
            else if (targetSpace.parent == this) // optimization
            {
                getTransformationMatrixFrom(this, resultMatrix);
                resultMatrix.invert();

                return resultMatrix;
            }

            // 1. find a common parent of this and the target space

            commonParent = null;
            currentObject = this;

            while (currentObject)
            {
                sAncestors[sAncestors.length] = currentObject; // avoiding 'push'
                currentObject = currentObject.parent;
            }

            currentObject = targetSpace;
            while (currentObject && sAncestors.indexOf(currentObject) == -1)
                currentObject = currentObject.parent;

            sAncestors.length = 0;

            if (currentObject) commonParent = currentObject;
            else throw new ArgumentError("Object not connected to target");

            // 2. move up from this to common parent

            currentObject = this;
            while (currentObject != commonParent)
            {
                resultMatrix.append(getTransformationMatrixFrom(currentObject));
                currentObject = currentObject.parent;
            }

            if (commonParent == targetSpace)
                return resultMatrix;

            // 3. now move up from target until we reach the common parent

            sHelperMatrix.identity();
            currentObject = targetSpace;
            while (currentObject != commonParent)
            {
                sHelperMatrix.append(getTransformationMatrixFrom(currentObject));
                currentObject = currentObject.parent;
            }

            // 4. now combine the two matrices

            sHelperMatrix.invert();
            resultMatrix.append(sHelperMatrix);

            return resultMatrix;
        }

        private function getTransformationMatrixFrom(object:DisplayObject,
                                                     resultMatrix:Matrix3D=null):Matrix3D
        {
            if (resultMatrix == null) resultMatrix = new Matrix3D();

            if (object is Sprite3D)
                resultMatrix.copyFrom((object as Sprite3D).transformationMatrix3D);
            else
                return MatrixUtil.convertTo3D(object.transformationMatrix, resultMatrix);

            return resultMatrix;
        }

        /** Transforms a point from global (stage) coordinates to the local coordinate system.
         *  If you pass a 'resultPoint', the result will be stored in this point instead of
         *  creating a new object. */
        public function globalToLocal3D(globalPoint:Vector3D, resultPoint:Vector3D=null):Vector3D
        {
            getTransformationMatrix3D(base, sHelperMatrix2);
            sHelperMatrix2.invert();
            return MatrixUtil.transformPoint3D(sHelperMatrix2, globalPoint, resultPoint);
        }

        /** Always returns the identity matrix. The actual transformation of a Sprite3D
         *  is stored in 'transformationMatrix3D'. */
        public override function get transformationMatrix():Matrix
        {
            // We always return the identity matrix!
            // The actual transformation is stored in the 3D matrix.

            return mTransformationMatrix;
        }

        public override function set transformationMatrix(value:Matrix):void
        {
            // todo: test this.

            super.transformationMatrix = value;
            mTransformationChanged = true;
        }

        public function get transformationMatrix3D():Matrix3D
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