// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Point;
    import flash.geom.Vector3D;

    import starling.errors.AbstractClassError;

    /** A utility class containing methods you might need for maths problems. */
    public class MathUtil
    {
        private static const TWO_PI:Number = Math.PI * 2.0;

        /** @private */
        public function MathUtil() { throw new AbstractClassError(); }

        /** Calculates the intersection point between the xy-plane and an infinite line
         *  that is defined by two 3D points. */
        public static function intersectLineWithXYPlane(pointA:Vector3D, pointB:Vector3D,
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

        /** Moves a radian angle into the range [-PI, +PI], while keeping the direction intact. */
        public static function normalizeAngle(angle:Number):Number
        {
            // move to equivalent value in range [0 deg, 360 deg] without a loop
            angle = angle % TWO_PI;

            // move to [-180 deg, +180 deg]
            if (angle < -Math.PI) angle += TWO_PI;
            if (angle >  Math.PI) angle -= TWO_PI;

            return angle;
        }

        /** Moves 'value' into the range between 'min' and 'max'. */
        public static function clamp(value:Number, min:Number, max:Number):Number
        {
            return value < min ? min : (value > max ? max : value);
        }
    }
}