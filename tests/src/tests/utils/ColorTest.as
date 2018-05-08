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

    public class ColorTest
    {
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
    }
}