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
    import flash.geom.Rectangle;
    
    import starling.errors.AbstractClassError;

    /** A utility class containing methods related to the Rectangle class. */
    public class RectangleUtil
    {
        /** @private */
        public function RectangleUtil() { throw new AbstractClassError(); }
        
        /** Calculates the intersection between two Rectangles. If the rectangles do not intersect,
         *  this method returns an empty Rectangle object with its properties set to 0. */
        public static function intersect(rect1:Rectangle, rect2:Rectangle, 
                                         resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var left:Number   = Math.max(rect1.x, rect2.x);
            var right:Number  = Math.min(rect1.x + rect1.width, rect2.x + rect2.width);
            var top:Number    = Math.max(rect1.y, rect2.y);
            var bottom:Number = Math.min(rect1.y + rect1.height, rect2.y + rect2.height);
            
            if (left > right || top > bottom)
                resultRect.setEmpty();
            else
                resultRect.setTo(left, top, right-left, bottom-top);
            
            return resultRect;
        }
        
        /** Calculates a rectangle with the same aspect ratio as the given 'rectangle',
         *  centered within 'into'. Optionally, the rectangle will be scaled to the biggest 
         *  possible size (so that no cropping occurs). This method is useful for calculating  
         *  the optimal viewPort for a certain display size. */
        public static function fit(rectangle:Rectangle, into:Rectangle, scale:Boolean=true,
                                   resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var width:Number  = rectangle.width;
            var height:Number = rectangle.height;
            
            if (scale)
            {
                var factorX:Number = into.width  / width;
                var factorY:Number = into.height / height;
                var factor:Number  = factorX < factorY ? factorX : factorY;
                
                width  *= factor;
                height *= factor;
            }
            
            resultRect.setTo(
                into.x + (into.width  - width)  / 2,
                into.y + (into.height - height) / 2,
                width, height);
            
            return resultRect;
        }
    }
}