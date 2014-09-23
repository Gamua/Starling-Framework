// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.animation
{
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;
    
    import starling.animation.DelayedCall;
    
    public class DelayedCallTest
    {		
        [Test]
        public function testSimple():void
        {
            var sum:int = 0;
            var dc:DelayedCall = new DelayedCall(raiseSum, 1.0, [5]);
            
            dc.advanceTime(0.5);
            assertEquals(0, sum);
            assertFalse(dc.isComplete);
            
            dc.advanceTime(0.25);
            assertEquals(0, sum);
            assertFalse(dc.isComplete);
            
            dc.advanceTime(0.25);
            assertEquals(5, sum);
            assertTrue(dc.isComplete);
            
            function raiseSum(by:int):void
            {
                sum += by;
            }
        }
        
        [Test]
        public function testRepeated():void
        {
            var sum:int = 0;
            var dc:DelayedCall = new DelayedCall(raiseSum, 1.0, [5]);
            dc.repeatCount = 3;
            
            dc.advanceTime(0.5);
            assertEquals(0, sum);
            assertFalse(dc.isComplete);
            
            dc.advanceTime(1.0);
            assertEquals(5, sum);
            assertFalse(dc.isComplete);
            
            dc.advanceTime(1.0);
            assertEquals(10, sum);
            assertFalse(dc.isComplete);
            
            dc.advanceTime(0.5);
            assertEquals(15, sum);
            assertTrue(dc.isComplete);
            
            dc.advanceTime(20);
            assertEquals(15, sum);
            
            function raiseSum(by:int):void
            {
                sum += by;
            }
        }
        
        [Test]
        public function testIndefinitive():void
        {
            var sum:int = 0;
            var dc:DelayedCall = new DelayedCall(raiseSum, 1.0, [5]);
            dc.repeatCount = 0;
            
            dc.advanceTime(1.5);
            assertEquals(5, sum);
            assertFalse(dc.isComplete);
            
            dc.advanceTime(10.0);
            assertEquals(55, sum);
            assertFalse(dc.isComplete);
            
            function raiseSum(by:int):void
            {
                sum += by;
            }
        }
    }
}