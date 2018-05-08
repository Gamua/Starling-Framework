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

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;
    import org.hamcrest.number.closeTo;

    import starling.animation.Juggler;
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.display.Quad;
    import starling.utils.deg2rad;

    public class TweenTest
    {
        private const E:Number = 0.0001;
        
        [Test]
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
            assertThat(quad.x, closeTo(startX + (endX-startX)/3.0, E));
            assertThat(quad.y, closeTo(startY + (endY-startY)/3.0, E));
            assertThat(quad.alpha, closeTo(startAlpha + (endAlpha-startAlpha)/3.0, E));
            assertEquals(1, startCount);
            assertEquals(1, updateCount);
            assertEquals(0, completeCount);
            assertFalse(tween.isComplete);
            
            tween.advanceTime(totalTime / 3.0);
            assertThat(quad.x, closeTo(startX + 2*(endX-startX)/3.0, E));
            assertThat(quad.y, closeTo(startY + 2*(endY-startY)/3.0, E));
            assertThat(quad.alpha, closeTo(startAlpha + 2*(endAlpha-startAlpha)/3.0, E));
            assertEquals(1, startCount);
            assertEquals(2, updateCount);
            assertEquals(0, completeCount);
            assertFalse(tween.isComplete);
            
            tween.advanceTime(totalTime / 3.0);
            assertThat(quad.x, closeTo(endX, E));
            assertThat(quad.y, closeTo(endY, E));
            assertThat(quad.alpha, closeTo(endAlpha, E));
            assertEquals(1, startCount);
            assertEquals(3, updateCount);
            assertEquals(1, completeCount);
            assertTrue(tween.isComplete);
        }
        
        [Test]
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
            assertThat(quad.y, closeTo(targetPos, E));
            
            tween2.advanceTime(1.0);
            assertThat(quad.y, closeTo(targetPos, E));
            
            tween2.advanceTime(0.5);
            assertThat(quad.y, closeTo((targetPos - startPos)/2.0, E));
            
            tween2.advanceTime(0.5);
            assertThat(quad.y, closeTo(startPos, E));
        }
        
        [Test]
        public function testTweenFromZero():void
        {
            var quad:Quad = new Quad(100, 100);
            quad.scaleX = 0.0;
            
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("scaleX", 1.0);
            
            tween.advanceTime(0.0);
            assertThat(quad.width, closeTo(0.0, E));
            
            tween.advanceTime(0.5);
            assertThat(quad.width, closeTo(50.0, E));
            
            tween.advanceTime(0.5);
            assertThat(quad.width, closeTo(100.0, E));
        }
        
        [Test]
        public function testResetTween():void
        {
            var quad:Quad = new Quad(100, 100);
            
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("x", 100);
            
            tween.advanceTime(0.5);
            assertThat(quad.x, closeTo(50, E));
            
            tween.reset(this, 1.0);
            tween.advanceTime(0.5);
            
            // tween should no longer change quad.x
            assertThat(quad.x, closeTo(50, E));
        }
        
        [Test]
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
            assertThat(quad.x, closeTo(100, E));
            assertThat(tween.currentTime, closeTo(0, E));
            
            juggler.advanceTime(1.0);
            assertThat(quad.x, closeTo(0, E));
            assertTrue(tween.isComplete);
        }
        
        [Test]
        public function testShortTween():void
        {
            executeTween(0.1, 0.1);
        }
        
        [Test]
        public function testZeroTween():void
        {
            executeTween(0.0, 0.1);
        }
        
        [Test]
        public function testCustomTween():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0, transition);
            tween.animate("x", 100);
            
            tween.advanceTime(0.1);
            assertThat(quad.x, closeTo(10, E));
            
            tween.advanceTime(0.5);
            assertThat(quad.x, closeTo(60, E));
            
            tween.advanceTime(0.4);
            assertThat(quad.x, closeTo(100, E));
            
            assertEquals("custom", tween.transition);
            
            function transition(ratio:Number):Number
            {
                return ratio;
            }
        }
        
        [Test]
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
            assertThat(quad.x, closeTo(50, E));
            assertEquals(tween.repeatCount, 2);
            assertEquals(startCount, 1);
            assertEquals(repeatCount, 1);
            assertEquals(completeCount, 0);
            
            tween.advanceTime(0.75);
            assertThat(quad.x, closeTo(25, E));
            assertEquals(tween.repeatCount, 1);
            assertEquals(startCount, 1);
            assertEquals(repeatCount, 2);
            assertEquals(completeCount, 0);
            assertFalse(tween.isComplete);
            
            tween.advanceTime(1.0);
            assertThat(quad.x, closeTo(100, E));
            assertEquals(tween.repeatCount, 1);
            assertEquals(startCount, 1);
            assertEquals(repeatCount, 2);
            assertEquals(completeCount, 1);
            assertTrue(tween.isComplete);
            
            function onStart():void { startCount++; }
            function onRepeat():void { repeatCount++; }
            function onComplete():void { completeCount++; }
        }
        
        [Test]
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
            assertThat(quad.x, closeTo(75, E));            
            
            tween.advanceTime(0.5);
            assertThat(quad.x, closeTo(75, E));
            
            tween.advanceTime(0.5);
            assertThat(quad.x, closeTo(25, E));
            assertFalse(tween.isComplete);

            tween.advanceTime(1.25);
            assertThat(quad.x, closeTo(100, E));
            assertFalse(tween.isComplete);
            
            tween.advanceTime(10);
            assertThat(quad.x, closeTo(0, E));
            assertTrue(tween.isComplete);
        }
        
        [Test]
        public function testInfiniteTween():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("x", 100);
            tween.repeatCount = 0;
            
            tween.advanceTime(30.5);
            assertThat(quad.x, closeTo(50, E));

            tween.advanceTime(100.5);
            assertThat(quad.x, closeTo(100, E));
            assertFalse(tween.isComplete);
        }
        
        [Test]
        public function testGetEndValue():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("x", 100);
            tween.fadeTo(0);
            tween.scaleTo(1.5);
            
            assertEquals(100, tween.getEndValue("x"));
            assertEquals(0, tween.getEndValue("alpha"));
            assertEquals(1.5, tween.getEndValue("scaleX"));
            assertEquals(1.5, tween.getEndValue("scaleY"));
        }
        
        [Test]
        public function testProgress():void
        {
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0, easeIn);
            assertEquals(0.0, tween.progress);
            
            tween.advanceTime(0.5);
            assertThat(tween.progress, closeTo(easeIn(0.5), E));
            
            tween.advanceTime(0.25);
            assertThat(tween.progress, closeTo(easeIn(0.75), E));
            
            tween.advanceTime(1.0);
            assertThat(tween.progress, closeTo(easeIn(1.0), E));
            
            function easeIn(ratio:Number):Number
            {
                return ratio * ratio * ratio;
            }
        }

        [Test]
        public function testColor():void
        {
            var quad:Quad = new Quad(100, 100, 0xff00ff);
            var tween:Tween = new Tween(quad, 1.0);
            tween.animate("color", 0x00ff00);
            tween.advanceTime(0.5);
            assertEquals(quad.color, 0x7f7f7f);
        }

        [Test]
        public function testRotationRad():void
        {
            var quad:Quad = new Quad(100, 100);
            quad.rotation = deg2rad(-170);

            var tween:Tween = new Tween(quad, 1.0);
            tween.rotateTo(deg2rad(170));
            tween.advanceTime(0.5);

            assertThat(quad.rotation, closeTo(-Math.PI, E));

            tween.advanceTime(0.5);
            assertThat(quad.rotation, closeTo(deg2rad(170), E));
        }

        [Test]
        public function testRotationDeg():void
        {
            var shape:Shape = new Shape();
            shape.rotation = -170;

            var tween:Tween = new Tween(shape, 1.0);
            tween.rotateTo(170, "deg");
            tween.advanceTime(0.5);

            assertThat(shape.rotation, closeTo(-180, E));

            tween.advanceTime(0.5);
            assertThat(shape.rotation, closeTo(170, E));
        }

        [Test]
        public function testAnimatesProperty():void
        {
            var shape:Shape = new Shape();
            var tween:Tween = new Tween(shape, 1.0);
            tween.animate("x", 5.0);
            tween.animate("rotation", 0.5);

            assertTrue(tween.animatesProperty("x"));
            assertTrue(tween.animatesProperty("rotation"));
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
            
            assertEquals(1, updateCount);
            assertEquals(1, startCount);
            assertEquals(advanceTime >= time ? 1 : 0, completeCount);
        }
    }
}