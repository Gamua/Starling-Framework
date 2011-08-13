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
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.utils.getTimer;
    
    public class Juggler implements IAnimatable
    {
        private var mObjects:Array;
        private var mElapsedTime:Number;        
        private var mDisplayObject:DisplayObject;
        
        public function Juggler()
        {
            mElapsedTime = 0;
            mObjects = [];
        }

        public function add(object:IAnimatable):void
        {
            if (object != null) mObjects.push(object);
        }
        
        public function remove(object:IAnimatable):void
        {
            mObjects = mObjects.filter(
                function(currentObject:Object, index:int, array:Array):Boolean
                {
                    return object != currentObject;
                });
        }
        
        public function removeTweens(target:Object):void
        {
            if (target == null) return;
            
            mObjects = mObjects.filter(
                function(currentObject:Object, index:int, array:Array):Boolean
                {
                    var tween:Tween = currentObject as Tween;
                    if (tween && tween.target == target) return false;
                    else return true;
                });
        }
        
        public function purge():void
        {
            mObjects = [];
        }        
        
        public function delayCall(call:Function, delay:Number, ...args):DelayedCall
        {
            if (call == null) return null;
            
            var delayedCall:DelayedCall = new DelayedCall(call, delay, args);
            add(delayedCall);
            return delayedCall;
        }
        
        public function advanceTime(time:Number):void
        {                        
            mElapsedTime += time;
            var objectCopy:Array = mObjects.concat();
            
            // since 'advanceTime' could modify the juggler (through a callback), we split
            // the logic in two loops.
            
            for each (var currentObject:IAnimatable in objectCopy)            
                currentObject.advanceTime(time);  
            
            mObjects = mObjects.filter(
                function(object:IAnimatable, index:int, array:Array):Boolean
                {
                    return !object.isComplete;
                });
        }
        
        public function get isComplete():Boolean  { return false; }        
        public function get elapsedTime():Number { return mElapsedTime; }        
    }
}