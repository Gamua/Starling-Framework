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
        
        private var testCase:Object;
        private var callback:Function;
        private var passThroughArgs:Array;
        private var callbackArgs:Array;
        
        public function AsyncUtil(testCase:Object, callback:Function, passThroughArgs:Array = null)
        {
            this.testCase = testCase;
            this.callback = callback;
            this.passThroughArgs = passThroughArgs;
        }
        
        public static function asyncHandler(testCase:Object, callback:Function = null, passThroughArgs:Array = null, timeout:Number = 1500):Function
        {
            var asyncUtil:AsyncUtil = new AsyncUtil(testCase, callback, passThroughArgs);
            asyncUtil.addEventListener(ASYNC_EVENT, Async.asyncHandler(testCase, asyncUtil.asyncEventHandler, timeout));
            
            return asyncUtil.asyncCallbackHandler;
        }
        
        public function asyncEventHandler(event:Event, flexUnitPassThroughArgs:Object = null):void
        {
            if (passThroughArgs) {
                callbackArgs = callbackArgs.concat(passThroughArgs);
            }
            
            if (callback is Function) {
                callback.apply(null, callbackArgs);
            }
        }
        
        public function asyncCallbackHandler(...args:Array):void
        {
            callbackArgs = args;
            dispatchEvent(new Event(ASYNC_EVENT));
        }
        
    }
}