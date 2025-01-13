package tests.text
{
    import starling.display.MeshBatch;
    import starling.text.TextField;
    import starling.text.TextFieldAutoSize;
    import starling.text.TextFormat;
    import starling.textures.Texture;
    import starling.unit.UnitTest;

    public class TextFieldTest extends UnitTest
    {
        private static const E:Number = 0.0001;
        private static const SUPER_LARGE_TEXT_LENGTH:Number = 3200;

        public function testTextField():void
        {
            var textField:TextField = new TextField(240, 50, "test text");
            assertEqual("test text", textField.text);
        }

        public function testWidthAndHeight():void
        {
            var textField:TextField = new TextField(100, 50, "test");

            assertEquivalent(textField.width,  100);
            assertEquivalent(textField.height, 50);
            assertEquivalent(textField.scaleX, 1.0);
            assertEquivalent(textField.scaleY, 1.0);

            textField.scale = 0.5;

            assertEquivalent(textField.width, 50);
            assertEquivalent(textField.height, 25);
            assertEquivalent(textField.scaleX, 0.5);
            assertEquivalent(textField.scaleY, 0.5);

            textField.width = 100;
            textField.height = 50;

            assertEquivalent(textField.width,  100);
            assertEquivalent(textField.height, 50);
            assertEquivalent(textField.scaleX, 0.5);
            assertEquivalent(textField.scaleY, 0.5);
        }

        public function testLargeTextField():void
        {
            var maxTextureSize:int = Texture.maxSize;
            var sampleText:String = getSampleText(SUPER_LARGE_TEXT_LENGTH * (maxTextureSize / 2048));
            var textField:TextField = new TextField(500, 50, sampleText);
            textField.format = new TextFormat("_sans", 32);
            textField.autoSize = TextFieldAutoSize.VERTICAL;
            assert(textField.height > maxTextureSize);

            var textureSize:Texture = mainTextureFromTextField(textField);
            assertTrue(textureSize);
            assert(textureSize ? textureSize.height * textureSize.scale : 0 <= maxTextureSize);
        }

        /** Creates a sample text longer than 'leastLength'. */
        private function getSampleText(leastLength:int):String
        {
            const sample:String = "This is a sample String. ";
            var repeat:int = Math.ceil(leastLength / sample.length);
            var parts:Vector.<String> = new Vector.<String>(repeat);

            for (var i:int = 0; i < repeat; i++)
                parts[i] = sample;

            return parts.join("");
        }

        /** Retrieves the TextField's internally used 'Texture'. */
        private function mainTextureFromTextField(textField:TextField):Texture
        {
            for (var i:int = 0; i < textField.numChildren; i++)
            {
                var meshBatch:MeshBatch = textField.getChildAt(i) as MeshBatch;
                if (meshBatch) return meshBatch.texture;
            }
            return null;
        }
    }
}