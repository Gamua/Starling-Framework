// =================================================================================================
//
//	Starling Framework
//	Copyright 2014 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
    /** Executes a function with the specified arguments. If the argument count does not match
     *  the function, the argument list is cropped / filled up with <code>null</code> values. */
    public function execute(func:Function, ...args):void
    {
        if (func != null)
        {
            for (var i:int=args.length; i<func.length; ++i)
                args[i] = null;

            func.apply(null, args.slice(0, func.length));
        }
    }
}
