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
    import starling.errors.AbstractClassError;

    /** A class that provides constant values for vertical alignment of objects. */
    public final class VAlign
    {
        /** @private */
        public function VAlign() { throw new AbstractClassError(); }
        
        /** Top alignment. */
        public static const TOP:String    = "top";
        
        /** Centered alignment. */
        public static const CENTER:String = "center";
        
        /** Bottom alignment. */
        public static const BOTTOM:String = "bottom";
        
        /** Indicates whether the given alignment string is valid. */
        public static function isValid(vAlign:String):Boolean
        {
            return vAlign == TOP || vAlign == CENTER || vAlign == BOTTOM;
        }
    }
}