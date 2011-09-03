// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.utils.Dictionary;
    
    import starling.display.DisplayObject;
    
    public class EventDispatcher
    {
        private var mEventListeners:Dictionary;
        
        public function EventDispatcher()
        {  }
        
        public function addEventListener(type:String, listener:Function):void
        {
            if (mEventListeners == null)
                mEventListeners = new Dictionary();
            
            var listeners:Vector.<Function> = mEventListeners[type];
            if (listeners == null)
                mEventListeners[type] = new <Function>[listener];
            else
                mEventListeners[type] = listeners.concat(new <Function>[listener]);
        }
        
        public function removeEventListener(type:String, listener:Function):void
        {
            var listeners:Vector.<Function> = mEventListeners[type];
            if (listeners)
            {
                listeners = listeners.filter(
                    function(item:Function, ...rest):Boolean { return item != listener; });
                
                if (listeners.length == 0)
                    delete mEventListeners[type];
                else
                    mEventListeners[type] = listeners;
            }
        }
        
        public function removeEventListeners(type:String=null):void
        {
            if (type)
                delete mEventListeners[type];
            else
                mEventListeners = null;
        }
        
        public function dispatchEvent(event:Event):void
        {
            var listeners:Vector.<Function> = mEventListeners ? mEventListeners[event.type] : null;
            if (listeners == null && !event.bubbles) return; // no need to do anything
            
            // if the event already has a current target, it was re-dispatched by user -> we change 
            // the target to 'this' for now, but undo that later on (instead of creating a clone)

            var previousTarget:EventDispatcher = event.target;
            if (previousTarget == null || event.currentTarget != null) event.setTarget(this);
            
            var stopImmediatePropagation:Boolean = false;
            if (listeners != null && listeners.length != 0)
            {
                event.setCurrentTarget(this);
                
                // we can enumerate directly over the vector, since "add"- and "removeEventListener" 
                // won't change it, but instead always create a new vector.
                for each (var listener:Function in listeners)
                {
                    listener(event);
                    if (event.stopsImmediatePropagation)
                    {
                        stopImmediatePropagation = true;
                        break;
                    }
                }
            }
            
            if (!stopImmediatePropagation && event.bubbles && !event.stopsPropagation && 
                this is DisplayObject)
            {
                var targetDisplayObject:DisplayObject = this as DisplayObject;
                if (targetDisplayObject.parent != null)
                {
                    event.setCurrentTarget(null); // to find out later if the event was redispatched
                    targetDisplayObject.parent.dispatchEvent(event);
                }
            }
            
            if (previousTarget) 
                event.setTarget(previousTarget);
        }
        
        public function hasEventListener(type:String):Boolean
        {
            return mEventListeners != null && mEventListeners[type] != null;
        }
    }
}