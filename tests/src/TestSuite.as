package
{
    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.display.Stage;
    import starling.unit.SimpleTestGui;
    import starling.unit.TestGui;
    import starling.unit.TestRunner;

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

    public class TestSuite extends Sprite
    {
        private var _testRunner:TestRunner;
        private var _testGui:TestGui;

        public function TestSuite()
        {
            _testRunner = createTestRunner();
            _testGui = createTestGui(_testRunner);

            addChild(_testGui);
            _testGui.start();
        }

        private function createTestRunner():TestRunner
        {
            var runner:TestRunner = new TestRunner();

            // animation
            runner.add(DelayedCallTest);
            runner.add(JugglerTest);
            runner.add(TweenTest);

            // display
            runner.add(BlendModeTest);
            runner.add(ButtonTest);
            runner.add(DisplayObjectContainerTest);
            runner.add(DisplayObjectTest);
            runner.add(ImageTest);
            runner.add(MeshTest);
            runner.add(MovieClipTest);
            runner.add(QuadTest);
            runner.add(Sprite3DTest);

            // events
            runner.add(EventTest);

            // filters
            runner.add(FilterChainTest);
            runner.add(FragmentFilterTest);

            // geom
            runner.add(PolygonTest);

            // rendering
            runner.add(IndexDataTest);
            runner.add(MeshStyleTest);
            runner.add(VertexDataFormatTest);
            runner.add(VertexDataTest);

            // text
            runner.add(TextFieldTest);

            // textures
            runner.add(TextureAtlasTest);
            runner.add(TextureTest);

            // utils
            runner.add(AssetManagerTest);
            runner.add(ByteArrayUtilTest);
            runner.add(ColorTest);
            runner.add(MathUtilTest);
            runner.add(MatrixUtilTest);
            runner.add(RectangleUtilTest);
            runner.add(StringUtilTest);
            runner.add(UtilsTest);

            return runner;
        }

        private function createTestGui(testRunner:TestRunner): TestGui
        {
            var padding:int = 10;
            var stage:Stage = Starling.current.stage;
            var width:int = stage.stageWidth - 2 * padding;
            var height:int = stage.stageHeight - 2 * padding;
            var gui:TestGui = new SimpleTestGui(_testRunner, width, height);
            gui.x = gui.y = padding;
            return gui;
        }
    }
}