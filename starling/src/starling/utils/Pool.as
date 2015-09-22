// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.errors.AbstractClassError;

    /** A simple object pool supporting the most basic utility objects.
     *
     *  <p>If you want to retrieve an object, but the pool does not contain any more instances,
     *  it will silently create a new one.</p>
     *
     *  <p>It's important that you use the pool in a balanced way, i.e. don't just "get" or "put"
     *  alone! Always make the calls in pairs; whenever you get an object, be sure to put it back
     *  later, and the other way round. Otherwise, the pool will empty or (even worse) grow
     *  in size uncontrolled.</p>
     */
    public class Pool
    {
        private static var sPoints:Vector.<Point> = new <Point>[];
        private static var sMatrices:Vector.<Matrix> = new <Matrix>[];
        private static var sMatrices3D:Vector.<Matrix3D> = new <Matrix3D>[];
        private static var sRectangles:Vector.<Rectangle> = new <Rectangle>[];

        /** @private */
        public function Pool() { throw new AbstractClassError(); }

        /** Retrieves a Point instance from the pool.
         *  @param origin   If enabled, the point will be reset to zero coordinates.
         */
        public static function getPoint(origin:Boolean=false):Point
        {
            if (sPoints.length == 0) return new Point();
            else
            {
                var point:Point = sPoints.pop();
                if (origin) point.setTo(0, 0);
                return point;
            }
        }

        /** Stores a Point instance in the pool. Don't keep any references to the object
         *  after moving it to the pool! */
        public static function putPoint(point:Point):void
        {
            if (point) sPoints[sPoints.length] = point;
        }

        /** Retrieves a Matrix instance from the pool.
         *  @param identity   If enabled, the matrix will be reset to the identity.
         */
        public static function getMatrix(identity:Boolean=false):Matrix
        {
            if (sMatrices.length == 0) return new Matrix();
            else
            {
                var matrix:Matrix = sMatrices.pop();
                if (identity) matrix.identity();
                return matrix;
            }
        }

        /** Stores a Matrix instance in the pool. Don't keep any references to the object
         *  after moving it to the pool! */
        public static function putMatrix(matrix:Matrix):void
        {
            if (matrix) sMatrices[sMatrices.length] = matrix;
        }

        /** Retrieves a Matrix3D instance from the pool.
         *  @param identity   If enabled, the matrix will be reset to the identity.
         */
        public static function getMatrix3D(identity:Boolean=false):Matrix3D
        {
            if (sMatrices3D.length == 0) return new Matrix3D();
            else
            {
                var matrix:Matrix3D = sMatrices3D.pop();
                if (identity) matrix.identity();
                return matrix;
            }
        }

        /** Stores a Matrix3D instance in the pool. Don't keep any references to the object
         *  after moving it to the pool! */
        public static function putMatrix3D(matrix:Matrix3D):void
        {
            if (matrix) sMatrices3D[sMatrices3D.length] = matrix;
        }

        /** Retrieves a Rectangle instance from the pool.
         *  @param empty   If enabled, the rectangle will be reset to zero values.
         */
        public static function getRectangle(empty:Boolean=false):Rectangle
        {
            if (sRectangles.length == 0) return new Rectangle();
            else
            {
                var rectangle:Rectangle = sRectangles.pop();
                if (empty) rectangle.setEmpty();
                return rectangle;
            }
        }

        /** Stores a Rectangle instance in the pool. Don't keep any references to the object
         *  after moving it to the pool! */
        public static function putRectangle(rectangle:Rectangle):void
        {
            if (rectangle) sRectangles[sRectangles.length] = rectangle;
        }
    }
}
