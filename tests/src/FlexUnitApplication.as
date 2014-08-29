package
{
    import Array.*;
    
    import flash.display.Sprite;
    
    import flexunit.flexui.FlexUnitTestRunnerUIAS;
    
    import tests.animation.DelayedCallTest;
    import tests.animation.JugglerTest;
    import tests.animation.TweenTest;
    import tests.display.BlendModeTest;
    import tests.display.DisplayObjectContainerTest;
    import tests.display.DisplayObjectTest;
    import tests.display.MovieClipTest;
    import tests.display.QuadTest;
    import tests.events.EventTest;
    import tests.textures.TextureAtlasTest;
    import tests.textures.TextureTest;
    import tests.utils.AssetManagerTest;
    import tests.utils.ColorTest;
    import tests.utils.RectangleUtilTest;
    import tests.utils.UtilsTest;
    import tests.utils.VertexDataTest;
    
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
            testsToRun.push(tests.utils.AssetManagerTest);
            testsToRun.push(tests.utils.ColorTest);
            testsToRun.push(tests.textures.TextureAtlasTest);
            testsToRun.push(tests.animation.JugglerTest);
            testsToRun.push(tests.display.QuadTest);
            testsToRun.push(tests.display.DisplayObjectContainerTest);
            testsToRun.push(tests.utils.UtilsTest);
            testsToRun.push(tests.display.DisplayObjectTest);
            testsToRun.push(tests.display.BlendModeTest);
            testsToRun.push(tests.display.MovieClipTest);
            testsToRun.push(tests.utils.RectangleUtilTest);
            testsToRun.push(tests.utils.VertexDataTest);
            testsToRun.push(tests.events.EventTest);
            testsToRun.push(tests.animation.DelayedCallTest);
            testsToRun.push(tests.animation.TweenTest);
            testsToRun.push(tests.textures.TextureTest);
            return testsToRun;
        }
    }
}