// =================================================================================================
//
//  Starling Framework
//  Copyright 2011-2015 Gamua. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.utils
{
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertNull;
    import org.flexunit.asserts.assertTrue;

    import starling.utils.HAlign;
    import starling.utils.ScaleMode;
    import starling.utils.VAlign;
    import starling.utils.deg2rad;
    import starling.utils.execute;
    import starling.utils.rad2deg;

    public class UtilsTest
    {
        [Test]
        public function testRad2Deg():void
        {
            assertEquals(  0.0, rad2deg(0));
            assertEquals( 90.0, rad2deg(Math.PI / 2.0));
            assertEquals(180.0, rad2deg(Math.PI));
            assertEquals(270.0, rad2deg(Math.PI / 2.0 * 3.0));
            assertEquals(360.0, rad2deg(2 * Math.PI));
        }
        
        [Test]
        public function testDeg2Rad():void
        {
            assertEquals(0.0, deg2rad(0));
            assertEquals(Math.PI / 2.0, deg2rad(90.0));
            assertEquals(Math.PI, deg2rad(180.0));
            assertEquals(Math.PI / 2.0 * 3.0, deg2rad(270.0));
            assertEquals(2 * Math.PI, deg2rad(360.0));
        } 

        [Test]
        public function testExecute():void
        {
            execute(funcOne, "a", "b");
            execute(funcOne, "a", "b", "c");
            execute(funcTwo, "a");

            function funcOne(a:String, b:String):void
            {
                assertEquals("a", a);
                assertEquals("b", b);
            }

            function funcTwo(a:String, b:String):void
            {
                assertEquals("a", a);
                assertNull(b);
            }
        }
        
        [Test]
        public function testHAlignValidValue():void
        {
            assertTrue(HAlign.isValid(HAlign.CENTER));
            assertTrue(HAlign.isValid(HAlign.LEFT));
            assertTrue(HAlign.isValid(HAlign.RIGHT));
        }
        
        [Test]
        public function testHAlignInvalidValue():void
        {
            assertFalse(HAlign.isValid("invalid value"));
        }
        
        [Test]
        public function testVAlignValidValue():void
        {
            assertTrue(VAlign.isValid(VAlign.BOTTOM));
            assertTrue(VAlign.isValid(VAlign.CENTER));
            assertTrue(VAlign.isValid(VAlign.TOP));
        }
        
        [Test]
        public function testVAlignInvalidValue():void
        {
            assertFalse(VAlign.isValid("invalid value"));
        }
        
        [Test]
        public function testScaleModeValidValue():void
        {
            assertTrue(ScaleMode.isValid(ScaleMode.NO_BORDER));
            assertTrue(ScaleMode.isValid(ScaleMode.NONE));
            assertTrue(ScaleMode.isValid(ScaleMode.SHOW_ALL));
        }
        
        [Test]
        public function testScaleModeInvalidValue():void
        {
            assertFalse(ScaleMode.isValid("invalid value"));
        }
    }
}