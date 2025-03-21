package starling.unit
{
    import flash.utils.getTimer;

    import starling.display.Sprite;
    import starling.events.Event;
    import starling.utils.Color;
    import flash.utils.getQualifiedClassName;
    import starling.errors.AbstractClassError;

    public class TestGui extends Sprite
    {
        private var _testRunner:TestRunner;
        private var _loop:Boolean;
        private var _testCount:int;
        private var _successCount:int;
        private var _startMoment:Number;
        private var _isPaused:Boolean;

        public function TestGui(testRunner:TestRunner)
        {
            _testRunner = testRunner;
            _testRunner.logFunction    = log;
            _testRunner.assertFunction = assert;

            if (getQualifiedClassName(this) == "starling.unit::TestGui")
                throw new AbstractClassError();
        }

        public function start(loop:Boolean=false):void
        {
            _loop = loop;
            _startMoment = getTimer() / 1000;
            _isPaused = false;
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        public function stop():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            _testRunner.resetRun();
        }

        private function onEnterFrame(event:Event):void
        {
            if (_isPaused) return;

            var status:String = _testRunner.runNext();

            if (status == TestRunner.STATUS_FINISHED)
            {
                var duration:int = getTimer() / 1000 - _startMoment;
                stop();

                log("Finished all tests!", Color.AQUA);
                log("Duration: " + duration + " seconds.", Color.AQUA);

                if (_loop) start(true);
                else       onFinished();
            }
        }

        public function onFinished():void
        {
            // override in subclass
        }

        public function log(message:String, color:uint=0xffffff):void
        {
            trace(message);
        }

        public function assert(success:Boolean, message:String=null):void
        {
            _testCount++;

            if (success)
            {
                _successCount++;
            }
            else
            {
                message = message ? message : "Assertion failed.";
                log(" " + message, Color.RED);
            }
        }

        public function get testCount():int { return _testCount; }
        public function get successCount():int { return _successCount; }
        public function get isStarted():Boolean { return _startMoment >= 0; }

        public function get isPaused():Boolean { return _isPaused; }
        public function set isPaused(value:Boolean):void { _isPaused = value; }
    }
}