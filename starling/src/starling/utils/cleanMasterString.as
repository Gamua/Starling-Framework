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
    /** Replaces a string's "master string" — the string it was built from —
     *  with a single character to save memory. Find more information about this AS3 oddity
     *  <a href="http://jacksondunstan.com/articles/2260">here</a>.
     *
     *  @param  str String to clean
     *  @return The input string, but with a master string only one character larger than it.
     *  @author Jackson Dunstan, JacksonDunstan.com
     */
    public function cleanMasterString(str:String):String
    {
        return ("_" + str).substr(1);
    }
}