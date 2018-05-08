package tests.text
{
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertTrue;
    import org.hamcrest.assertThat;
    import org.hamcrest.number.closeTo;
    import org.hamcrest.number.greaterThan;
    import org.hamcrest.number.lessThanOrEqualTo;

    import starling.display.MeshBatch;
    import starling.text.TextField;
    import starling.text.TextFieldAutoSize;
    import starling.text.TextFormat;
    import starling.textures.Texture;

    import tests.StarlingTestCase;

    public class TextFieldTest extends StarlingTestCase
    {
        private static const E:Number = 0.0001;
        private static const SUPER_LARGE_TEXT_LENGTH:Number = 3200;

        [Test]
        public function testTextField():void
        {
            var textField:TextField = new TextField(240, 50, "test text");
            assertEquals("test text", textField.text);
        }

        [Test]
        public function testWidthAndHeight():void
        {
            var textField:TextField = new TextField(100, 50, "test");

            assertThat(textField.width,  closeTo(100, E));
            assertThat(textField.height, closeTo(50, E));
            assertThat(textField.scaleX, closeTo(1.0, E));
            assertThat(textField.scaleY, closeTo(1.0, E));

            textField.scale = 0.5;

            assertThat(textField.width, closeTo(50, E));
            assertThat(textField.height, closeTo(25, E));
            assertThat(textField.scaleX, closeTo(0.5, E));
            assertThat(textField.scaleY, closeTo(0.5, E));

            textField.width = 100;
            textField.height = 50;

            assertThat(textField.width,  closeTo(100, E));
            assertThat(textField.height, closeTo(50, E));
            assertThat(textField.scaleX, closeTo(0.5, E));
            assertThat(textField.scaleY, closeTo(0.5, E));
        }

        [Test]
        public function testLargeTextField():void
        {
            var maxTextureSize:int = Texture.maxSize;
            var sampleText:String = getSampleText(SUPER_LARGE_TEXT_LENGTH * (maxTextureSize / 2048));
            var textField:TextField = new TextField(500, 50, sampleText);
            textField.format = new TextFormat("_sans", 32);
            textField.autoSize = TextFieldAutoSize.VERTICAL;

            assertThat(textField.height, greaterThan(maxTextureSize));

            var textureSize:Texture = mainTextureFromTextField(textField);
            assertTrue(textureSize);
            assertThat(textureSize ? textureSize.height * textureSize.scale : 0,
                    lessThanOrEqualTo(maxTextureSize));
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