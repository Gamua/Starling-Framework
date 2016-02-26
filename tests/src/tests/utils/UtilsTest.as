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
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertNull;
    import org.flexunit.asserts.assertTrue;

    import starling.utils.Align;
    import starling.utils.ScaleMode;
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
        public function testAlignIsValid():void
        {
            assertTrue(Align.isValid(Align.CENTER));
            assertTrue(Align.isValid(Align.LEFT));
            assertTrue(Align.isValid(Align.RIGHT));
            assertTrue(Align.isValid(Align.TOP));
            assertTrue(Align.isValid(Align.BOTTOM));
            assertFalse(Align.isValid("invalid value"));
        }
        
        [Test]
        public function testAlignIsValidVertical():void
        {
            assertTrue(Align.isValidVertical(Align.BOTTOM));
            assertTrue(Align.isValidVertical(Align.CENTER));
            assertTrue(Align.isValidVertical(Align.TOP));
            assertFalse(Align.isValidVertical(Align.LEFT));
            assertFalse(Align.isValidVertical(Align.RIGHT));
        }

        [Test]
        public function testAlignIsValidHorizontal():void
        {
            assertTrue(Align.isValidHorizontal(Align.LEFT));
            assertTrue(Align.isValidHorizontal(Align.CENTER));
            assertTrue(Align.isValidHorizontal(Align.RIGHT));
            assertFalse(Align.isValidHorizontal(Align.TOP));
            assertFalse(Align.isValidHorizontal(Align.BOTTOM));
        }
        
        [Test]
        public function testScaleModeIsValid():void
        {
            assertTrue(ScaleMode.isValid(ScaleMode.NO_BORDER));
            assertTrue(ScaleMode.isValid(ScaleMode.NONE));
            assertTrue(ScaleMode.isValid(ScaleMode.SHOW_ALL));
            assertFalse(ScaleMode.isValid("invalid value"));
        }
    }
}