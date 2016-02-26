// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;
    import flash.geom.Point;

    /** Uses a matrix to transform 2D coordinates into a different space. If you pass a 
     *  'resultPoint', the result will be stored in this point instead of creating a new object.*/
    public function transformCoords(matrix:Matrix, x:Number, y:Number,
                                    resultPoint:Point=null):Point
    {
        if (!deprecationNotified)
        {
            deprecationNotified = true;
            trace("[Starling] The method 'transformCoords' is deprecated. " + 
                  "Please use 'MatrixUtil.transformCoords' instead.");
        }
        
        if (resultPoint == null) resultPoint = new Point();   
        
        resultPoint.x = matrix.a * x + matrix.c * y + matrix.tx;
        resultPoint.y = matrix.d * y + matrix.b * x + matrix.ty;
        
        return resultPoint;
    }
}

var deprecationNotified:Boolean = false;