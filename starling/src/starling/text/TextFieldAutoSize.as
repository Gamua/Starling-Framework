// =================================================================================================
//
//	Starling Framework
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text 
{
    import starling.errors.AbstractClassError;

    /** This class is an enumeration of constant values used in setting the 
     *  autoSize property of the TextField class. */ 
    public class TextFieldAutoSize
    {
        /** @private */
        public function TextFieldAutoSize() { throw new AbstractClassError(); }
        
        /** No auto-sizing will happen. */
        public static const NONE:String = "none";
        
        /** Best used for single-line text. The text field will keep its height 
         *  and will grow to the right. */ 
        public static const SINGLE_LINE:String = "singleLine";
        
        /** Best used for multi-line text. The text field will keep its width
         *  and will grow to the bottom. */
        public static const MULTI_LINE:String = "multiLine";
    }
}