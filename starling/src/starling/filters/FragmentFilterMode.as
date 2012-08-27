// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import starling.errors.AbstractClassError;

    public class FragmentFilterMode
    {
        /** @private */
        public function FragmentFilterMode() { throw new AbstractClassError(); }
        
        public static const BELOW:String = "below";
        public static const REPLACE:String = "replace";
        public static const ABOVE:String = "above";
    }
}