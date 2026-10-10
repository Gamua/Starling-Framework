// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.filters
{
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.filters.BlurFilter;
    import starling.unit.UnitTest;

    import utils.GoldenFixture;

    public class BlurFilterTest extends UnitTest
    {
        private var _fixture:GoldenFixture;

        override public function setUp():void
        {
            super.setUp();
            _fixture = new GoldenFixture();
        }

        override public function tearDown():void
        {
            _fixture.dispose();
            super.tearDown();
        }

        public function testRendering(onComplete:Function):void
        {
            var canvas:Sprite = _fixture.createCanvas();
            var filter:BlurFilter = new BlurFilter(2, 2);

            var image:Image = new Image(_fixture.checkerboardTexture);
            image.scale = 2;
            image.x = image.y = 32;
            image.filter = filter;
            canvas.addChild(image);

            assertMatchesGolden(canvas, "filters/blur", onComplete);
            filter.dispose();
        }
    }
}
