// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.errors.AbstractClassError;

    /** A utility class containing methods related to the Rectangle class. */
    public class RectangleUtil
    {
        /** Helper objects. */
        private static const sHelperPoint:Point = new Point();
        private static const sPositions:Vector.<Point> =
            new <Point>[ new Point(0, 0), new Point(1, 0), new Point(0, 1), new Point(1, 1) ];

        /** @private */
        public function RectangleUtil() { throw new AbstractClassError(); }
        
        /** Calculates the intersection between two Rectangles. If the rectangles do not intersect,
         *  this method returns an empty Rectangle object with its properties set to 0. */
        public static function intersect(rect1:Rectangle, rect2:Rectangle, 
                                         resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var left:Number   = rect1.x      > rect2.x      ? rect1.x      : rect2.x;
            var right:Number  = rect1.right  < rect2.right  ? rect1.right  : rect2.right;
            var top:Number    = rect1.y      > rect2.y      ? rect1.y      : rect2.y;
            var bottom:Number = rect1.bottom < rect2.bottom ? rect1.bottom : rect2.bottom;
            
            if (left > right || top > bottom)
                resultRect.setEmpty();
            else
                resultRect.setTo(left, top, right-left, bottom-top);
            
            return resultRect;
        }
        
        /** Calculates a rectangle with the same aspect ratio as the given 'rectangle',
         *  centered within 'into'.  
         * 
         *  <p>This method is useful for calculating the optimal viewPort for a certain display 
         *  size. You can use different scale modes to specify how the result should be calculated;
         *  furthermore, you can avoid pixel alignment errors by only allowing whole-number  
         *  multipliers/divisors (e.g. 3, 2, 1, 1/2, 1/3).</p>
         *  
         *  @see starling.utils.ScaleMode
         */
        public static function fit(rectangle:Rectangle, into:Rectangle, 
                                   scaleMode:String="showAll", pixelPerfect:Boolean=false,
                                   resultRect:Rectangle=null):Rectangle
        {
            if (!ScaleMode.isValid(scaleMode)) throw new ArgumentError("Invalid scaleMode: " + scaleMode);
            if (resultRect == null) resultRect = new Rectangle();
            
            var width:Number   = rectangle.width;
            var height:Number  = rectangle.height;
            var factorX:Number = into.width  / width;
            var factorY:Number = into.height / height;
            var factor:Number  = 1.0;
            
            if (scaleMode == ScaleMode.SHOW_ALL)
            {
                factor = factorX < factorY ? factorX : factorY;
                if (pixelPerfect) factor = nextSuitableScaleFactor(factor, false);
            }
            else if (scaleMode == ScaleMode.NO_BORDER)
            {
                factor = factorX > factorY ? factorX : factorY;
                if (pixelPerfect) factor = nextSuitableScaleFactor(factor, true);
            }
            
            width  *= factor;
            height *= factor;
            
            resultRect.setTo(
                into.x + (into.width  - width)  / 2,
                into.y + (into.height - height) / 2,
                width, height);
            
            return resultRect;
        }
        
        /** Calculates the next whole-number multiplier or divisor, moving either up or down. */
        private static function nextSuitableScaleFactor(factor:Number, up:Boolean):Number
        {
            var divisor:Number = 1.0;
            
            if (up)
            {
                if (factor >= 0.5) return Math.ceil(factor);
                else
                {
                    while (1.0 / (divisor + 1) > factor)
                        ++divisor;
                }
            }
            else
            {
                if (factor >= 1.0) return Math.floor(factor);
                else
                {
                    while (1.0 / divisor > factor)
                        ++divisor;
                }
            }
            
            return 1.0 / divisor;
        }
        
        /** If the rectangle contains negative values for width or height, all coordinates
         *  are adjusted so that the rectangle describes the same region with positive values. */
        public static function normalize(rect:Rectangle):void
        {
            if (rect.width < 0)
            {
                rect.width = -rect.width;
                rect.x -= rect.width;
            }
            
            if (rect.height < 0)
            {
                rect.height = -rect.height;
                rect.y -= rect.height;
            }
        }

        /** Calculates the bounds of a rectangle after transforming it by a matrix.
         *  If you pass a 'resultRect', the result will be stored in this rectangle
         *  instead of creating a new object. */
        public static function getBounds(rectangle:Rectangle, transformationMatrix:Matrix,
                                         resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            
            for (var i:int=0; i<4; ++i)
            {
                MatrixUtil.transformCoords(transformationMatrix,
                    sPositions[i].x * rectangle.width, sPositions[i].y * rectangle.height,
                    sHelperPoint);
                
                if (minX > sHelperPoint.x) minX = sHelperPoint.x;
                if (maxX < sHelperPoint.x) maxX = sHelperPoint.x;
                if (minY > sHelperPoint.y) minY = sHelperPoint.y;
                if (maxY < sHelperPoint.y) maxY = sHelperPoint.y;
            }
            
            resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
            return resultRect;
        }
    }
}