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

    /** A class that provides constant values for filter modes. The values are used in the
     *  FragmentFilter.mode property and define how a filter result is combined with the 
     *  original object. */
    public class FragmentFilterMode
    {
        /** @private */
        public function FragmentFilterMode() { throw new AbstractClassError(); }
        
        /** The filter is displayed below the filtered object. */
        public static const BELOW:String = "below";
        
        /** The filter is replacing the filtered object. */
        public static const REPLACE:String = "replace";
        
        /** The filter is displayed above the filtered object. */ 
        public static const ABOVE:String = "above";
    }
}