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
    /** Returns the next power of two that is equal to or bigger than the specified number. */
    public function getNextPowerOfTwo(number:int):int
    {
        var result:int = 1;
        while (result < number) result *= 2;
        return result;   
    }
}