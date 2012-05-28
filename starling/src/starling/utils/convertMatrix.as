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
    import flash.geom.Matrix3D;

    /** Converts a 2D matrix to a 3D matrix. If you pass a 'resultMatrix',  
     *  the result will be stored in this matrix instead of creating a new object. */
    public function convertMatrix(matrix:Matrix, resultMatrix:Matrix3D=null):Matrix3D
    {
        if (resultMatrix == null) resultMatrix = new Matrix3D();
        
        rawData[0] = matrix.a;
        rawData[1] = matrix.b;
        rawData[4] = matrix.c;
        rawData[5] = matrix.d;
        rawData[12] = matrix.tx;
        rawData[13] = matrix.ty;
        
        resultMatrix.copyRawDataFrom(rawData);
        return resultMatrix;
    }
}

var rawData:Vector.<Number> = new <Number>[1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1];