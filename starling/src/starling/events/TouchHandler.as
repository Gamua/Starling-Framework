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

public interface TouchHandler
{
    function handleTouches(touches:Vector.<Touch>):void;
    function dispose():void;
}
}
