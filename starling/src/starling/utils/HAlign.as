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

    public final class HAlign
    {
        public function HAlign() { throw new AbstractClassError(); }
        
        public static const LEFT:String   = "left";
        public static const CENTER:String = "center";
        public static const RIGHT:String  = "right";
        
        public static function isValid(hAlign:String):Boolean
        {
            return hAlign == LEFT || hAlign == CENTER || hAlign == RIGHT;
        }
    }
}