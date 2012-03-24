// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import starling.errors.AbstractClassError;
    
    /** A class that provides constant values for visual blend mode effects. */
    public class BlendMode
    {
        /** @private */
        public function BlendMode() { throw new AbstractClassError(); }
        
        /** Inherits the blend mode from this display object's parent. */
        public static const AUTO:String = "auto";

        /** Deactivates blending, i.e. disabling any transparency. */
        public static const NONE:String = "none";
        
        /** The display object appears in front of the background. */
        public static const NORMAL:String = "normal";
        
        /** Adds the values of the colors of the display object to the colors of its background. */
        public static const ADD:String = "add";
        
        /** Multiplies the values of the display object colors with the the background color. */
        public static const MULTIPLY:String = "multiply";
        
        /** Multiplies the complement (inverse) of the display object color with the complement of 
          * the background color, resulting in a bleaching effect. */
        public static const SCREEN:String = "screen";
        
        /** Determines whether a blending value is valid. */
        public static function isValid(mode:String):Boolean
        {
            return mode == AUTO || mode == NORMAL || mode == ADD ||
                   mode == MULTIPLY || mode == NONE || mode == SCREEN;
        }
    }
}