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
    import starling.events.Event;
    import starling.events.EventDispatcher;

    /** A DelayedCall allows you to execute a method after a certain time has passed. Since it 
     *  implements the IAnimatable interface, it can be added to a juggler. In most cases, you 
     *  do not have to use this class directly; the juggler class contains a method to delay
     *  calls directly. 
     * 
     *  <p>DelayedCall dispatches an Event of type 'Event.REMOVE_FROM_JUGGLER' when it is finished,
     *  so that the juggler automatically removes it when its no longer needed.</p>
     * 
     *  @see Juggler
     */ 
    public class DelayedCall extends EventDispatcher implements IAnimatable
    {
        private var mCurrentTime:Number = 0;
        private var mTotalTime:Number;
		private var mTotalCalls:Number;
        private var mCall:Function;
        private var mArgs:Array;
        private var mRepeatCount:int = 1;
        
        /** Creates a delayed call. */
        public function DelayedCall(call:Function, delay:Number, args:Array=null)
        {
            mCall = call;
            mTotalTime = Math.max(delay, 0.0001);
            mArgs = args;
        }
        
        /** @inheritDoc */
        public function advanceTime(time:Number):void
        {
            var previousTime:Number = mCurrentTime;
            mCurrentTime = Math.min(mTotalTime, mCurrentTime + time);
            
            if (previousTime < mTotalTime && mCurrentTime >= mTotalTime)
            {                
                mCall.apply(null, mArgs);
                
				mTotalCalls += 1;
				
                if (mRepeatCount > 1)
                {
                    mRepeatCount -= 1;
                    mCurrentTime = 0;
                    advanceTime((previousTime + time) - mTotalTime);
                }
                else if (mRepeatCount < 1)
				{
					mCurrentTime = 0;
                    advanceTime((previousTime + time) - mTotalTime);
				}
				else
                {
                    dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
                }
            }
        }
        
		/** Forcefully stops the Delayed Call (useful when repeatCount = 0)*/
		public function stop():void
		{
			dispatchEvent(new Event(Event.REMOVE_FROM_JUGGLER));
		}
		
        /** Indicates if enough time has passed, and the call has already been executed. */
        public function get isComplete():Boolean 
        { 
            return mRepeatCount == 1 && mCurrentTime >= mTotalTime; 
        }
        
        /** The time for which calls will be delayed (in seconds). */
        public function get totalTime():Number { return mTotalTime; }
        
		/** The amount of calls that have already been made */
		public function get totalCalls():Number { return mTotalCalls; }
		
        /** The time that has already passed (in seconds). */
        public function get currentTime():Number { return mCurrentTime; }
        
        /** The number of times the call will be repeated. 
		 * If you set this number to 0, the call will be repeated an infinite amount of times. */
        public function get repeatCount():int { return mRepeatCount; }
        public function set repeatCount(value:int):void { mRepeatCount = value; }
		
		
    }
}