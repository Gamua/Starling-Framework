// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.unit
{
    import flash.display.BitmapData;

    import starling.unit.ImageDiff;
    import starling.unit.UnitTest;

    public class ImageDiffTest extends UnitTest
    {
        public function testCompareIdenticalImages():void
        {
            var image:BitmapData = new BitmapData(4, 4, true, 0xff336699);
            var diff:ImageDiff = ImageDiff.compare(image, image.clone(), 0);

            assertEqual(0, diff.numDiffPixels);
            assertEqual(0, diff.maxDelta);
        }

        public function testCompareWithThreshold():void
        {
            var expected:BitmapData = new BitmapData(4, 4, true, 0xff808080);
            var actual:BitmapData = expected.clone();
            actual.setPixel32(1, 0, 0xff838080); // red channel +3: within threshold
            actual.setPixel32(2, 0, 0xff80808a); // blue channel +10: above threshold

            var diff:ImageDiff = ImageDiff.compare(expected, actual, 5);

            assertEqual(1, diff.numDiffPixels);
            assertEqual(10, diff.maxDelta);
            assertEqual(0xffff0000, diff.image.getPixel32(2, 0));
            assertEqual(0xff838080, diff.image.getPixel32(1, 0));
        }
    }
}
