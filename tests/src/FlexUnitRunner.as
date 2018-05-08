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
    import tests.display.ButtonTest;
    import tests.display.DisplayObjectContainerTest;
    import tests.display.DisplayObjectTest;
    import tests.display.ImageTest;
    import tests.display.MeshTest;
    import tests.display.MovieClipTest;
    import tests.display.QuadTest;
    import tests.display.Sprite3DTest;
    import tests.events.EventTest;
    import tests.filters.FilterChainTest;
    import tests.filters.FragmentFilterTest;
    import tests.geom.PolygonTest;
    import tests.rendering.IndexDataTest;
    import tests.rendering.MeshStyleTest;
    import tests.rendering.VertexDataFormatTest;
    import tests.rendering.VertexDataTest;
    import tests.text.TextFieldTest;
    import tests.textures.TextureAtlasTest;
    import tests.textures.TextureTest;
    import tests.utils.AssetManagerTest;
    import tests.utils.ByteArrayUtilTest;
    import tests.utils.ColorTest;
    import tests.utils.MathUtilTest;
    import tests.utils.MatrixUtilTest;
    import tests.utils.RectangleUtilTest;
    import tests.utils.StringUtilTest;
    import tests.utils.UtilsTest;

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
            testsToRun.push(BlendModeTest);
            testsToRun.push(UtilsTest);
            testsToRun.push(JugglerTest);
            testsToRun.push(MeshTest);
            testsToRun.push(QuadTest);
            testsToRun.push(ImageTest);
            testsToRun.push(AssetManagerTest);
            testsToRun.push(TweenTest);
            testsToRun.push(DisplayObjectContainerTest);
            testsToRun.push(DelayedCallTest);
            testsToRun.push(DisplayObjectTest);
            testsToRun.push(ColorTest);
            testsToRun.push(TextFieldTest);
            testsToRun.push(TextureTest);
            testsToRun.push(TextureAtlasTest);
            testsToRun.push(EventTest);
            testsToRun.push(MovieClipTest);
            testsToRun.push(RectangleUtilTest);
            testsToRun.push(MatrixUtilTest);
            testsToRun.push(MathUtilTest);
            testsToRun.push(StringUtilTest);
            testsToRun.push(Sprite3DTest);
            testsToRun.push(PolygonTest);
            testsToRun.push(IndexDataTest);
            testsToRun.push(VertexDataTest);
            testsToRun.push(VertexDataFormatTest);
            testsToRun.push(FilterChainTest);
            testsToRun.push(FragmentFilterTest);
            testsToRun.push(MeshStyleTest);
            testsToRun.push(ButtonTest);
            testsToRun.push(ByteArrayUtilTest);
            return testsToRun;
        }
    }
}