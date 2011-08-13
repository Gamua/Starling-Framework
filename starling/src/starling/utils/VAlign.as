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
    import starling.errors.AbstractClassError;

    public final class VAlign
    {
        public function VAlign() { throw new AbstractClassError(); }
        
        public static const TOP:String    = "top";
        public static const CENTER:String = "center";
        public static const BOTTOM:String = "bottom";
        
        public static function isValid(vAlign:String):Boolean
        {
            return vAlign == TOP || vAlign == CENTER || vAlign == BOTTOM;
        }
    }
}