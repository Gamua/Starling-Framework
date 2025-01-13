// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import starling.unit.UnitTest;
    import starling.utils.Color;

    public class ColorTest extends UnitTest
    {
        private static const E:Number = 0.004;

        public function testGetElement():void
        {
            var color:uint = 0xaabbcc;
            assertEqual(0xaa, Color.getRed(color));
            assertEqual(0xbb, Color.getGreen(color));
            assertEqual(0xcc, Color.getBlue(color));
        }

        public function testSetElement():void
        {
            var color:uint = 0xaabbccdd;
            assertEqual(0xffbbccdd, Color.setAlpha(color, 0xff));
            assertEqual(0xaaffccdd, Color.setRed(color, 0xff));
            assertEqual(0xaabbffdd, Color.setGreen(color, 0xff));
            assertEqual(0xaabbccff, Color.setBlue(color, 0xff));
        }

        public function testRgb():void
        {
            var color:uint = Color.rgb(0xaa, 0xbb, 0xcc);
            assertEqual(0xaabbcc, color);
        }

        public function testArgb():void
        {
            var color:uint = Color.argb(0xaa, 0xbb, 0xcc, 0xdd);
            assertEqual(0xaabbccdd, color);
        }

        public function testHslToRgb():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/hsl-to-rgb.htm
            assertEqual(Color.hsl(d2u(0), 0.5, 0), 0x000000);
            assertEqual(Color.hsl(d2u(0), 0.5, 1.0), 0xFFFFFF);
            assertEqual(Color.hsl(d2u(0), 1.0, 0.5), 0xFF0000);
            assertEqual(Color.hsl(d2u(60), 1.0, 0.5), 0xFFFF00);
            assertEqual(Color.hsl(d2u(120), 1.0, 0.5), 0x00FF00);
            assertEqual(Color.hsl(d2u(180), 1.0, 0.5), 0x00FFFF);
            assertEqual(Color.hsl(d2u(240), 1.0, 0.5), 0x0000FF);
            assertEqual(Color.hsl(d2u(300), 1.0, 0.5), 0xFF00FF);
            assertEqual(Color.hsl(d2u(0), 0, 0.75), 0xC0C0C0);
            assertEqual(Color.hsl(d2u(0), 0, 0.5), 0x808080);
            assertEqual(Color.hsl(d2u(0), 1.0, 0.25), 0x800000);
            assertEqual(Color.hsl(d2u(60), 1.0, 0.25), 0x808000);
            assertEqual(Color.hsl(d2u(120), 1.0, 0.25), 0x008000);
            assertEqual(Color.hsl(d2u(300), 1.0, 0.25), 0x800080);
            assertEqual(Color.hsl(d2u(180), 1.0, 0.25), 0x008080);
            assertEqual(Color.hsl(d2u(240), 1.0, 0.25), 0x000080);
        }

        public function testRgbToHsl():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/rgb-to-hsl.htm
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x000000), new <Number>[d2u(0), 0, 0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0xFFFFFF), new <Number>[d2u(0), 0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0xFF0000), new <Number>[d2u(0), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0xFFFF00), new <Number>[d2u(60), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x00FF00), new <Number>[d2u(120), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x00FFFF), new <Number>[d2u(180), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x0000FF), new <Number>[d2u(240), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0xFF00FF), new <Number>[d2u(300), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0xC0C0C0), new <Number>[d2u(0), 0, 0.75], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x808080), new <Number>[d2u(0), 0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x800000), new <Number>[d2u(0), 1.0, 0.25], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x808000), new <Number>[d2u(60), 1.0, 0.25], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x008000), new <Number>[d2u(120), 1.0, 0.25], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x800080), new <Number>[d2u(300), 1.0, 0.25], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x008080), new <Number>[d2u(180), 1.0, 0.25], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsl(0x000080), new <Number>[d2u(240), 1.0, 0.25], E);
        }

        public function testHsvToRgb():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/hsv-to-rgb.htm
            assertEqual(Color.hsv(d2u(0), 0, 0), 0x000000);
            assertEqual(Color.hsv(d2u(0), 0, 1.0), 0xFFFFFF);
            assertEqual(Color.hsv(d2u(0), 1.0, 1.0), 0xFF0000);
            assertEqual(Color.hsv(d2u(60), 1.0, 1.0), 0xFFFF00);
            assertEqual(Color.hsv(d2u(120), 1.0, 1.0), 0x00FF00);
            assertEqual(Color.hsv(d2u(180), 1.0, 1.0), 0x00FFFF);
            assertEqual(Color.hsv(d2u(240), 1.0, 1.0), 0x0000FF);
            assertEqual(Color.hsv(d2u(300), 1.0, 1.0), 0xFF00FF);
            assertEqual(Color.hsv(d2u(0), 0, 0.75), 0xC0C0C0);
            assertEqual(Color.hsv(d2u(0), 0, 0.5), 0x808080);
            assertEqual(Color.hsv(d2u(0), 1.0, 0.5), 0x800000);
            assertEqual(Color.hsv(d2u(60), 1.0, 0.5), 0x808000);
            assertEqual(Color.hsv(d2u(120), 1.0, 0.5), 0x008000);
            assertEqual(Color.hsv(d2u(300), 1.0, 0.5), 0x800080);
            assertEqual(Color.hsv(d2u(180), 1.0, 0.5), 0x008080);
            assertEqual(Color.hsv(d2u(240), 1.0, 0.5), 0x000080);
        }

        public function testRgbToHsv():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/rgb-to-hsv.htm
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x000000), new <Number>[d2u(0), 0, 0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0xFFFFFF), new <Number>[d2u(0), 0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0xFF0000), new <Number>[d2u(0), 1.0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0xFFFF00), new <Number>[d2u(60), 1.0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x00FF00), new <Number>[d2u(120), 1.0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x00FFFF), new <Number>[d2u(180), 1.0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x0000FF), new <Number>[d2u(240), 1.0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0xFF00FF), new <Number>[d2u(300), 1.0, 1.0], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0xC0C0C0), new <Number>[d2u(0), 0, 0.75], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x808080), new <Number>[d2u(0), 0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x800000), new <Number>[d2u(0), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x808000), new <Number>[d2u(60), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x008000), new <Number>[d2u(120), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x800080), new <Number>[d2u(300), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x008080), new <Number>[d2u(180), 1.0, 0.5], E);
            assertEqualVectorsOfNumbers(Color.rgbToHsv(0x000080), new <Number>[d2u(240), 1.0, 0.5], E);
        }

        private static function d2u(deg:Number):Number
        {
            return deg / 360.0;
        }
    }
}