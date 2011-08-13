// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests
{
    import flexunit.framework.Assert;
    
    import starling.utils.Color;

    public class ColorTest
    {		
        [Test]
        public function testGetElement():void
        {
            var color:uint = 0xaabbcc;
            Assert.assertEquals(0xaa, Color.getRed(color));
            Assert.assertEquals(0xbb, Color.getGreen(color));
            Assert.assertEquals(0xcc, Color.getBlue(color));
        }
        
        [Test]
        public function testRgb():void
        {
            var color:uint = Color.rgb(0xaa, 0xbb, 0xcc);
            Assert.assertEquals(0xaabbcc, color);
        }
        
        [Test]
        public function testArgb():void
        {
            var color:uint = Color.argb(0xaa, 0xbb, 0xcc, 0xdd);
            Assert.assertEquals(0xaabbccdd, color);
        }
    }
}