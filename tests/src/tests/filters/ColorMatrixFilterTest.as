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
    import starling.filters.ColorMatrixFilter;
    import starling.unit.UnitTest;

    import utils.GoldenFixture;

    public class ColorMatrixFilterTest extends UnitTest
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

            var filter:ColorMatrixFilter = new ColorMatrixFilter();
            filter.adjustHue(0.5);
            filter.adjustContrast(0.3);

            var image:Image = new Image(_fixture.checkerboardTexture);
            image.width = _fixture.width;
            image.height = _fixture.height;
            image.filter = filter;
            canvas.addChild(image);

            assertMatchesGolden(canvas, "filters/color-matrix", onComplete);
            filter.dispose();
        }
    }
}
