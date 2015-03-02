package tests.text
{
    import flexunit.framework.Assert;

    import org.hamcrest.assertThat;
    import org.hamcrest.number.greaterThan;
    import org.hamcrest.number.lessThanOrEqualTo;

    import starling.display.Image;
    import starling.text.TextField;
    import starling.text.TextFieldAutoSize;
    import starling.textures.Texture;

    import tests.StarlingTestCase;

    public class TextFieldTest extends StarlingTestCase
    {
        private const SUPER_LARGE_TEXT_LENGTH:Number = 3200;

        [Test]
        public function testTextField():void
        {
            var textField:TextField = new TextField(240, 50, "test text", "_sans", 16);
            Assert.assertEquals("test text", textField.text);
        }

        [Test]
        public function testLargeTextField():void
        {
            var maxTextureSize:int = Texture.maxSize;
            var sampleText:String = getSampleText(SUPER_LARGE_TEXT_LENGTH * (maxTextureSize / 2048));
            var textField:TextField = new TextField(500, 50, sampleText, "_sans", 32);
            textField.autoSize = TextFieldAutoSize.VERTICAL;

            assertThat(textField.height, greaterThan(maxTextureSize));

            var textureSize:Texture = mainTextureFromTextField(textField);
            Assert.assertTrue(textureSize);
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

            return parts.join();
        }

        /** Retrieves the TextField's internally used 'Texture'. */
        private function mainTextureFromTextField(textField:TextField):Texture
        {
            for (var i:int = 0; i < textField.numChildren; i++)
            {
                var image:Image = textField.getChildAt(i) as Image;
                if (image) return image.texture;
            }
            return null;
        }
    }
}