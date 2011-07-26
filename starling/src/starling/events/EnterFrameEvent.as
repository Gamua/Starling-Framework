package starling.events
{
    public class EnterFrameEvent extends Event
    {
        private var mPassedTime:Number;
        
        public function EnterFrameEvent(type:String, passedTime:Number, bubbles:Boolean=false)
        {
            super(type, bubbles);
            mPassedTime = passedTime;
        }
        
        public function get passedTime():Number { return mPassedTime; }
    }
}