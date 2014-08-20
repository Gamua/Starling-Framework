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
    import starling.geom.Cuboid;
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
        private static var sHelperPoint:Vector3D   = new Vector3D();
        private static var sHelperPoint2:Vector3D  = new Vector3D();
        private static var sHelperMatrix:Matrix3D  = new Matrix3D();
        private static var sHelperCuboid:Cuboid = new Cuboid();
        private static var sHelperPoint2D:Point = new Point();

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

            var bounds3D:Cuboid = getBounds3D(targetSpace, sHelperCuboid);
            var camPosGlobal:Vector3D = new Vector3D(stage.stageWidth  / 2,
                                                     stage.stageHeight / 2, -500);
            var camPos:Vector3D = targetSpace.globalToLocal3D(camPosGlobal, sHelperPoint);

            var bounds3DVertex:Vector3D = sHelperPoint2;
            var bounds2DVertex:Point = sHelperPoint2D;
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;

            for (var i:int=0; i<8; ++i)
            {
                bounds3D.getVertex(i, bounds3DVertex);
                intersectLineWithXYPlane(camPos, bounds3DVertex, bounds2DVertex);

                if (minX > bounds2DVertex.x) minX = bounds2DVertex.x;
                if (maxX < bounds2DVertex.x) maxX = bounds2DVertex.x;
                if (minY > bounds2DVertex.y) minY = bounds2DVertex.y;
                if (maxY < bounds2DVertex.y) maxY = bounds2DVertex.y;
            }

            resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
            return resultRect;
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

            // todo: this should be a property on the stage
            var camPosGlobal:Vector3D = new Vector3D(stage.stageWidth  / 2,
                                                     stage.stageHeight / 2, -500);
            var camPosLocal:Vector3D = globalToLocal3D(camPosGlobal, sHelperPoint);
            var localPoint3D:Vector3D = MatrixUtil.transformCoords3D(
                sHelperMatrix, localPoint.x, localPoint.y, 0, sHelperPoint2);

            intersectLineWithXYPlane(localPoint3D, camPosLocal, localPoint);

            return super.hitTest(localPoint, forTouch);
        }

        // helpers

        private function intersectLineWithXYPlane(pointA:Vector3D, pointB:Vector3D,
                                                  resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();

            var vectorX:Number = pointB.x - pointA.x;
            var vectorY:Number = pointB.y - pointA.y;
            var vectorZ:Number = pointB.z - pointA.z;
            var lambda:Number = -pointA.z / vectorZ;

            resultPoint.x = pointA.x + lambda * vectorX;
            resultPoint.y = pointA.y + lambda * vectorY;

            return resultPoint;
        }

        // properties

        /** Always returns the identity matrix. The actual transformation of a Sprite3D
         *  is stored in 'transformationMatrix3D'. */
        public override function get transformationMatrix():Matrix
        {
            // We always return the identity matrix! The actual transformation is stored in
            // the 3D matrix; a 2D matrix cannot represent 3D transformations.

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