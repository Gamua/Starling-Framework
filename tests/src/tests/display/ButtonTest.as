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

    import starling.display.Button;
    import starling.textures.Texture;
    import starling.unit.UnitTest;

    import utils.MockTexture;

    public class ButtonTest extends UnitTest
    {
        private static const E:Number = 0.0001;

        public function testWidthAndHeight():void
        {
            var texture:Texture = new MockTexture(100, 50);
            var button:Button = new Button(texture, "test");
            var textBounds:Rectangle = new Rectangle();

            assertEquivalent(button.width,  100);
            assertEquivalent(button.height, 50);
            assertEquivalent(button.scaleX, 1.0);
            assertEquivalent(button.scaleY, 1.0);

            button.scale = 0.5;
            textBounds.copyFrom(button.textBounds);

            assertEquivalent(button.width, 50);
            assertEquivalent(button.height, 25);
            assertEquivalent(button.scaleX, 0.5);
            assertEquivalent(button.scaleY, 0.5);
            assertEquivalent(textBounds.width, 100);
            assertEquivalent(textBounds.height, 50);

            button.width = 100;
            button.height = 50;
            textBounds.copyFrom(button.textBounds);

            assertEquivalent(button.width,  100);
            assertEquivalent(button.height, 50);
            assertEquivalent(button.scaleX, 0.5);
            assertEquivalent(button.scaleY, 0.5);
            assertEquivalent(textBounds.width, 200);
            assertEquivalent(textBounds.height, 100);
        }
    }
}
