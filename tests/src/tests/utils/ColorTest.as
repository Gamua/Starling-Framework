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
    import org.flexunit.asserts.assertEquals;

    import starling.utils.Color;

    import tests.Helpers;

    public class ColorTest
    {
        private static const E:Number = 0.004;

        [Test]
        public function testGetElement():void
        {
            var color:uint = 0xaabbcc;
            assertEquals(0xaa, Color.getRed(color));
            assertEquals(0xbb, Color.getGreen(color));
            assertEquals(0xcc, Color.getBlue(color));
        }

        [Test]
        public function testSetElement():void
        {
            var color:uint = 0xaabbccdd;
            assertEquals(0xffbbccdd, Color.setAlpha(color, 0xff));
            assertEquals(0xaaffccdd, Color.setRed(color, 0xff));
            assertEquals(0xaabbffdd, Color.setGreen(color, 0xff));
            assertEquals(0xaabbccff, Color.setBlue(color, 0xff));
        }

        [Test]
        public function testRgb():void
        {
            var color:uint = Color.rgb(0xaa, 0xbb, 0xcc);
            assertEquals(0xaabbcc, color);
        }

        [Test]
        public function testArgb():void
        {
            var color:uint = Color.argb(0xaa, 0xbb, 0xcc, 0xdd);
            assertEquals(0xaabbccdd, color);
        }

        [Test]
        public function testHslToRgb():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/hsl-to-rgb.htm
            assertEquals(Color.hsl(d2u(0), 0.5, 0), 0x000000);
            assertEquals(Color.hsl(d2u(0), 0.5, 1.0), 0xFFFFFF);
            assertEquals(Color.hsl(d2u(0), 1.0, 0.5), 0xFF0000);
            assertEquals(Color.hsl(d2u(60), 1.0, 0.5), 0xFFFF00);
            assertEquals(Color.hsl(d2u(120), 1.0, 0.5), 0x00FF00);
            assertEquals(Color.hsl(d2u(180), 1.0, 0.5), 0x00FFFF);
            assertEquals(Color.hsl(d2u(240), 1.0, 0.5), 0x0000FF);
            assertEquals(Color.hsl(d2u(300), 1.0, 0.5), 0xFF00FF);
            assertEquals(Color.hsl(d2u(0), 0, 0.75), 0xC0C0C0);
            assertEquals(Color.hsl(d2u(0), 0, 0.5), 0x808080);
            assertEquals(Color.hsl(d2u(0), 1.0, 0.25), 0x800000);
            assertEquals(Color.hsl(d2u(60), 1.0, 0.25), 0x808000);
            assertEquals(Color.hsl(d2u(120), 1.0, 0.25), 0x008000);
            assertEquals(Color.hsl(d2u(300), 1.0, 0.25), 0x800080);
            assertEquals(Color.hsl(d2u(180), 1.0, 0.25), 0x008080);
            assertEquals(Color.hsl(d2u(240), 1.0, 0.25), 0x000080);
        }

        [Test]
        public function testRgbToHsl():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/rgb-to-hsl.htm
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x000000), new <Number>[d2u(0), 0, 0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0xFFFFFF), new <Number>[d2u(0), 0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0xFF0000), new <Number>[d2u(0), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0xFFFF00), new <Number>[d2u(60), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x00FF00), new <Number>[d2u(120), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x00FFFF), new <Number>[d2u(180), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x0000FF), new <Number>[d2u(240), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0xFF00FF), new <Number>[d2u(300), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0xC0C0C0), new <Number>[d2u(0), 0, 0.75], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x808080), new <Number>[d2u(0), 0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x800000), new <Number>[d2u(0), 1.0, 0.25], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x808000), new <Number>[d2u(60), 1.0, 0.25], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x008000), new <Number>[d2u(120), 1.0, 0.25], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x800080), new <Number>[d2u(300), 1.0, 0.25], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x008080), new <Number>[d2u(180), 1.0, 0.25], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsl(0x000080), new <Number>[d2u(240), 1.0, 0.25], E);
        }

        [Test]
        public function testHsvToRgb():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/hsv-to-rgb.htm
            assertEquals(Color.hsv(d2u(0), 0, 0), 0x000000);
            assertEquals(Color.hsv(d2u(0), 0, 1.0), 0xFFFFFF);
            assertEquals(Color.hsv(d2u(0), 1.0, 1.0), 0xFF0000);
            assertEquals(Color.hsv(d2u(60), 1.0, 1.0), 0xFFFF00);
            assertEquals(Color.hsv(d2u(120), 1.0, 1.0), 0x00FF00);
            assertEquals(Color.hsv(d2u(180), 1.0, 1.0), 0x00FFFF);
            assertEquals(Color.hsv(d2u(240), 1.0, 1.0), 0x0000FF);
            assertEquals(Color.hsv(d2u(300), 1.0, 1.0), 0xFF00FF);
            assertEquals(Color.hsv(d2u(0), 0, 0.75), 0xC0C0C0);
            assertEquals(Color.hsv(d2u(0), 0, 0.5), 0x808080);
            assertEquals(Color.hsv(d2u(0), 1.0, 0.5), 0x800000);
            assertEquals(Color.hsv(d2u(60), 1.0, 0.5), 0x808000);
            assertEquals(Color.hsv(d2u(120), 1.0, 0.5), 0x008000);
            assertEquals(Color.hsv(d2u(300), 1.0, 0.5), 0x800080);
            assertEquals(Color.hsv(d2u(180), 1.0, 0.5), 0x008080);
            assertEquals(Color.hsv(d2u(240), 1.0, 0.5), 0x000080);
        }

        [Test]
        public function testRgbToHsv():void
        {
            // Colors from: http://www.rapidtables.com/convert/color/rgb-to-hsv.htm
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x000000), new <Number>[d2u(0), 0, 0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0xFFFFFF), new <Number>[d2u(0), 0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0xFF0000), new <Number>[d2u(0), 1.0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0xFFFF00), new <Number>[d2u(60), 1.0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x00FF00), new <Number>[d2u(120), 1.0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x00FFFF), new <Number>[d2u(180), 1.0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x0000FF), new <Number>[d2u(240), 1.0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0xFF00FF), new <Number>[d2u(300), 1.0, 1.0], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0xC0C0C0), new <Number>[d2u(0), 0, 0.75], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x808080), new <Number>[d2u(0), 0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x800000), new <Number>[d2u(0), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x808000), new <Number>[d2u(60), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x008000), new <Number>[d2u(120), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x800080), new <Number>[d2u(300), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x008080), new <Number>[d2u(180), 1.0, 0.5], E);
            Helpers.compareVectorsOfNumbers(Color.rgbToHsv(0x000080), new <Number>[d2u(240), 1.0, 0.5], E);
        }
        
        private static function d2u(deg:Number):Number
        {
            return deg / 360.0;
        }
    }
}