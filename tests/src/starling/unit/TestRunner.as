package starling.unit
{
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;

    import starling.utils.StringUtil;

    public class TestRunner
    {
        public static const STATUS_FINISHED:String = "finished";
        public static const STATUS_RUNNING:String  = "running";
        public static const STATUS_WAITING:String  = "waiting";

        private var _tests:Array;
        private var _logFunction:Function;
        private var _assertFunction:Function;
        private var _currentTestIndex:int;
        private var _waiting:Boolean;

        public function TestRunner()
        {
            _tests = [];
            _currentTestIndex = 0;
            _waiting = false;

            _logFunction = trace;
            _assertFunction = function(success:Boolean, message:String=null):void
            {
                if (success) trace("Success!");
                else trace(message ? message : "Assertion failed.");
            };
        }

        public function add(testClass:Class):void
        {
            var typeInfo:XML = describeType(testClass);
            var methodNames:Array = [];

            for each (var method:XML in typeInfo.factory.method)
                if (method.@name.toLowerCase().indexOf("test") == 0)
                    methodNames.push(method.@name.toString());

            methodNames.sort();

            for each (var methodName:String in methodNames)
                _tests.push([testClass, methodName]);
        }

        public function runNext():String
        {
            if (_waiting) return STATUS_WAITING;
            if (_currentTestIndex == _tests.length) return STATUS_FINISHED;

            _waiting = true;
            var testData:Array = _tests[_currentTestIndex++];
            runTest(testData[0], testData[1], onComplete);
            return _waiting ? STATUS_WAITING : STATUS_RUNNING;

            function onComplete():void
            {
                _waiting = false;
            }
        }

        public function resetRun():void
        {
            _currentTestIndex = 0;
        }

        private function runTest(testClass:Class, methodName:String, onComplete:Function):void
        {
            var className:String = getQualifiedClassName(testClass).split("::").pop();
            logFunction(StringUtil.format("{0}.{1} ...", className, methodName));

            var test:UnitTest = new testClass() as UnitTest;
            test.assertFunction = _assertFunction;

            setUp();

            function setUp():void
            {
                test.setUp();
                test.setUpAsync(run);
            }

            function run():void
            {
                var method:Function = test[methodName];
                var async:Boolean = method.length != 0;
                if (async)
                {
                    method(tearDown);
                }
                else
                {
                    method();
                    tearDown();
                }
            }

            function tearDown():void
            {
                test.tearDown();
                test.tearDownAsync(onComplete);
            }
        }

        public function get assertFunction():Function { return _assertFunction; }
        public function set assertFunction(value:Function):void { _assertFunction = value; }

        public function get logFunction():Function { return _logFunction; }
        public function set logFunction(value:Function):void { _logFunction = value; }
   }
}