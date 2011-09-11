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
     *   
     *   @see Juggler
     *   @see Tween
     */
    public interface IAnimatable 
    {
        /** Advance the time by a number of seconds. @param time in seconds. */
        function advanceTime(time:Number):void;
        
        /** Indicates if the animation is finished. 
         *  The object will then be removed from the juggler. */
        function get isComplete():Boolean;
    }
}