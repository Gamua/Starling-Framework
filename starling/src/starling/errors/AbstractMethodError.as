// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.errors
{
    /** An AbstractMethodError is thrown when you attempt to call an abstract method. */
    public class AbstractMethodError extends Error
    {
        /** Creates a new AbstractMethodError object. */
        public function AbstractMethodError(message:*="", id:*=0)
        {
            super(message, id);
        }
    }
}