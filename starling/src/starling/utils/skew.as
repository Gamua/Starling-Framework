// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    import flash.geom.Matrix;

    /** Appends a skew transformation to a matrix, with angles in radians. */
    public function skew(matrix:Matrix, skewX:Number, skewY:Number):void
    {
        var a:Number = matrix.a;
        var b:Number = matrix.b;
        var c:Number = matrix.c;
        var d:Number = matrix.d;
        var sinX:Number = Math.sin(skewX);
        var cosX:Number = Math.cos(skewX);
        var sinY:Number = Math.sin(skewY);
        var cosY:Number = Math.cos(skewY);

        matrix.a = a*cosY - b*sinX;
        matrix.b = a*sinY + b*cosX;
        matrix.c = c*cosY - d*sinX;
        matrix.d = c*sinY + d*cosX;
    }
}
