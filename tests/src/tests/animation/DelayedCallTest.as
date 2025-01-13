// =================================================================================================
//
//  Starling Framework
//  Copyright Gamua GmbH. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.animation
{
    import starling.animation.DelayedCall;
    import starling.unit.UnitTest;

    public class DelayedCallTest extends UnitTest
    {
        public function testSimple():void
        {
            var sum:int = 0;
            var dc:DelayedCall = new DelayedCall(raiseSum, 1.0, [5]);

            dc.advanceTime(0.5);
            assertEqual(0, sum);
            assertFalse(dc.isComplete);

            dc.advanceTime(0.25);
            assertEqual(0, sum);
            assertFalse(dc.isComplete);

            dc.advanceTime(0.25);
            assertEqual(5, sum);
            assert(dc.isComplete);

            function raiseSum(by:int):void
            {
                sum += by;
            }
        }

        public function testRepeated():void
        {
            var sum:int = 0;
            var dc:DelayedCall = new DelayedCall(raiseSum, 1.0, [5]);
            dc.repeatCount = 3;

            dc.advanceTime(0.5);
            assertEqual(0, sum);
            assertFalse(dc.isComplete);

            dc.advanceTime(1.0);
            assertEqual(5, sum);
            assertFalse(dc.isComplete);

            dc.advanceTime(1.0);
            assertEqual(10, sum);
            assertFalse(dc.isComplete);

            dc.advanceTime(0.5);
            assertEqual(15, sum);
            assert(dc.isComplete);

            dc.advanceTime(20);
            assertEqual(15, sum);

            function raiseSum(by:int):void
            {
                sum += by;
            }
        }

        public function testIndefinitive():void
        {
            var sum:int = 0;
            var dc:DelayedCall = new DelayedCall(raiseSum, 1.0, [5]);
            dc.repeatCount = 0;

            dc.advanceTime(1.5);
            assertEqual(5, sum);
            assertFalse(dc.isComplete);

            dc.advanceTime(10.0);
            assertEqual(55, sum);
            assertFalse(dc.isComplete);

            function raiseSum(by:int):void
            {
                sum += by;
            }
        }

        public function testComplete():void
        {
            var sum:int = 0;
            var dc:DelayedCall = new DelayedCall(raiseSum, 1.0);

            dc.advanceTime(0.5);
            assertEqual(0, sum);

            dc.complete();
            assertEqual(1, sum);
            assert(dc.isComplete);

            dc.complete();
            assertEqual(1, sum);

            dc.advanceTime(10);
            assertEqual(1, sum);

            dc = new DelayedCall(raiseSum, 1.0);
            dc.repeatCount = 3;

            sum = 0;
            dc.complete();
            assertEqual(1, sum);
            assertFalse(dc.isComplete);

            for (var i:int = 0; i < 10; ++i)
                dc.complete();

            assertEqual(3, sum);
            assert(dc.isComplete);

            function raiseSum():void
            {
                sum += 1;
            }
        }
    }
}