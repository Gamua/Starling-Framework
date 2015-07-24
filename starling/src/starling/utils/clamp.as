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
    /** Moves 'value' into the range between 'min' and 'max'. */
    public function clamp(value:Number, min:Number, max:Number):Number
    {
        return value < min ? min : (value > max ? max : value);
    }
}
