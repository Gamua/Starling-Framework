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
    /** Returns the next power of two that is equal to or bigger than the specified number. */
    public function getNextPowerOfTwo(number:Number):int
    {
        if (number is int && number > 0 && (number & (number - 1)) == 0) // see: http://goo.gl/D9kPj
            return number;
        else
        {
            var result:int = 1;
            number -= 0.000000001; // avoid floating point rounding errors

            while (result < number) result <<= 1;
            return result;
        }
    }
}