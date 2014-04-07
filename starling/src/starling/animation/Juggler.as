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
    import starling.core.starling_internal;
    import starling.events.Event;
    import starling.events.EventDispatcher;

    /** The Juggler takes objects that implement IAnimatable (like Tweens) and executes them.
     * 
     *  <p>A juggler is a simple object. It does no more than saving a list of objects implementing 
     *  "IAnimatable" and advancing their time if it is told to do so (by calling its own 
     *  "advanceTime"-method). When an animation is completed, it throws it away.</p>
     *  
     *  <p>There is a default juggler available at the Starling class:</p>
     *  
     *  <pre>
     *  var juggler:Juggler = Starling.juggler;
     *  </pre>
     *  
     *  <p>You can create juggler objects yourself, just as well. That way, you can group 
     *  your game into logical components that handle their animations independently. All you have
     *  to do is call the "advanceTime" method on your custom juggler once per frame.</p>
     *  
     *  <p>Another handy feature of the juggler is the "delayCall"-method. Use it to 
     *  execute a function at a later time. Different to conventional approaches, the method
     *  will only be called when the juggler is advanced, giving you perfect control over the 
     *  call.</p>
     *  
     *  <pre>
     *  juggler.delayCall(object.removeFromParent, 1.0);
     *  juggler.delayCall(object.addChild, 2.0, theChild);
     *  juggler.delayCall(function():void { doSomethingFunny(); }, 3.0);
     *  </pre>
     * 
     *  @see Tween
     *  @see DelayedCall 
     */
    public class Juggler implements IAnimatable
    {
        private var mObjects:Vector.<IAnimatable>;
        private var mElapsedTime:Number;
        
        /** Create an empty juggler. */
        public function Juggler()
        {
            mElapsedTime = 0;
            mObjects = new <IAnimatable>[];
        }

        /** Adds an object to the juggler. */
        public function add(object:IAnimatable):void
        {
            if (object && mObjects.indexOf(object) == -1) 
            {
                mObjects.push(object);
            
                var dispatcher:EventDispatcher = object as EventDispatcher;
                if (dispatcher) dispatcher.addEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
            }
        }
        
        /** Determines if an object has been added to the juggler. */
        public function contains(object:IAnimatable):Boolean
        {
            return mObjects.indexOf(object) != -1;
        }
        
        /** Removes an object from the juggler. */
        public function remove(object:IAnimatable):void
        {
            if (object == null) return;
            
            var dispatcher:EventDispatcher = object as EventDispatcher;
            if (dispatcher) dispatcher.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);

            var index:int = mObjects.indexOf(object);
            if (index != -1) mObjects[index] = null;
        }
        
        /** Removes all tweens with a certain target. */
        public function removeTweens(target:Object):void
        {
            if (target == null) return;
            
            for (var i:int=mObjects.length-1; i>=0; --i)
            {
                var tween:Tween = mObjects[i] as Tween;
                if (tween && tween.target == target)
                {
                    tween.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
                    mObjects[i] = null;
                }
            }
        }
        
        /** Figures out if the juggler contains one or more tweens with a certain target. */
        public function containsTweens(target:Object):Boolean
        {
            if (target == null) return false;
            
            for (var i:int=mObjects.length-1; i>=0; --i)
            {
                var tween:Tween = mObjects[i] as Tween;
                if (tween && tween.target == target) return true;
            }
            
            return false;
        }
        
        /** Removes all objects at once. */
        public function purge():void
        {
            // the object vector is not purged right away, because if this method is called 
            // from an 'advanceTime' call, this would make the loop crash. Instead, the
            // vector is filled with 'null' values. They will be cleaned up on the next call
            // to 'advanceTime'.
            
            for (var i:int=mObjects.length-1; i>=0; --i)
            {
                var dispatcher:EventDispatcher = mObjects[i] as EventDispatcher;
                if (dispatcher) dispatcher.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
                mObjects[i] = null;
            }
        }
        
        /** Delays the execution of a function until <code>delay</code> seconds have passed.
         *  Creates an object of type 'DelayedCall' internally and returns it. Remove that object
         *  from the juggler to cancel the function call. */
        public function delayCall(call:Function, delay:Number, ...args):DelayedCall
        {
            if (call == null) return null;
            
            var delayedCall:DelayedCall = new DelayedCall(call, delay, args);
            add(delayedCall);
            return delayedCall;
        }
        
        /** Utilizes a tween to animate the target object over <code>time</code> seconds. Internally,
         *  this method uses a tween instance (taken from an object pool) that is added to the
         *  juggler right away. This method provides a convenient alternative for creating 
         *  and adding a tween manually.
         *  
         *  <p>Fill 'properties' with key-value pairs that describe both the 
         *  tween and the animation target. Here is an example:</p>
         *  
         *  <pre>
         *  juggler.tween(object, 2.0, {
         *      transition: Transitions.EASE_IN_OUT,
         *      delay: 20, // -> tween.delay = 20
         *      x: 50      // -> tween.animate("x", 50)
         *  });
         *  </pre> 
         */
        public function tween(target:Object, time:Number, properties:Object):void
        {
            var tween:Tween = Tween.starling_internal::fromPool(target, time);
            
            for (var property:String in properties)
            {
                var value:Object = properties[property];
                
                if (tween.hasOwnProperty(property))
                    tween[property] = value;
                else if (target.hasOwnProperty(property))
                    tween.animate(property, value as Number);
                else
                    throw new ArgumentError("Invalid property: " + property);
            }
            
            tween.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledTweenComplete);
            add(tween);
        }
        
        private function onPooledTweenComplete(event:Event):void
        {
            Tween.starling_internal::toPool(event.target as Tween);
        }
        
        /** Advances all objects by a certain time (in seconds). */
        public function advanceTime(time:Number):void
        {   
            var numObjects:int = mObjects.length;
            var currentIndex:int = 0;
            var i:int;
            
            mElapsedTime += time;
            if (numObjects == 0) return;
            
            // there is a high probability that the "advanceTime" function modifies the list 
            // of animatables. we must not process new objects right now (they will be processed
            // in the next frame), and we need to clean up any empty slots in the list.
            
            for (i=0; i<numObjects; ++i)
            {
                var object:IAnimatable = mObjects[i];
                if (object)
                {
                    // shift objects into empty slots along the way
                    if (currentIndex != i) 
                    {
                        mObjects[currentIndex] = object;
                        mObjects[i] = null;
                    }
                    
                    object.advanceTime(time);
                    ++currentIndex;
                }
            }
            
            if (currentIndex != i)
            {
                numObjects = mObjects.length; // count might have changed!
                
                while (i < numObjects)
                    mObjects[int(currentIndex++)] = mObjects[int(i++)];
                
                mObjects.length = currentIndex;
            }
        }
        
        private function onRemove(event:Event):void
        {
            remove(event.target as IAnimatable);
            
            var tween:Tween = event.target as Tween;
            if (tween && tween.isComplete)
                add(tween.nextTween);
        }
        
        /** The total life time of the juggler (in seconds). */
        public function get elapsedTime():Number { return mElapsedTime; }
 
        /** The actual vector that contains all objects that are currently being animated. */
        protected function get objects():Vector.<IAnimatable> { return mObjects; }
    }
}
