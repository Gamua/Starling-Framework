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
    import starling.errors.AbstractClassError;

    /** A utility class with methods related to the String class. */
    public class StringUtil
    {
        /** @private */
        public function StringUtil() { throw new AbstractClassError(); }

        /** Formats a String in .Net-style, with curly braces ("{0}"). Does not support any
         *  number formatting options yet. */
        public static function format(format:String, ...args):String
        {
            // TODO: add number formatting options

            for (var i:int=0; i<args.length; ++i)
                format = format.replace(new RegExp("\\{"+i+"\\}", "g"), args[i]);

            return format;
        }

        /** Replaces a string's "master string" — the string it was built from —
         *  with a single character to save memory. Find more information about this AS3 oddity
         *  <a href="http://jacksondunstan.com/articles/2260">here</a>.
         *
         *  @param  str String to clean
         *  @return The input string, but with a master string only one character larger than it.
         *  @author Jackson Dunstan, JacksonDunstan.com
         */
        public static function clean(str:String):String
        {
            return ("_" + str).substr(1);
        }
    }
}
