package tests
{
    import flash.events.Event;
    import flash.events.EventDispatcher;

    import org.flexunit.async.Async;

    /**
     * @author http://www.betriebsraum.de/blog/2010/07/20/asynchronous-callback-functions-in-flexunit/
     */
    public class AsyncUtil extends EventDispatcher
    {
        public static const ASYNC_EVENT:String = "asyncEvent";
        
        private var _testCase:Object;
        private var _callback:Function;
        private var _passThroughArgs:Array;
        private var _callbackArgs:Array;
        
        public function AsyncUtil(testCase:Object, callback:Function, passThroughArgs:Array = null)
        {
            this._testCase = testCase;
            this._callback = callback;
            this._passThroughArgs = passThroughArgs;
        }
        
        public static function asyncHandler(testCase:Object, callback:Function = null, passThroughArgs:Array = null, timeout:Number = 1500):Function
        {
            var asyncUtil:AsyncUtil = new AsyncUtil(testCase, callback, passThroughArgs);
            asyncUtil.addEventListener(ASYNC_EVENT, Async.asyncHandler(testCase, asyncUtil.asyncEventHandler, timeout));
            
            return asyncUtil.asyncCallbackHandler;
        }
        
        public function asyncEventHandler(event:Event, flexUnitPassThroughArgs:Object = null):void
        {
            if (_passThroughArgs) {
                _callbackArgs = _callbackArgs.concat(_passThroughArgs);
            }
            
            if (_callback is Function) {
                _callback.apply(null, _callbackArgs);
            }
        }
        
        public function asyncCallbackHandler(...args:Array):void
        {
            _callbackArgs = args;
            dispatchEvent(new Event(ASYNC_EVENT));
        }
        
    }
}