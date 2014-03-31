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
            while (args.length < func.length)
                args.push(null);

            if      (func.length == 0) func();
            else if (func.length == 1) func(args[0]);
            else if (func.length == 2) func(args[0], args[1]);
            else if (func.length == 3) func(args[0], args[1], args[2]);
            else if (func.length == 4) func(args[0], args[1], args[2], args[3]);
            else if (func.length == 5) func(args[0], args[1], args[2], args[3], args[4]);
            else if (func.length == 6) func(args[0], args[1], args[2], args[3], args[4], args[5]);
            else throw new ArgumentError("'execute' is limited to 6 parameters.");
        }
    }
}
