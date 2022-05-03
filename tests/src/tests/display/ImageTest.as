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
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertNull;
    import org.hamcrest.number.closeTo;

    import starling.display.Image;
    import starling.textures.Texture;

    import tests.Helpers;
    import tests.utils.MockTexture;

    public class ImageTest
    {
        private static const E:Number = 0.00001;

        [Test]
        public function testBindScale9GridToTexture():void
        {
            var image:Image;
            var texture:Texture = new MockTexture(16, 16);
            var texture2:Texture = new MockTexture(16, 16);
            var scale9Grid:Rectangle = new Rectangle(2, 2, 12, 12);

            Image.bindScale9GridToTexture(texture, scale9Grid);

            image = new Image(texture);
            Helpers.compareRectangles(image.scale9Grid, scale9Grid);

            image.texture = texture2;
            assertNull(image.scale9Grid);

            Image.resetSetupForTexture(texture);

            image = new Image(texture);
            assertNull(image.scale9Grid);
        }

        [Test]
        public function testBindPivotPointToTexture():void
        {
            var image:Image;
            var texture:Texture = new MockTexture(16, 16);
            var texture2:Texture = new MockTexture(16, 16);
            var pivotX:Number = 4;
            var pivotY:Number = 8;

            Image.bindPivotPointToTexture(texture, pivotX, pivotY);

            image = new Image(texture);
            assertThat(image.pivotX, closeTo(pivotX, E));
            assertThat(image.pivotY, closeTo(pivotY, E));

            image.texture = texture2;
            assertEquals(image.pivotX, 0);
            assertEquals(image.pivotY, 0);

            Image.resetSetupForTexture(texture);

            image = new Image(texture);
            assertEquals(image.pivotX, 0);
            assertEquals(image.pivotY, 0);
        }

        [Test]
        public function testAddAndRemoveAutomatedSetup():void
        {
            var image:Image;
            var texture:Texture = new MockTexture(16, 16);
            var setupColor:uint = 0xff0000;
            var releaseColor:uint = 0x00ff00;

            Image.automateSetupForTexture(texture, onAssign, onRelease);
            image = new Image(texture);
            assertEquals(image.color, setupColor);

            assertEquals(image.color, setupColor);
            image.texture = null;
            assertEquals(image.color, releaseColor);

            Image.removeSetupForTexture(texture, onAssign, onRelease);
            image.texture = texture;
            assertEquals(image.color, releaseColor);

            image.color = 0x0;
            assertEquals(image.color, 0x0);

            function onAssign(image:Image):void { image.color = setupColor; }
            function onRelease(image:Image):void { image.color = releaseColor; }
        }

        [Test]
        public function testAutomatedSetupWithMultipleCallbacks():void
        {
            var image:Image;
            var texture:Texture = new MockTexture(16, 16);
            var pivotX:Number = 4;
            var pivotY:Number = 8;
            var setupColor:uint = 0xff0000;
            var releaseColor:uint = 0;

            Image.bindPivotPointToTexture(texture, pivotX, pivotY);
            Image.automateSetupForTexture(texture,
                function(image:Image):void { image.color = setupColor; },
                function(image:Image):void { image.color = releaseColor; });

            image = new Image(texture);

            assertThat(image.pivotX, closeTo(pivotX, E));
            assertThat(image.pivotY, closeTo(pivotY, E));
            assertEquals(image.color, setupColor);

            image.texture = new MockTexture(16, 16);

            assertEquals(image.pivotX, 0);
            assertEquals(image.pivotY, 0);
            assertEquals(image.color, 0);

            Image.resetSetupForTexture(texture);
            image.texture = texture;

            assertEquals(image.pivotX, 0);
            assertEquals(image.pivotY, 0);
            assertEquals(image.color, releaseColor);
        }
    }
}
