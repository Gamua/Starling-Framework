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
    public class MissingContextError extends Error
    {
        public function MissingContextError(message:*="", id:*=0)
        {
            super(message, id);
        }
    }
}