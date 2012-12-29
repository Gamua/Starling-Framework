// =================================================================================================
//
//    Starling Framework
//    Copyright 2011 Gamua OG. All Rights Reserved.
//
//    This program is free software. You can redistribute and/or modify it
//    in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events {

    /** An interface that allows for low-level handling of Touch input. User code can install
     * a custom TouchHandler via Starling.touchHandler */
    public interface TouchHandler
    {
        /** Handle touch input. 'touches' is a list of *all* current touches. Touches that were
         * just created or updated as a result of new input will have their 'updated' properties
         * set to true.  */
        function handleTouches(touches:Vector.<Touch>):void;

        /** Perform any necessary cleanup */
        function dispose():void;
    }
}
