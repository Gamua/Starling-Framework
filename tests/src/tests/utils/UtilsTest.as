// =================================================================================================
//
//  Starling Framework
//  Copyright Gamua GmbH. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import flexunit.framework.Assert;
    
    import starling.utils.HAlign;
    import starling.utils.ScaleMode;
    import starling.utils.VAlign;
    import starling.utils.cleanMasterString;
    import starling.utils.deg2rad;
    import starling.utils.execute;
    import starling.utils.formatString;
    import starling.utils.getNextPowerOfTwo;
    import starling.utils.rad2deg;

    public class UtilsTest
    {
        [Test]
        public function testFormatString():void
        {
            Assert.assertEquals("This is a test.", formatString("This is {0} test.", "a"));            
            Assert.assertEquals("aba{2}", formatString("{0}{1}{0}{2}", "a", "b"));
            Assert.assertEquals("1{2}21", formatString("{0}{2}{1}{0}", 1, 2));
        }

        [Test]
        public function testGetNextPowerOfTwo():void
        {
            Assert.assertEquals(1,   getNextPowerOfTwo(0));
            Assert.assertEquals(1,   getNextPowerOfTwo(1));
            Assert.assertEquals(2,   getNextPowerOfTwo(2));
            Assert.assertEquals(4,   getNextPowerOfTwo(3));
            Assert.assertEquals(4,   getNextPowerOfTwo(4));
            Assert.assertEquals(8,   getNextPowerOfTwo(6));
            Assert.assertEquals(32,  getNextPowerOfTwo(17));
            Assert.assertEquals(64,  getNextPowerOfTwo(63));
            Assert.assertEquals(256, getNextPowerOfTwo(129));
            Assert.assertEquals(256, getNextPowerOfTwo(255));
            Assert.assertEquals(256, getNextPowerOfTwo(256));
        }
        
        [Test]
        public function testRad2Deg():void
        {
            Assert.assertEquals(  0.0, rad2deg(0));
            Assert.assertEquals( 90.0, rad2deg(Math.PI / 2.0));
            Assert.assertEquals(180.0, rad2deg(Math.PI));
            Assert.assertEquals(270.0, rad2deg(Math.PI / 2.0 * 3.0));
            Assert.assertEquals(360.0, rad2deg(2 * Math.PI));
        }
        
        [Test]
        public function testDeg2Rad():void
        {
            Assert.assertEquals(0.0, deg2rad(0));
            Assert.assertEquals(Math.PI / 2.0, deg2rad(90.0));
            Assert.assertEquals(Math.PI, deg2rad(180.0));
            Assert.assertEquals(Math.PI / 2.0 * 3.0, deg2rad(270.0));
            Assert.assertEquals(2 * Math.PI, deg2rad(360.0));
        } 

        [Test]
        public function testExecute():void
        {
            execute(funcOne, "a", "b");
            execute(funcOne, "a", "b", "c");
            execute(funcTwo, "a");

            function funcOne(a:String, b:String):void
            {
                Assert.assertEquals("a", a);
                Assert.assertEquals("b", b);
            }

            function funcTwo(a:String, b:String):void
            {
                Assert.assertEquals("a", a);
                Assert.assertNull(b);
            }
        }
        
        [Test]
        public function testCleanMasterString():void
        {
            Assert.assertEquals("a", cleanMasterString("a"));
        }
        
        [Test]
        public function HAlignValidValue():void
        {
            Assert.assertTrue(HAlign.isValid(HAlign.CENTER));
            Assert.assertTrue(HAlign.isValid(HAlign.LEFT));
            Assert.assertTrue(HAlign.isValid(HAlign.RIGHT));
        }
        
        [Test]
        public function HAlignInvalidValue():void
        {
            Assert.assertFalse(HAlign.isValid("invalid value"));
        }
        
        [Test]
        public function VAlignValidValue():void
        {
            Assert.assertTrue(VAlign.isValid(VAlign.BOTTOM));
            Assert.assertTrue(VAlign.isValid(VAlign.CENTER));
            Assert.assertTrue(VAlign.isValid(VAlign.TOP));
        }
        
        [Test]
        public function VAlignInvalidValue():void
        {
            Assert.assertFalse(VAlign.isValid("invalid value"));
        }
        
        [Test]
        public function scaleModeValidValue():void
        {
            Assert.assertTrue(ScaleMode.isValid(ScaleMode.NO_BORDER));
            Assert.assertTrue(ScaleMode.isValid(ScaleMode.NONE));
            Assert.assertTrue(ScaleMode.isValid(ScaleMode.SHOW_ALL));
        }
        
        [Test]
        public function scaleModeInvalidValue():void
        {
            Assert.assertFalse(ScaleMode.isValid("invalid value"));
        }
    }
}