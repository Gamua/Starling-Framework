// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.animation
{
    /**  The IAnimatable interface describes objects that are animated depending on the passed time. 
     *   Any object that implements this interface can be added to a juggler.
     *   @see Juggler
     */
    public interface IAnimatable 
    {
        /** Advance the animation by a number of seconds. @param time in seconds. */
        function advanceTime(time:Number):void;
        
        /** Indicates if the animation is finished. The juggler will purge the object in that case. */
        function get isComplete():Boolean;
    }
}