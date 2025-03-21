// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.animation
{
    import flash.display.Shape;

    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.display.Quad;
    import starling.utils.deg2rad;
    import starling.unit.UnitTest;

    public class TweenTest extends UnitTest
    {
        public function testBasicTween():void
        {
            var startX:Number = 10.0;
            var startY:Number = 20.0;
            var endX:Number = 100.0;
            var endY:Number = 200.0;
            var startAlpha:Number = 1.0;
            var endAlpha:Number = 0.0;
            var totalTime:Number = 2.0;

            var startCount:int = 0;
            var updateCount:int = 0;
            var completeCount:int = 0;

            var quad:Quad = new Quad(100, 100);
            quad.x = startX;
            quad.y = startY;
            quad.alpha = startAlpha;

            var tween:Tween = new Tween(quad, totalTime, Transitions.LINEAR);
            tween.moveTo(endX, endY);
            tween.animate("alpha", endAlpha);
            tween.onStart    = function():void { startCount++; };
            tween.onUpdate   = function():void { updateCount++; };
            tween.onComplete = function():void { completeCount++; };

            tween.advanceTime(totalTime / 3.0);
            assertEquivalent(quad.x, startX + (endX-startX)/3.0);
            assertEquivalent(quad.y, startY + (endY-startY)/3.0);
            assertEquivalent(quad.alpha, startAlpha + (endAlpha-startAlpha)/3.0);
            assertEqual(1, startCount);
            assertEqual(1, updateCount);
            assertEqual(0, completeCount);
            assertFalse(tween.isComplete);

            tween.advanceTime(totalTime / 3.0);
            assertEquivalent(quad.x, startX + 2*(endX-startX)/3.0);
            assertEquivalent(quad.y, startY + 2*(endY-startY)/3.0);
            assertEquivalent(quad.alpha, startAlpha + 2*(endAlpha-startAlpha)/3.0);
            assertEqual(1, startCount);
            assertEqual(2, updateCount);
            assertEqual(0, completeCount);
            assertFalse(tween.isComplete);

            tween.advanceTime(totalTime / 3.0);
            assertEquivalent(quad.x, endX);
            assertEquivalent(quad.y, endY);
            assertEquivalent(quad.alpha, endAlpha);
            assertEqual(1, startCount);
            assertEqual(3, updateCount);
            assertEqual(1, completeCount);
            assert(tween.isComplete);
        }

        public function testSequentialTweens():void
        {
            var startPos:Number  = 0.0;
            var targetPos:Number = 50.0;
            var quad:Quad = new Quad(100, 100);

            // 2 tweens should move object up, then down
            var tween1:Tween = new Tween(quad, 1.0);
            tween1.animate("y", targetPos);

            var tween2:Tween = new Tween(quad, 1.0);
            tween2.animate("y", startPos);
            tween2.delay = tween1.totalTime;

            tween1.advanceTime(1.0);
            assertEquivalent(quad.y, targetPos);

            tween2.advanceTime(1.0);
            assertEquivalent(quad.y, targetPos);

            tween2.advanceTime(0.5);
            assertEquivalent(quad.y, (targetPos - startPos)/2.0);

            tween2.advanceTime(0.5);
            assertEquivalent(quad.y, startPos);
        }

        public function testTweenFromZero():void
        {
            var quad:Quad = new Quad(100, 100);
            quad.scaleX = 0.0;

            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("scaleX", 1.0);

            tween.advanceTime(0.0);
            assertEquivalent(quad.width, 0.0);

            tween.advanceTime(0.5);
            assertEquivalent(quad.width, 50.0);

            tween.advanceTime(0.5);
            assertEquivalent(quad.width, 100.0);
        }

        public function testResetTween():void
        {
            var quad:Quad = new Quad(100, 100);

            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("x", 100);

            tween.advanceTime(0.5);
            assertEquivalent(quad.x, 50);

            tween.reset(this, 1.0);
            tween.advanceTime(0.5);

            // tween should no longer change quad.x
            assertEquivalent(quad.x, 50);
        }

        public function testResetTweenInOnComplete():void
        {
            var quad:Quad = new Quad(100, 100);
            var juggler:Juggler = new Juggler();

            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("x", 100);
            tween.onComplete = function():void
            {
                tween.reset(quad, 1.0);
                tween.animate("x", 0);
                juggler.add(tween);
            };

            juggler.add(tween);

            juggler.advanceTime(1.1);
            assertEquivalent(quad.x, 100);
            assertEquivalent(tween.currentTime, 0);

            juggler.advanceTime(1.0);
            assertEquivalent(quad.x, 0);
            assert(tween.isComplete);
        }

        public function testShortTween():void
        {
            executeTween(0.1, 0.1);
        }

        public function testZeroTween():void
        {
            executeTween(0.0, 0.1);
        }

        public function testCustomTween():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0, transition);
            tween.animate("x", 100);

            tween.advanceTime(0.1);
            assertEquivalent(quad.x, 10);

            tween.advanceTime(0.5);
            assertEquivalent(quad.x, 60);

            tween.advanceTime(0.4);
            assertEquivalent(quad.x, 100);

            assertEqual("custom", tween.transition);

            function transition(ratio:Number):Number
            {
                return ratio;
            }
        }

        public function testRepeatedTween():void
        {
            var startCount:int = 0;
            var repeatCount:int = 0;
            var completeCount:int = 0;

            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            tween.repeatCount = 3;
            tween.onStart = onStart;
            tween.onRepeat = onRepeat;
            tween.onComplete = onComplete;
            tween.animate("x", 100);

            tween.advanceTime(1.5);
            assertEquivalent(quad.x, 50);
            assertEqual(tween.repeatCount, 2);
            assertEqual(startCount, 1);
            assertEqual(repeatCount, 1);
            assertEqual(completeCount, 0);

            tween.advanceTime(0.75);
            assertEquivalent(quad.x, 25);
            assertEqual(tween.repeatCount, 1);
            assertEqual(startCount, 1);
            assertEqual(repeatCount, 2);
            assertEqual(completeCount, 0);
            assertFalse(tween.isComplete);

            tween.advanceTime(1.0);
            assertEquivalent(quad.x, 100);
            assertEqual(tween.repeatCount, 1);
            assertEqual(startCount, 1);
            assertEqual(repeatCount, 2);
            assertEqual(completeCount, 1);
            assert(tween.isComplete);

            function onStart():void { startCount++; }
            function onRepeat():void { repeatCount++; }
            function onComplete():void { completeCount++; }
        }

        public function testReverseTween():void
        {
            var startCount:int = 0;
            var completeCount:int = 0;

            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            tween.repeatCount = 4;
            tween.reverse = true;
            tween.animate("x", 100);

            tween.advanceTime(0.75);
            assertEquivalent(quad.x, 75);

            tween.advanceTime(0.5);
            assertEquivalent(quad.x, 75);

            tween.advanceTime(0.5);
            assertEquivalent(quad.x, 25);
            assertFalse(tween.isComplete);

            tween.advanceTime(1.25);
            assertEquivalent(quad.x, 100);
            assertFalse(tween.isComplete);

            tween.advanceTime(10);
            assertEquivalent(quad.x, 0);
            assert(tween.isComplete);
        }

        public function testInfiniteTween():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("x", 100);
            tween.repeatCount = 0;

            tween.advanceTime(30.5);
            assertEquivalent(quad.x, 50);

            tween.advanceTime(100.5);
            assertEquivalent(quad.x, 100);
            assertFalse(tween.isComplete);
        }

        public function testGetEndValue():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("x", 100);
            tween.fadeTo(0);
            tween.scaleTo(1.5);

            assertEqual(100, tween.getEndValue("x"));
            assertEqual(0, tween.getEndValue("alpha"));
            assertEqual(1.5, tween.getEndValue("scaleX"));
            assertEqual(1.5, tween.getEndValue("scaleY"));
        }

        public function testProgress():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0, easeIn);
            assertEqual(0.0, tween.progress);

            tween.advanceTime(0.5);
            assertEquivalent(tween.progress, easeIn(0.5));

            tween.advanceTime(0.25);
            assertEquivalent(tween.progress, easeIn(0.75));

            tween.advanceTime(1.0);
            assertEquivalent(tween.progress, easeIn(1.0));

            function easeIn(ratio:Number):Number
            {
                return ratio * ratio * ratio;
            }
        }

        public function testColor():void
        {
            var quad:Quad = new Quad(100, 100, 0xff00ff);
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("color", 0x00ff00);
            tween.advanceTime(0.5);
            assertEqual(quad.color, 0x7f7f7f);
        }

        public function testRotationRad():void
        {
            var quad:Quad = new Quad(100, 100);
            quad.rotation = deg2rad(-170);

            var tween:Tween = new Tween(quad, 1.0);
            tween.rotateTo(deg2rad(170));
            tween.advanceTime(0.5);

            assertEquivalent(quad.rotation, -Math.PI);

            tween.advanceTime(0.5);
            assertEquivalent(quad.rotation, deg2rad(170));
        }

        public function testRotationDeg():void
        {
            var shape:Shape = new Shape();
            shape.rotation = -170;

            var tween:Tween = new Tween(shape, 1.0);
            tween.rotateTo(170, "deg");
            tween.advanceTime(0.5);

            assertEquivalent(shape.rotation, -180);

            tween.advanceTime(0.5);
            assertEquivalent(shape.rotation, 170);
        }

        public function testAnimatesProperty():void
        {
            var shape:Shape = new Shape();
            var tween:Tween = new Tween(shape, 1.0);
            tween.animate("x", 5.0);
            tween.animate("rotation", 0.5);

            assert(tween.animatesProperty("x"));
            assert(tween.animatesProperty("rotation"));
            assertFalse(tween.animatesProperty("y"));
            assertFalse(tween.animatesProperty("alpha"));
        }

        private function executeTween(time:Number, advanceTime:Number):void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, time);
            tween.animate("x", 100);

            var startCount:int = 0;
            var updateCount:int = 0;
            var completeCount:int = 0;

            tween.onStart    = function():void { startCount++; };
            tween.onUpdate   = function():void { updateCount++ };
            tween.onComplete = function():void { completeCount++ };

            tween.advanceTime(advanceTime);

            assertEqual(1, updateCount);
            assertEqual(1, startCount);
            assertEqual(advanceTime >= time ? 1 : 0, completeCount);
        }
    }
}