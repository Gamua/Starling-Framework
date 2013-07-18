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

    /** A Tween animates numeric properties of objects. It uses different transition functions 
     *  to give the animations various styles.
     *  
     *  <p>The primary use of this class is to do standard animations like movement, fading, 
     *  rotation, etc. But there are no limits on what to animate; as long as the property you want
     *  to animate is numeric (<code>int, uint, Number</code>), the tween can handle it. For a list 
     *  of available Transition types, look at the "Transitions" class.</p> 
     *  
     *  <p>Here is an example of a tween that moves an object to the right, rotates it, and 
     *  fades it out:</p>
     *  
     *  <listing>
     *  var tween:Tween = new Tween(object, 2.0, Transitions.EASE_IN_OUT);
     *  tween.animate("x", object.x + 50);
     *  tween.animate("rotation", deg2rad(45));
     *  tween.fadeTo(0);    // equivalent to 'animate("alpha", 0)'
     *  Starling.juggler.add(tween);</listing> 
     *  
     *  <p>Note that the object is added to a juggler at the end of this sample. That's because a 
     *  tween will only be executed if its "advanceTime" method is executed regularly - the 
     *  juggler will do that for you, and will remove the tween when it is finished.</p>
     *  
     *  @see Juggler
     *  @see Transitions
     */ 
    public class Tween extends EventDispatcher implements IAnimatable
    {
        private var mTarget:Object;
        private var mTransitionFunc:Function;
        private var mTransitionName:String;
        
        private var mProperties:Vector.<String>;
        private var mStartValues:Vector.<Number>;
        private var mEndValues:Vector.<Number>;

        private var mOnStart:Function;
        private var mOnUpdate:Function;
        private var mOnRepeat:Function;
        private var mOnComplete:Function;  
        
        private var mOnStartArgs:Array;
        private var mOnUpdateArgs:Array;
        private var mOnRepeatArgs:Array;
        private var mOnCompleteArgs:Array;
        
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mProgress:Number;
        private var mDelay:Number;
        private var mRoundToInt:Boolean;
        private var mNextTween:Tween;
        private var mRepeatCount:int;
        private var mRepeatDelay:Number;
        private var mReverse:Boolean;
        private var mCurrentCycle:int;
        
        /** Creates a tween with a target, duration (in seconds) and a transition function.
         *  @param target the object that you want to animate
         *  @param time the duration of the Tween (in seconds)
         *  @param transition can be either a String (e.g. one of the constants defined in the
         *         Transitions class) or a function. Look up the 'Transitions' class for a   
         *         documentation about the required function signature. */ 
        public function Tween(target:Object, time:Number, transition:Object="linear")        
        {
             reset(target, time, transition);
        }

        /** Resets the tween to its default values. Useful for pooling tweens. */
        public function reset(target:Object, time:Number, transition:Object="linear"):Tween
        {
            mTarget = target;
            mCurrentTime = 0.0;
            mTotalTime = Math.max(0.0001, time);
            mProgress = 0.0;
            mDelay = mRepeatDelay = 0.0;
            mOnStart = mOnUpdate = mOnComplete = null;
            mOnStartArgs = mOnUpdateArgs = mOnCompleteArgs = null;
            mRoundToInt = mReverse = false;
            mRepeatCount = 1;
            mCurrentCycle = -1;
            
            if (transition is String)
                this.transition = transition as String;
            else if (transition is Function)
                this.transitionFunc = transition as Function;
            else 
                throw new ArgumentError("Transition must be either a string or a function");
            
            if (mProperties)  mProperties.length  = 0; else mProperties  = new <String>[];
            if (mStartValues) mStartValues.length = 0; else mStartValues = new <Number>[];
            if (mEndValues)   mEndValues.length   = 0; else mEndValues   = new <Number>[];
            
            return this;
        }
        
        /** Animates the property of the target to a certain value. You can call this method multiple
         *  times on one tween. */
        public function animate(property:String, endValue:Number):void
        {
            if (mTarget == null) return; // tweening null just does nothing.
                   
            mProperties.push(property);
            mStartValues.push(Number.NaN);
            mEndValues.push(endValue);
        }
        
        /** Animates the 'scaleX' and 'scaleY' properties of an object simultaneously. */
        public function scaleTo(factor:Number):void
        {
            animate("scaleX", factor);
            animate("scaleY", factor);
        }
        
        /** Animates the 'x' and 'y' properties of an object simultaneously. */
        public function moveTo(x:Number, y:Number):void
        {
            animate("x", x);
            animate("y", y);
        }
        
        /** Animates the 'alpha' property of an object to a certain target value. */ 
        public function fadeTo(alpha:Number):void
        {
            animate("alpha", alpha);
        }
        
        /** @inheritDoc */
        public function advanceTime(time:Number):void
        {
            if (time == 0 || (mRepeatCount == 1 && mCurrentTime == mTotalTime)) return;
            
            var i:int;
            var previousTime:Number = mCurrentTime;
            var restTime:Number = mTotalTime - mCurrentTime;
            var carryOverTime:Number = time > restTime ? time - restTime : 0.0;
            
            mCurrentTime += time;
            
            if (mCurrentTime <= 0) 
                return; // the delay is not over yet
            else if (mCurrentTime > mTotalTime) 
                mCurrentTime = mTotalTime;
            
            if (mCurrentCycle < 0 && previousTime <= 0 && mCurrentTime > 0)
            {
                mCurrentCycle++;
                if (mOnStart != null) mOnStart.apply(null, mOnStartArgs);
            }

            var ratio:Number = mCurrentTime / mTotalTime;
            var reversed:Boolean = mReverse && (mCurrentCycle % 2 == 1);
            var numProperties:int = mStartValues.length;
            mProgress = reversed ? mTransitionFunc(1.0 - ratio) : mTransitionFunc(ratio);

            for (i=0; i<numProperties; ++i)
            {                
                if (mStartValues[i] != mStartValues[i]) // isNaN check - "isNaN" causes allocation! 
                    mStartValues[i] = mTarget[mProperties[i]] as Number;
                
                var startValue:Number = mStartValues[i];
                var endValue:Number = mEndValues[i];
                var delta:Number = endValue - startValue;
                var currentValue:Number = startValue + mProgress * delta;
                
                if (mRoundToInt) currentValue = Math.round(currentValue);
                mTarget[mProperties[i]] = currentValue;
            }

            if (mOnUpdate != null) 
                mOnUpdate.apply(null, mOnUpdateArgs);
            
            if (previousTime < mTotalTime && mCurrentTime >= mTotalTime)
            {
                if (mRepeatCount == 0 || mRepeatCount > 1)
                {
                    mCurrentTime = -mRepeatDelay;
                    mCurrentCycle++;
                    if (mRepeatCount > 1) mRepeatCount--;
                    if (mOnRepeat != null) mOnRepeat.apply(null, mOnRepeatArgs);
                }
                else
                {
                    // save callback & args: they might be changed through an event listener
                    var onComplete:Function = mOnComplete;
                    var onCompleteArgs:Array = mOnCompleteArgs;
                    
                    // in the 'onComplete' callback, people might want to call "tween.reset" and
                    // add it to another juggler; so this event has to be dispatched *before*
                    // executing 'onComplete'.
                    dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
                    if (onComplete != null) onComplete.apply(null, onCompleteArgs);
                }
            }
            
            if (carryOverTime) 
                advanceTime(carryOverTime);
        }
        
        /** The end value a certain property is animated to. Throws an ArgumentError if the 
         *  property is not being animated. */
        public function getEndValue(property:String):Number
        {
            var index:int = mProperties.indexOf(property);
            if (index == -1) throw new ArgumentError("The property '" + property + "' is not animated");
            else return mEndValues[index] as Number;
        }
        
        /** Indicates if the tween is finished. */
        public function get isComplete():Boolean 
        { 
            return mCurrentTime >= mTotalTime && mRepeatCount == 1; 
        }        
        
        /** The target object that is animated. */
        public function get target():Object { return mTarget; }
        
        /** The transition method used for the animation. @see Transitions */
        public function get transition():String { return mTransitionName; }
        public function set transition(value:String):void 
        { 
            mTransitionName = value;
            mTransitionFunc = Transitions.getTransition(value);
            
            if (mTransitionFunc == null)
                throw new ArgumentError("Invalid transiton: " + value);
        }
        
        /** The actual transition function used for the animation. */
        public function get transitionFunc():Function { return mTransitionFunc; }
        public function set transitionFunc(value:Function):void
        {
            mTransitionName = "custom";
            mTransitionFunc = value;
        }
        
        /** The total time the tween will take per repetition (in seconds). */
        public function get totalTime():Number { return mTotalTime; }
        
        /** The time that has passed since the tween was created (in seconds). */
        public function get currentTime():Number { return mCurrentTime; }
        
        /** The current progress between 0 and 1, as calculated by the transition function. */
        public function get progress():Number { return mProgress; } 
        
        /** The delay before the tween is started (in seconds). @default 0 */
        public function get delay():Number { return mDelay; }
        public function set delay(value:Number):void 
        { 
            mCurrentTime = mCurrentTime + mDelay - value;
            mDelay = value;
        }
        
        /** The number of times the tween will be executed. 
         *  Set to '0' to tween indefinitely. @default 1 */
        public function get repeatCount():int { return mRepeatCount; }
        public function set repeatCount(value:int):void { mRepeatCount = value; }
        
        /** The amount of time to wait between repeat cycles (in seconds). @default 0 */
        public function get repeatDelay():Number { return mRepeatDelay; }
        public function set repeatDelay(value:Number):void { mRepeatDelay = value; }
        
        /** Indicates if the tween should be reversed when it is repeating. If enabled, 
         *  every second repetition will be reversed. @default false */
        public function get reverse():Boolean { return mReverse; }
        public function set reverse(value:Boolean):void { mReverse = value; }
        
        /** Indicates if the numeric values should be cast to Integers. @default false */
        public function get roundToInt():Boolean { return mRoundToInt; }
        public function set roundToInt(value:Boolean):void { mRoundToInt = value; }        
        
        /** A function that will be called when the tween starts (after a possible delay). */
        public function get onStart():Function { return mOnStart; }
        public function set onStart(value:Function):void { mOnStart = value; }
        
        /** A function that will be called each time the tween is advanced. */
        public function get onUpdate():Function { return mOnUpdate; }
        public function set onUpdate(value:Function):void { mOnUpdate = value; }
        
        /** A function that will be called each time the tween finishes one repetition
         *  (except the last, which will trigger 'onComplete'). */
        public function get onRepeat():Function { return mOnRepeat; }
        public function set onRepeat(value:Function):void { mOnRepeat = value; }
        
        /** A function that will be called when the tween is complete. */
        public function get onComplete():Function { return mOnComplete; }
        public function set onComplete(value:Function):void { mOnComplete = value; }
        
        /** The arguments that will be passed to the 'onStart' function. */
        public function get onStartArgs():Array { return mOnStartArgs; }
        public function set onStartArgs(value:Array):void { mOnStartArgs = value; }
        
        /** The arguments that will be passed to the 'onUpdate' function. */
        public function get onUpdateArgs():Array { return mOnUpdateArgs; }
        public function set onUpdateArgs(value:Array):void { mOnUpdateArgs = value; }
        
        /** The arguments that will be passed to the 'onRepeat' function. */
        public function get onRepeatArgs():Array { return mOnRepeatArgs; }
        public function set onRepeatArgs(value:Array):void { mOnRepeatArgs = value; }
        
        /** The arguments that will be passed to the 'onComplete' function. */
        public function get onCompleteArgs():Array { return mOnCompleteArgs; }
        public function set onCompleteArgs(value:Array):void { mOnCompleteArgs = value; }
        
        /** Another tween that will be started (i.e. added to the same juggler) as soon as 
         *  this tween is completed. */
        public function get nextTween():Tween { return mNextTween; }
        public function set nextTween(value:Tween):void { mNextTween = value; }
        
        // tween pooling
        
        private static var sTweenPool:Vector.<Tween> = new <Tween>[];
        
        /** @private */
        starling_internal static function fromPool(target:Object, time:Number, 
                                                   transition:Object="linear"):Tween
        {
            if (sTweenPool.length) return sTweenPool.pop().reset(target, time, transition);
            else return new Tween(target, time, transition);
        }
        
        /** @private */
        starling_internal static function toPool(tween:Tween):void
        {
            // reset any object-references, to make sure we don't prevent any garbage collection
            tween.mOnStart = tween.mOnUpdate = tween.mOnRepeat = tween.mOnComplete = null;
            tween.mOnStartArgs = tween.mOnUpdateArgs = tween.mOnRepeatArgs = tween.mOnCompleteArgs = null;
            tween.mTarget = null;
            tween.mTransitionFunc = null;
            tween.removeEventListeners();
            sTweenPool.push(tween);
        }
    }
}
