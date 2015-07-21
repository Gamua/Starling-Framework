package
{
    import flash.display.Sprite;
    
    import org.flexunit.internals.TraceListener;
    import org.flexunit.listeners.CIListener;
    import org.flexunit.runner.FlexUnitCore;
    
    import tests.animation.DelayedCallTest;
    import tests.animation.JugglerTest;
    import tests.animation.TweenTest;
    import tests.display.BlendModeTest;
    import tests.display.DisplayObjectContainerTest;
    import tests.display.DisplayObjectTest;
    import tests.display.MovieClipTest;
    import tests.display.QuadTest;
    import tests.display.Sprite3DTest;
    import tests.events.EventTest;
    import tests.geom.PolygonTest;
    import tests.text.TextFieldTest;
    import tests.textures.TextureAtlasTest;
    import tests.textures.TextureTest;
    import tests.utils.AssetManagerTest;
    import tests.utils.ColorTest;
    import tests.utils.MatrixUtilTest;
    import tests.utils.RectangleUtilTest;
    import tests.utils.UtilsTest;
    import tests.utils.VertexDataTest;
    
    public class FlexUnitRunner extends Sprite
    {
        public function FlexUnitRunner()
        {
            onCreationComplete();
        }
        
        private function onCreationComplete():void
        {
            var core:FlexUnitCore = new FlexUnitCore();
            core.addListener(new TraceListener());
            core.addListener(new CIListener());
            core.visualDisplayRoot = stage;
            core.run(currentRunTestSuite());
        }
        
        public function currentRunTestSuite():Array
        {
            var testsToRun:Array = new Array();
            testsToRun.push(tests.display.BlendModeTest);
            testsToRun.push(tests.utils.UtilsTest);
            testsToRun.push(tests.animation.JugglerTest);
            testsToRun.push(tests.display.QuadTest);
            testsToRun.push(tests.utils.AssetManagerTest);
            testsToRun.push(tests.animation.TweenTest);
            testsToRun.push(tests.display.DisplayObjectContainerTest);
            testsToRun.push(tests.animation.DelayedCallTest);
            testsToRun.push(tests.display.DisplayObjectTest);
            testsToRun.push(tests.utils.ColorTest);
            testsToRun.push(tests.text.TextFieldTest);
            testsToRun.push(tests.textures.TextureTest);
            testsToRun.push(tests.textures.TextureAtlasTest);
            testsToRun.push(tests.events.EventTest);
            testsToRun.push(tests.display.MovieClipTest);
            testsToRun.push(tests.utils.RectangleUtilTest);
            testsToRun.push(tests.utils.VertexDataTest);
            testsToRun.push(tests.utils.MatrixUtilTest);
            testsToRun.push(tests.utils.MathUtilTest);
            testsToRun.push(tests.display.Sprite3DTest);
            testsToRun.push(tests.geom.PolygonTest);
            testsToRun.push(tests.utils.ArrayUtilTest);
            return testsToRun;
        }
    }
}