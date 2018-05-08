// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
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

    import starling.core.starling_internal;
    import starling.events.Event;
    import starling.rendering.Painter;
    import starling.utils.MathUtil;
    import starling.utils.MatrixUtil;
    import starling.utils.rad2deg;

    use namespace starling_internal;

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
     *  <p>On rendering, each Sprite3D requires its own draw call — except if the object does not
     *  contain any 3D transformations ('z', 'rotationX/Y' and 'pivotZ' are zero). Furthermore,
     *  it interrupts the render cache, i.e. the cache cannot contain objects within different
     *  3D coordinate systems. Flat contents within the Sprite3D will be cached, though.</p>
     *
     */
    public class Sprite3D extends DisplayObjectContainer
    {
        private static const E:Number = 0.00001;

        private var _rotationX:Number;
        private var _rotationY:Number;
        private var _scaleZ:Number;
        private var _pivotZ:Number;
        private var _z:Number;

        /** Helper objects. */
        private static var sHelperPoint:Vector3D    = new Vector3D();
        private static var sHelperPointAlt:Vector3D = new Vector3D();
        private static var sHelperMatrix:Matrix3D   = new Matrix3D();

        /** Creates an empty Sprite3D. */
        public function Sprite3D()
        {
            _scaleZ = 1.0;
            _rotationX = _rotationY = _pivotZ = _z = 0.0;
            setIs3D(true);

            addEventListener(Event.ADDED, onAddedChild);
            addEventListener(Event.REMOVED, onRemovedChild);
        }

        /** @inheritDoc */
        override public function render(painter:Painter):void
        {
            if (isFlat) super.render(painter);
            else
            {
                painter.finishMeshBatch();
                painter.pushState();
                painter.state.transformModelviewMatrix3D(transformationMatrix3D);

                super.render(painter);

                painter.finishMeshBatch();
                painter.excludeFromCache(this);
                painter.popState();
            }
        }

        /** @inheritDoc */
        override public function hitTest(localPoint:Point):DisplayObject
        {
            if (isFlat) return super.hitTest(localPoint);
            else
            {
                if (!visible || !touchable) return null;

                // We calculate the interception point between the 3D plane that is spawned up
                // by this sprite3D and the straight line between the camera and the hit point.

                sHelperMatrix.copyFrom(transformationMatrix3D);
                sHelperMatrix.invert();

                stage.getCameraPosition(this, sHelperPoint);
                MatrixUtil.transformCoords3D(sHelperMatrix, localPoint.x, localPoint.y, 0, sHelperPointAlt);
                MathUtil.intersectLineWithXYPlane(sHelperPoint, sHelperPointAlt, localPoint);

                return super.hitTest(localPoint);
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

        override starling_internal function updateTransformationMatrices(
            x:Number, y:Number, pivotX:Number, pivotY:Number, scaleX:Number, scaleY:Number,
            skewX:Number, skewY:Number, rotation:Number, out:Matrix, out3D:Matrix3D):void
        {
            if (isFlat) super.updateTransformationMatrices(
                x, y, pivotX, pivotY, scaleX, scaleY, skewX, skewY, rotation, out, out3D);
            else updateTransformationMatrices3D(
                x, y, _z, pivotX, pivotY, _pivotZ, scaleX, scaleY, _scaleZ,
                _rotationX, _rotationY, rotation, out, out3D);
        }

        starling_internal function updateTransformationMatrices3D(
            x:Number, y:Number, z:Number,
            pivotX:Number, pivotY:Number, pivotZ:Number,
            scaleX:Number, scaleY:Number, scaleZ:Number,
            rotationX:Number, rotationY:Number, rotationZ:Number,
            out:Matrix, out3D:Matrix3D):void
        {
            out.identity();
            out3D.identity();

            if (scaleX != 1.0 || scaleY != 1.0 || scaleZ != 1.0)
                out3D.appendScale(scaleX || E , scaleY || E, scaleZ || E);
            if (rotationX != 0.0)
                out3D.appendRotation(rad2deg(rotationX), Vector3D.X_AXIS);
            if (rotationY != 0.0)
                out3D.appendRotation(rad2deg(rotationY), Vector3D.Y_AXIS);
            if (rotationZ != 0.0)
                out3D.appendRotation(rad2deg(rotationZ), Vector3D.Z_AXIS);
            if (x != 0.0 || y != 0.0 || z != 0.0)
                out3D.appendTranslation(x, y, z);
            if (pivotX != 0.0 || pivotY != 0.0 || pivotZ != 0.0)
                out3D.prependTranslation(-pivotX, -pivotY, -pivotZ);
        }

        // properties

        public override function set transformationMatrix(value:Matrix):void
        {
            super.transformationMatrix = value;
            _rotationX = _rotationY = _pivotZ = _z = 0;
            setTransformationChanged();
        }

        /** The z coordinate of the object relative to the local coordinates of the parent.
         *  The z-axis points away from the camera, i.e. positive z-values will move the object further
         *  away from the viewer. */
        public function get z():Number { return _z; }
        public function set z(value:Number):void
        {
            _z = value;
            setTransformationChanged();
        }

        /** The z coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotZ():Number { return _pivotZ; }
        public function set pivotZ(value:Number):void
        {
            _pivotZ = value;
            setTransformationChanged();
        }

        /** The depth scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleZ():Number { return _scaleZ; }
        public function set scaleZ(value:Number):void
        {
            _scaleZ = value;
            setTransformationChanged();
        }

        /** @private */
        override public function set scale(value:Number):void
        {
            scaleX = scaleY = scaleZ = value;
        }

        /** @private */
        public override function set skewX(value:Number):void
        {
            throw new Error("3D objects do not support skewing");

            // super.skewX = value;
            // _orientationChanged = true;
        }

        /** @private */
        public override function set skewY(value:Number):void
        {
            throw new Error("3D objects do not support skewing");

            // super.skewY = value;
            // _orientationChanged = true;
        }

        /** The rotation of the object about the x axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationX():Number { return _rotationX; }
        public function set rotationX(value:Number):void
        {
            _rotationX = MathUtil.normalizeAngle(value);
            setTransformationChanged();
        }

        /** The rotation of the object about the y axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationY():Number { return _rotationY; }
        public function set rotationY(value:Number):void
        {
            _rotationY = MathUtil.normalizeAngle(value);
            setTransformationChanged();
        }

        /** The rotation of the object about the z axis, in radians.
         *  (In Starling, all angles are measured in radians.) */
        public function get rotationZ():Number { return rotation; }
        public function set rotationZ(value:Number):void { rotation = value; }

        /** If <code>true</code>, this 3D object contains only 2D content.
         *  This means that rendering will be just as efficient as for a standard 2D object. */
        public function get isFlat():Boolean
        {
            return _z > -E && _z < E &&
                   _rotationX > -E && _rotationX < E &&
                   _rotationY > -E && _rotationY < E &&
                   _pivotZ > -E && _pivotZ < E;
        }
    }
}