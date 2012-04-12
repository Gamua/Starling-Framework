package
{
    import Array;
    
    import flash.display.Sprite;
    
    import flexunit.flexui.FlexUnitTestRunnerUIAS;
    
    import tests.BlendModeTest;
    import tests.ColorTest;
    import tests.DisplayObjectContainerTest;
    import tests.DisplayObjectTest;
    import tests.EventTest;
    import tests.JugglerTest;
    import tests.MovieClipTest;
    import tests.QuadTest;
    import tests.TextureAtlasTest;
    import tests.TextureTest;
    import tests.TweenTest;
    import tests.UtilsTest;
    import tests.VertexDataTest;
    
    public class FlexUnitApplication extends Sprite
    {
        public function FlexUnitApplication()
        {
            onCreationComplete();
        }
        
        private function onCreationComplete():void
        {
            var testRunner:FlexUnitTestRunnerUIAS=new FlexUnitTestRunnerUIAS();
            testRunner.portNumber=8765; 
            this.addChild(testRunner); 
            testRunner.runWithFlexUnit4Runner(currentRunTestSuite(), "Starling-Tests");
        }
        
        public function currentRunTestSuite():Array
        {
            var testsToRun:Array = new Array();
            testsToRun.push(tests.TextureAtlasTest);
            testsToRun.push(tests.DisplayObjectTest);
            testsToRun.push(tests.VertexDataTest);
            testsToRun.push(tests.BlendModeTest);
            testsToRun.push(tests.TextureTest);
            testsToRun.push(tests.DisplayObjectContainerTest);
            testsToRun.push(tests.MovieClipTest);
            testsToRun.push(tests.UtilsTest);
            testsToRun.push(tests.JugglerTest);
            testsToRun.push(tests.TweenTest);
            testsToRun.push(tests.ColorTest);
            testsToRun.push(tests.QuadTest);
            testsToRun.push(tests.EventTest);
            return testsToRun;
        }
    }
}