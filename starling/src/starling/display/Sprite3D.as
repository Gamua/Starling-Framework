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

    /** A container that allows you to position objects in three-dimensional space.
     *
     *  <p>Starling is, at its heart, a 2D engine. However, sometimes, simple 3D effects are
     *  useful for special effects, e.g. for screen transitions or to turn playing cards
     *  realistically. This class makes it possible to create such 3D effects.</p>
     *
     *  <p><strong>Positioning objects in 3D</strong></p>
     *
     *  <p>Just like a normal sprite, you can add and remove children to this container, which
     *  allows you to group several display objects together. In addition to that, Sprite3D
     *  adds some interesting properties:</p>
     *
     *  <ul>
     *    <li>z - Moves the sprite closer to / further away from the camera.</li>
     *    <li>rotationX — Rotates the sprite around the x-axis.</li>
     *    <li>rotationY — Rotates the sprite around the y-axis.</li>
     *    <li>scaleZ - Scales the sprite along the z-axis.</li>
     *    <li>pivotZ - Moves the pivot point along the z-axis.</li>
     *  </ul>
     *
     *  <p>With the help of these properties, you can move a sprite and all its children in the
     *  3D space. By nesting several Sprite3D containers, it's even possible to construct simple
     *  volumetric objects (like a cube).</p>
     *
     *  <p>Note that Starling does not make any z-tests: visibility is solely established by the
     *  order of the children, just as with 2D objects.</p>
     *
     *  <p><strong>Setting up the camera</strong></p>
     *
     *  <p>The camera settings are found directly on the stage. Modify the 'focalLength' or
     *  'fieldOfView' properties to change the distance between stage and camera; use the
     *  'projectionOffset' to move it to a different position.</p>
     *
     *  <p><strong>Limitations</strong></p>
     *
     *  <p>A Sprite3D object cannot be flattened (although you can flatten objects <em>within</em>
     *  a Sprite3D), and it does not work with the "clipRect" property. Furthermore, a filter
     *  applied to a Sprite3D object cannot be cached.</p>
     *
     *  <p>On rendering, each Sprite3D requires its own draw call — except if the object does not
     *  contain any 3D transformations ('z', 'rotationX/Y' and 'pivotZ' are zero).</p>
     *
     */
    public class Sprite3D extends DisplayObjectContainer
    {
        private static const E:Number = 0.00001;

        private var mRotationX:Number;
        private var mRotationY:Number;
        private var mScaleZ:Number;
        private var mPivotZ:Number;
        private var mZ:Number;

        private var mTransformationMatrix:Matrix;
        private var mTransformationMatrix3D:Matrix3D;
        private var mTransformationChanged:Boolean;

        /** Helper objects. */
        private static var sHelperPoint:Vector3D    = new Vector3D();
        private static var sHelperPointAlt:Vector3D = new Vector3D();
        private static var sHelperMatrix:Matrix3D   = new Matrix3D();

        /** Creates an empty Sprite3D. */
        public function Sprite3D()
        {
            mScaleZ = 1.0;
            mRotationX = mRotationY = mPivotZ = mZ = 0.0;
            mTransformationMatrix = new Matrix();
            mTransformationMatrix3D = new Matrix3D();
            setIs3D(true);

            addEventListener(Event.ADDED, onAddedChild);
            addEventListener(Event.REMOVED, onRemovedChild);
        }

        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            if (is2D) super.render(support, parentAlpha);
            else
            {
                support.finishQuadBatch();
                support.pushMatrix3D();
                support.transformMatrix3D(this);

                super.render(support, parentAlpha);

                support.finishQuadBatch();
                support.popMatrix3D();
            }
        }

        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (is2D) return super.hitTest(localPoint, forTouch);
            else
            {
                if (forTouch && (!visible || !touchable))
                    return null;

                // We calculate the interception point between the 3D plane that is spawned up
                // by this sprite3D and the straight line between the camera and the hit point.

                sHelperMatrix.copyFrom(transformationMatrix3D);
                sHelperMatrix.invert();

                stage.getCameraPosition(this, sHelperPoint);
                MatrixUtil.transformCoords3D(sHelperMatrix, localPoint.x, localPoint.y, 0, sHelperPointAlt);
                MathUtil.intersectLineWithXYPlane(sHelperPoint, sHelperPointAlt, localPoint);

                return super.hitTest(localPoint, forTouch);
            }
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

        private function updateMatrices():void
        {
            var x:Number = this.x;
            var y:Number = this.y;
            var scaleX:Number = this.scaleX;
            var scaleY:Number = this.scaleY;
            var pivotX:Number = this.pivotX;
            var pivotY:Number = this.pivotY;
            var rotationZ:Number = this.rotation;

            mTransformationMatrix3D.identity();

            if (scaleX != 1.0 || scaleY != 1.0 || mScaleZ != 1.0)
                mTransformationMatrix3D.appendScale(scaleX || E , scaleY || E, mScaleZ || E);
            if (mRotationX != 0.0)
                mTransformationMatrix3D.appendRotation(rad2deg(mRotationX), Vector3D.X_AXIS);
            if (mRotationY != 0.0)
                mTransformationMatrix3D.appendRotation(rad2deg(mRotationY), Vector3D.Y_AXIS);
            if (rotationZ != 0.0)
                mTransformationMatrix3D.appendRotation(rad2deg( rotationZ), Vector3D.Z_AXIS);
            if (x != 0.0 || y != 0.0 || mZ != 0.0)
                mTransformationMatrix3D.appendTranslation(x, y, mZ);
            if (pivotX != 0.0 || pivotY != 0.0 || mPivotZ != 0.0)
                mTransformationMatrix3D.prependTranslation(-pivotX, -pivotY, -mPivotZ);

            if (is2D) MatrixUtil.convertTo2D(mTransformationMatrix3D, mTransformationMatrix);
            else      mTransformationMatrix.identity();
        }

        /** Indicates if the object can be represented by a 2D transformation. */
        [Inline]
        private final function get is2D():Boolean
        {
            return mZ > -E && mZ < E &&
                mRotationX > -E && mRotationX < E &&
                mRotationY > -E && mRotationY < E &&
                mPivotZ > -E && mPivotZ < E;
        }

        // properties

        /** The 2D transformation matrix of the object relative to its parent — if it can be
         *  represented in such a matrix (the values of 'z', 'rotationX/Y', and 'pivotZ' are
         *  zero). Otherwise, the identity matrix. CAUTION: not a copy, but the actual object! */
        public override function get transformationMatrix():Matrix
        {
            if (mTransformationChanged)
            {
                updateMatrices();
                mTransformationChanged = false;
            }

            return mTransformationMatrix;
        }

        public override function set transformationMatrix(value:Matrix):void
        {
            super.transformationMatrix = value;
            mRotationX = mRotationY = mPivotZ = mZ = 0;
            mTransformationChanged = true;
        }

        /**  The 3D transformation matrix of the object relative to its parent.
         *   CAUTION: not a copy, but the actual object! */
        public override function get transformationMatrix3D():Matrix3D
        {
            if (mTransformationChanged)
            {
                updateMatrices();
                mTransformationChanged = false;
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

        /** The z coordinate of the object relative to the local coordinates of the parent.
         *  The z-axis points away from the camera, i.e. positive z-values will move the object further
         *  away from the viewer. */
        public function get z():Number { return mZ; }
        public function set z(value:Number):void
        {
            mZ = value;
            mTransformationChanged = true;
        }

        /** @inheritDoc */
        public override function set pivotX(value:Number):void
        {
             super.pivotX = value;
             mTransformationChanged = true;
        }

        /** @inheritDoc */
        public override function set pivotY(value:Number):void
        {
             super.pivotY = value;
             mTransformationChanged = true;
        }

        /** The z coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotZ():Number { return mPivotZ; }
        public function set pivotZ(value:Number):void
        {
            mPivotZ = value;
            mTransformationChanged = true;
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

        /** The depth scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleZ():Number { return mScaleZ; }
        public function set scaleZ(value:Number):void
        {
            mScaleZ = value;
            mTransformationChanged = true;
        }

        /** @private */
        public override function set skewX(value:Number):void
        {
            throw new Error("3D objects do not support skewing");

            // super.skewX = value;
            // mOrientationChanged = true;
        }

        /** @private */
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
            mRotationX = MathUtil.normalizeAngle(value);
            mTransformationChanged = true;
        }

        /** The rotation of the object about the y axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationY():Number { return mRotationY; }
        public function set rotationY(value:Number):void
        {
            mRotationY = MathUtil.normalizeAngle(value);
            mTransformationChanged = true;
        }

        /** The rotation of the object about the z axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationZ():Number { return rotation; }
        public function set rotationZ(value:Number):void { rotation = value; }
    }
}