// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flash.geom.Rectangle;

    import org.flexunit.assertThat;
    import org.hamcrest.number.closeTo;

    import starling.display.Button;
    import starling.textures.Texture;

    import tests.StarlingTestCase;
    import tests.utils.MockTexture;

    public class ButtonTest extends StarlingTestCase
    {
        private static const E:Number = 0.0001;

        [Test]
        public function testWidthAndHeight():void
        {
            var texture:Texture = new MockTexture(100, 50);
            var button:Button = new Button(texture, "test");
            var textBounds:Rectangle = new Rectangle();

            assertThat(button.width,  closeTo(100, E));
            assertThat(button.height, closeTo(50, E));
            assertThat(button.scaleX, closeTo(1.0, E));
            assertThat(button.scaleY, closeTo(1.0, E));

            button.scale = 0.5;
            textBounds.copyFrom(button.textBounds);

            assertThat(button.width, closeTo(50, E));
            assertThat(button.height, closeTo(25, E));
            assertThat(button.scaleX, closeTo(0.5, E));
            assertThat(button.scaleY, closeTo(0.5, E));
            assertThat(textBounds.width, closeTo(100, E));
            assertThat(textBounds.height, closeTo(50, E));

            button.width = 100;
            button.height = 50;
            textBounds.copyFrom(button.textBounds);

            assertThat(button.width,  closeTo(100, E));
            assertThat(button.height, closeTo(50, E));
            assertThat(button.scaleX, closeTo(0.5, E));
            assertThat(button.scaleY, closeTo(0.5, E));
            assertThat(textBounds.width, closeTo(200, E));
            assertThat(textBounds.height, closeTo(100, E));
        }
    }
}
