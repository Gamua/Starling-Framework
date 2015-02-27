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
		private const MAX_TEXTURE_DIMENSION:Number = 2048;
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
			var textField:TextField = new TextField(240, 50, sampleString(SUPER_LARGE_TEXT_LENGTH), "_sans", 32);
			textField.autoSize = TextFieldAutoSize.VERTICAL;
			
			assertThat(textField.height, greaterThan(MAX_TEXTURE_DIMENSION));
			
			var textureSize:Texture = mainTextureFromTextField(textField);
			Assert.assertTrue(textureSize);
			assertThat(textureSize ? textureSize.height * textureSize.scale : 0, lessThanOrEqualTo(MAX_TEXTURE_DIMENSION));
		}
		
		/**
		 * Sample String longer than leastLength.
		 * @param leastLength
		 * @return 
		 */
		private function sampleString(leastLength:int):String {
			const sample:String = "This is Sample String. ";
			var repeat:int = Math.ceil(leastLength / sample.length);
			var parts:Vector.<String> = new Vector.<String>(repeat);
			for (var i:int = 0; i < repeat; i++) {
				parts[i] = sample;
			}
			return parts.join();
		}
		
		/**
		 * returns Texture from main Image of TextFields.
		 * @param textField.
		 * @return main texture.
		 */
		private function mainTextureFromTextField(textField:TextField):Texture {
			for (var i:int = 0; i < textField.numChildren; i++) {
				var image:Image = textField.getChildAt(i) as Image;
				if (image) {
					return image.texture;
				}
			}
			return null;
		}
	}
}