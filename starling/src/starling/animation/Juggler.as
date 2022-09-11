// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
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
     *  juggler.delayCall(function():void { rotation += 0.1; }, 3.0);
     *  </pre>
     *
     *  @see Tween
     *  @see DelayedCall
     */
    public class Juggler implements IAnimatable
    {
        private var _objects:Vector.<IAnimatable>;
        private var _objectIDs:Vector.<uint>;
        private var _elapsedTime:Number;
        private var _timeScale:Number;

        private static var sCurrentObjectID:uint;

        /** Create an empty juggler. */
        public function Juggler()
        {
            _elapsedTime = 0;
            _timeScale = 1.0;
            _objects = new <IAnimatable>[];
            _objectIDs = new <uint>[];
        }

        /** Adds an object to the juggler.
         *
         *  @return Unique numeric identifier for the animation. This identifier may be used
         *          to remove the object via <code>removeByID()</code>.
         */
        public function add(object:IAnimatable):uint
        {
            return addWithID(object, getNextID());
        }

        private function addWithID(object:IAnimatable, objectID:uint):uint
        {
            if (object && !contains(object))
            {
                var dispatcher:EventDispatcher = object as EventDispatcher;
                if (dispatcher) dispatcher.addEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);

                _objects[_objects.length] = object;
                _objectIDs[_objectIDs.length] = objectID;

                return objectID;
            }
            else return 0;
        }

        /** Determines if an object has been added to the juggler. */
        public function contains(object:IAnimatable):Boolean
        {
            return _objects.indexOf(object) != -1;
        }

        /** Returns true if there is currently no object being juggled. */
        public function get isEmpty():Boolean
        {
            return _objects.length == 0;
        }

        /** Removes an object from the juggler.
         *
         *  @return The (now meaningless) unique numeric identifier for the animation, or zero
         *          if the object was not found.
         */
        public function remove(object:IAnimatable):uint
        {
            var objectIndex:int = _objects.indexOf(object);
            if (objectIndex != -1)
                return removeByIndex(objectIndex);

            return 0;
        }

        /** Marks the cell used by the object as "free".
         *
         * <p>This method leaves an empty slot in the object list, just in case it is currently
         * being iterated over. The cell will be fully cleaned & re-used on the next call to
         * 'advanceTime'.</p>
         *
         * <p>Important: a valid index must be used here.</p>
         *
         * @return The id of "removed" object.
         */
        private function removeByIndex(index:int):uint
        {
            // get properties
            var object:IAnimatable = _objects[index];
            var objectID:uint = _objectIDs[index];

            // remove the event listener
            var dispatcher:EventDispatcher = object as EventDispatcher;
            if (dispatcher) dispatcher.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);

            // free the cell
            _objects[index] = null;
            _objectIDs[index] = 0;

            return objectID;
        }

        /** Removes an object from the juggler, identified by the unique numeric identifier you
         *  received when adding it.
         *
         *  <p>It's not uncommon that an animatable object is added to a juggler repeatedly,
         *  e.g. when using an object-pool. Thus, when using the <code>remove</code> method,
         *  you might accidentally remove an object that has changed its context. By using
         *  <code>removeByID</code> instead, you can be sure to avoid that, since the objectID
         *  will always be unique.</p>
         *
         *  @return if successful, the passed objectID; if the object was not found, zero.
         */
        public function removeByID(objectID:uint):uint
        {
            var objectIndex:int = _objectIDs.indexOf(objectID);
            if (objectIndex != -1)
                return removeByIndex(objectIndex);

            return 0;
        }

        /** Removes all tweens with a certain target. */
        public function removeTweens(target:Object):void
        {
            if (target == null) return;

            for (var i:int=_objects.length-1; i>=0; --i)
            {
                var tween:Tween = _objects[i] as Tween;
                if (tween && tween.target == target)
                    removeByIndex(i);
            }
        }

        /** Removes all delayed and repeated calls with a certain callback. */
        public function removeDelayedCalls(callback:Function):void
        {
            if (callback == null) return;

            for (var i:int=_objects.length-1; i>=0; --i)
            {
                var delayedCall:DelayedCall = _objects[i] as DelayedCall;
                if (delayedCall && delayedCall.callback == callback)
                    removeByIndex(i);
            }
        }

        /** Figures out if the juggler contains one or more tweens with a certain target. */
        public function containsTweens(target:Object):Boolean
        {
            if (target)
            {
                for (var i:int=_objects.length-1; i>=0; --i)
                {
                    var tween:Tween = _objects[i] as Tween;
                    if (tween && tween.target == target) return true;
                }
            }

            return false;
        }

        /** Figures out if the juggler contains one or more delayed calls with a certain callback. */
        public function containsDelayedCalls(callback:Function):Boolean
        {
            if (callback != null)
            {
                for (var i:int=_objects.length-1; i>=0; --i)
                {
                    var delayedCall:DelayedCall = _objects[i] as DelayedCall;
                    if (delayedCall && delayedCall.callback == callback) return true;
                }
            }

            return false;
        }

        /** Removes all objects at once. */
        public function purge():void
        {
            var i:int;

            // if possible, request removals through events
            // this ensures that tweens from the pool are properly returned
            for (i=_objects.length-1; i>=0; --i)
            {
                var dispatcher:EventDispatcher = _objects[i] as EventDispatcher;
                if (dispatcher) dispatcher.dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
            }

            // remove the remaining objects
            // the object vector is not purged right away, because if this method is called
            // from an 'advanceTime' call, this would make the loop crash. Instead, the
            // vector is filled with 'null' values. They will be cleaned up on the next call
            // to 'advanceTime'.
            for (i=_objects.length-1; i>=0; --i)
                removeByIndex(i);
        }

        /** Delays the execution of a function until <code>delay</code> seconds have passed.
         *  This method provides a convenient alternative for creating and adding a DelayedCall
         *  manually.
         *
         *  @return Unique numeric identifier for the delayed call. This identifier may be used
         *          to remove the object via <code>removeByID()</code>.
         */
        public function delayCall(call:Function, delay:Number, ...args):uint
        {
            if (call == null) throw new ArgumentError("call must not be null");

            var delayedCall:DelayedCall = DelayedCall.starling_internal::fromPool(call, delay, args);
            delayedCall.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledDelayedCallComplete);
            return add(delayedCall);
        }

        /** Runs a function at a specified interval (in seconds). A 'repeatCount' of zero
         *  means that it runs indefinitely.
         *
         *  @return Unique numeric identifier for the delayed call. This identifier may be used
         *          to remove the object via <code>removeByID()</code>.
         */
        public function repeatCall(call:Function, interval:Number, repeatCount:int=0, ...args):uint
        {
            if (call == null) throw new ArgumentError("call must not be null");

            var delayedCall:DelayedCall = DelayedCall.starling_internal::fromPool(call, interval, args);
            delayedCall.repeatCount = repeatCount;
            delayedCall.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledDelayedCallComplete);
            return add(delayedCall);
        }

        private function onPooledDelayedCallComplete(event:Event):void
        {
            DelayedCall.starling_internal::toPool(event.target as DelayedCall);
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
         *
         *  <p>To cancel the tween, call 'Juggler.removeTweens' with the same target, or pass
         *  the returned ID to 'Juggler.removeByID()'.</p>
         *
         *  <p>Note that some property types may be animated in a special way:</p>
         *  <ul>
         *    <li>If the property contains the string <code>color</code> or <code>Color</code>,
         *        it will be treated as an unsigned integer with a color value
         *        (e.g. <code>0xff0000</code> for red). Each color channel will be animated
         *        individually.</li>
         *    <li>The same happens if you append the string <code>#rgb</code> to the name.</li>
         *    <li>If you append <code>#rad</code>, the property is treated as an angle in radians,
         *        making sure it always uses the shortest possible arc for the rotation.</li>
         *    <li>The string <code>#deg</code> does the same for angles in degrees.</li>
         *  </ul>
         */
        public function tween(target:Object, time:Number, properties:Object):uint
        {
            if (target == null) throw new ArgumentError("target must not be null");

            var tween:Tween = Tween.starling_internal::fromPool(target, time);

            for (var property:String in properties)
            {
                var value:Object = properties[property];

                if (tween.hasOwnProperty(property))
                    tween[property] = value;
                else if (target.hasOwnProperty(Tween.getPropertyName(property)))
                    tween.animate(property, value as Number);
                else
                    throw new ArgumentError("Invalid property: " + property);
            }

            tween.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledTweenRemoveRequested);
            return add(tween);
        }

        private function onPooledTweenRemoveRequested(event:Event):void
        {
            // return the tween to the pool
            Tween.starling_internal::toPool(event.target as Tween);

            // note: no need to actually remove the tween here, the Juggler will already take care of that.
        }

        /** Advances all objects by a certain time (in seconds). */
        public function advanceTime(time:Number):void
        {
            var numObjects:int = _objects.length;
            var currentIndex:int = 0;
            var i:int;

            _elapsedTime += time;
            time *= _timeScale;

            if (numObjects == 0 || time == 0) return;

            // there is a high probability that the "advanceTime" function modifies the list
            // of animatables. we must not process new objects right now (they will be processed
            // in the next frame), and we need to clean up any empty slots in the list.

            for (i=0; i<numObjects; ++i)
            {
                var object:IAnimatable = _objects[i];

                if (object)
                {
                    // shift objects into empty slots along the way
                    if (currentIndex != i)
                    {
                        _objects[currentIndex] = object;
                        _objectIDs[currentIndex] = _objectIDs[i];
                        _objects[i] = null;
                        _objectIDs[i] = 0;
                    }

                    object.advanceTime(time);
                    ++currentIndex;
                }
            }

            if (currentIndex != i)
            {
                numObjects = _objects.length; // count might have changed!

                while (i < numObjects)
                {
                    _objects[currentIndex] = _objects[i];
                    _objectIDs[currentIndex] = _objectIDs[i];

                    currentIndex++;
                    i++;
                }

                _objects.length = currentIndex;
                _objectIDs.length = currentIndex;
            }
        }

        private function onRemove(event:Event):void
        {
            var objectID:uint = remove(event.target as IAnimatable);

            if (objectID)
            {
                var tween:Tween = event.target as Tween;
                if (tween && tween.isComplete)
                    addWithID(tween.nextTween, objectID);
            }
        }

        private static function getNextID():uint { return ++sCurrentObjectID; }

        /** The total life time of the juggler (in seconds). */
        public function get elapsedTime():Number { return _elapsedTime; }

        /** The scale at which the time is passing. This can be used for slow motion or time laps
         *  effects. Values below '1' will make all animations run slower, values above '1' faster.
         *  @default 1.0 */
        public function get timeScale():Number { return _timeScale; }
        public function set timeScale(value:Number):void { _timeScale = value; }

        /** The actual vector that contains all objects that are currently being animated. */
        protected function get objects():Vector.<IAnimatable> { return _objects; }
    }
}
