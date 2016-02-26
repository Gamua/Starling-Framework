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
    // TODO: add number formatting options
    
    /** Formats a String in .Net-style, with curly braces ("{0}"). Does not support any 
     *  number formatting options yet. */
    public function formatString(format:String, ...args):String
    {
        for (var i:int=0; i<args.length; ++i)
            format = format.replace(new RegExp("\\{"+i+"\\}", "g"), args[i]);
        
        return format;
    }
}