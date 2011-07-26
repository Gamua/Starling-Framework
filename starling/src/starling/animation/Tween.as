package starling.animation
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    public class Tween implements IAnimatable
    {        
        private var mTarget:Object;
        private var mTransition:String;
        private var mProperties:Array = [];
        private var mStartValues:Array = [];
        private var mEndValues:Array = [];        

        private var mOnStart:Function;
        private var mOnUpdate:Function;
        private var mOnComplete:Function;  
        
        private var mOnStartArgs:Array = [];
        private var mOnUpdateArgs:Array = [];
        private var mOnCompleteArgs:Array = [];
        
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mDelay:Number;
        private var mRoundToInt:Boolean;        
       
        public function Tween(target:Object, time:Number, transition:String="linear")        
        {             
             mTarget = target;
             mCurrentTime = 0;
             mTotalTime = Math.max(0.0001, time);
             mDelay = 0;
             mTransition = transition;
             mRoundToInt = false;
        }

        public function animate(property:String, targetValue:Number):void
        {
            if (mTarget == null) return; // tweening null just does nothing.
                   
            mProperties.push(property);
            mStartValues.push(null);
            mEndValues.push(targetValue);
        }
        
        public function scaleTo(factor:Number):void
        {
            animate("scaleX", factor);
            animate("scaleY", factor);
        }
        
        public function moveTo(x:Number, y:Number):void
        {
            animate("x", x);
            animate("y", y);
        }
        
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

            for (var i:int=0; i<mStartValues.length; ++i)
            {                
                if (mStartValues[i] == null) mStartValues[i] = mTarget[mProperties[i]];
                
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
        
        public function complete():void
        {
            if (!isComplete) advanceTime(mTotalTime - mCurrentTime);
        }
        
        public function get isComplete():Boolean { return mCurrentTime >= mTotalTime; }        
        public function get target():Object { return mTarget; }
        public function get transition():String { return mTransition; }        
        public function get totalTime():Number { return mTotalTime; }
        public function get currentTime():Number { return mCurrentTime; }
        public function get delay():Number { return mDelay; }
        public function set delay(value:Number):void 
        { 
            mCurrentTime = mCurrentTime + mDelay - value;
            mDelay = value;
        }
        
        public function get roundToInt():Boolean { return mRoundToInt; }
        public function set roundToInt(value:Boolean):void { mRoundToInt = value; }        
        
        public function get onStart():Function { return mOnStart; }
        public function set onStart(value:Function):void { mOnStart = value; }
        
        public function get onUpdate():Function { return mOnUpdate; }
        public function set onUpdate(value:Function):void { mOnUpdate = value; }
        
        public function get onComplete():Function { return mOnComplete; }
        public function set onComplete(value:Function):void { mOnComplete = value; }
        
        public function get onStartArgs():Array { return mOnStartArgs; }
        public function set onStartArgs(value:Array):void { mOnStartArgs = value; }
        
        public function get onUpdateArgs():Array { return mOnUpdateArgs; }
        public function set onUpdateArgs(value:Array):void { mOnUpdateArgs = value; }
        
        public function get onCompleteArgs():Array { return mOnCompleteArgs; }
        public function set onCompleteArgs(value:Array):void { mOnCompleteArgs = value; }
    }
}
