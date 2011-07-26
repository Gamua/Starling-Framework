package starling.animation
{
    public class DelayedCall implements IAnimatable
    {
        private var mCurrentTime:Number = 0;
        private var mTotalTime:Number;
        private var mCall:Function;
        private var mArgs:Array;
        private var mRepeatCount:int = 1;
        
        public function DelayedCall(call:Function, delay:Number, args:Array=null)
        {
            mCall = call;
            mTotalTime = Math.max(delay, 0.0001);
            mArgs = args;
        }
        
        public function advanceTime(time:Number):void
        {
            var previousTime:Number = mCurrentTime;
            mCurrentTime = Math.min(mTotalTime, mCurrentTime + time);
            
            if (previousTime < mTotalTime && mCurrentTime >= mTotalTime)
            {                
                mCall.apply(null, mArgs);
                
                if (mRepeatCount > 1)
                {
                    mRepeatCount -= 1;
                    mCurrentTime = 0;
                    advanceTime((previousTime + time) - mTotalTime);
                }
            }            
        }
        
        public function get isComplete():Boolean { return mCurrentTime >= mTotalTime; }
        public function get totalTime():Number { return mTotalTime; }        
        public function get currentTime():Number { return mCurrentTime; }
        
        public function get repeatCount():int { return mRepeatCount; }
        public function set repeatCount(value:int):void { mRepeatCount = value; }
    }
}