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
     *  <pre>
     *  var tween:Tween = new Tween(object, 2.0, Transitions.EASE_IN_OUT);
     *  tween.animate("x", object.x + 50);
     *  tween.animate("rotation", deg2rad(45));
     *  tween.fadeTo(0);    // equivalent to 'animate("alpha", 0)'
     *  Starling.juggler.add(tween); 
     *  </pre> 
     * 
     *  Note that the object is added to a juggler at the end. A tween will only be executed if its
     *  "advanceTime" method is executed regularly - the juggler will do that for you, and will 
     *  release the tween when it is finished.
     * 
     *  @see Juggler
     *  @see Transitions
     */ 
    public class Tween implements IAnimatable
    {
        private var mTarget:Object;
        private var mTransition:String;
        private var mProperties:Vector.<String>;
        private var mStartValues:Vector.<Number>;
        private var mEndValues:Vector.<Number>;

        private var mOnStart:Function;
        private var mOnUpdate:Function;
        private var mOnComplete:Function;  
        
        private var mOnStartArgs:Array;
        private var mOnUpdateArgs:Array;
        private var mOnCompleteArgs:Array;
        
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mDelay:Number;
        private var mRoundToInt:Boolean;        
       
        /** Creates a tween with a target, duration (in seconds) and a transition function. */
        public function Tween(target:Object, time:Number, transition:String="linear")        
        {
             mTarget = target;
             mCurrentTime = 0;
             mTotalTime = Math.max(0.0001, time);
             mDelay = 0;
             mTransition = transition;
             mRoundToInt = false;
             mProperties = new <String>[];
             mStartValues = new <Number>[];
             mEndValues = new <Number>[];
        }

        /** Animates the property of an object to a target value. You can call this method multiple
         *  times on one tween. */
        public function animate(property:String, targetValue:Number):void
        {
            if (mTarget == null) return; // tweening null just does nothing.
                   
            mProperties.push(property);
            mStartValues.push(Number.NaN);
            mEndValues.push(targetValue);
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
            if (time == 0) return;
            
            var previousTime:Number = mCurrentTime;
            mCurrentTime += time;
            
            if (mCurrentTime < 0 || previousTime >= mTotalTime) 
                return;

            if (onStart != null && previousTime <= 0 && mCurrentTime >= 0) 
                onStart.apply(null, mOnStartArgs);

            var ratio:Number = Math.min(mTotalTime, mCurrentTime) / mTotalTime;
            var numAnimatedProperties:int = mStartValues.length;

            for (var i:int=0; i<numAnimatedProperties; ++i)
            {                
                if (isNaN(mStartValues[i])) 
                    mStartValues[i] = mTarget[mProperties[i]] as Number;
                
                var startValue:Number = mStartValues[i];
                var endValue:Number = mEndValues[i];
                var delta:Number = endValue - startValue;
                
                var transitionFunc:Function = Transitions.getTransition(mTransition);                
                var currentValue:Number = startValue + transitionFunc(ratio) * delta;
                if (mRoundToInt) currentValue = Math.round(currentValue);
                mTarget[mProperties[i]] = currentValue;
            }

            if (onUpdate != null) 
                onUpdate.apply(null, mOnUpdateArgs);
            
            if (onComplete != null && previousTime < mTotalTime && mCurrentTime >= mTotalTime)
                onComplete.apply(null, mOnCompleteArgs);
        }
        
        /** @inheritDoc */
        public function get isComplete():Boolean { return mCurrentTime >= mTotalTime; }        
        
        /** The target object that is animated. */
        public function get target():Object { return mTarget; }
        
        /** The transition method used for the animation. @see Transitions */
        public function get transition():String { return mTransition; }
        
        /** The total time the tween will take (in seconds). */
        public function get totalTime():Number { return mTotalTime; }
        
        /** The time that has passed since the tween was created. */
        public function get currentTime():Number { return mCurrentTime; }
        
        /** The delay before the tween is started. */
        public function get delay():Number { return mDelay; }
        public function set delay(value:Number):void 
        { 
            mCurrentTime = mCurrentTime + mDelay - value;
            mDelay = value;
        }
        
        /** Indicates if the numeric values should be cast to Integers. @default false */
        public function get roundToInt():Boolean { return mRoundToInt; }
        public function set roundToInt(value:Boolean):void { mRoundToInt = value; }        
        
        /** A function that will be called when the tween starts (after a possible delay). */
        public function get onStart():Function { return mOnStart; }
        public function set onStart(value:Function):void { mOnStart = value; }
        
        /** A function that will be called each time the tween is advanced. */
        public function get onUpdate():Function { return mOnUpdate; }
        public function set onUpdate(value:Function):void { mOnUpdate = value; }
        
        /** A function that will be called when the tween is complete. */
        public function get onComplete():Function { return mOnComplete; }
        public function set onComplete(value:Function):void { mOnComplete = value; }
        
        /** The arguments that will be passed to the 'onStart' function. */
        public function get onStartArgs():Array { return mOnStartArgs; }
        public function set onStartArgs(value:Array):void { mOnStartArgs = value; }
        
        /** The arguments that will be passed to the 'onUpdate' function. */
        public function get onUpdateArgs():Array { return mOnUpdateArgs; }
        public function set onUpdateArgs(value:Array):void { mOnUpdateArgs = value; }
        
        /** The arguments that will be passed to the 'onComplete' function. */
        public function get onCompleteArgs():Array { return mOnCompleteArgs; }
        public function set onCompleteArgs(value:Array):void { mOnCompleteArgs = value; }
    }
}
