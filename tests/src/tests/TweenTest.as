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
    
    import org.flexunit.assertThat;
    import org.hamcrest.number.closeTo;
    
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.display.Quad;

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
            Assert.assertEquals(1, startCount);
            Assert.assertEquals(1, updateCount);
            Assert.assertEquals(0, completeCount);
            Assert.assertFalse(tween.isComplete);
            
            tween.advanceTime(totalTime / 3.0);
            assertThat(quad.x, closeTo(startX + 2*(endX-startX)/3.0, E));
            assertThat(quad.y, closeTo(startY + 2*(endY-startY)/3.0, E));
            assertThat(quad.alpha, closeTo(startAlpha + 2*(endAlpha-startAlpha)/3.0, E));
            Assert.assertEquals(1, startCount);
            Assert.assertEquals(2, updateCount);
            Assert.assertEquals(0, completeCount);
            Assert.assertFalse(tween.isComplete);
            
            tween.advanceTime(totalTime / 3.0);
            assertThat(quad.x, closeTo(endX, E));
            assertThat(quad.y, closeTo(endY, E));
            assertThat(quad.alpha, closeTo(endAlpha, E));
            Assert.assertEquals(1, startCount);
            Assert.assertEquals(3, updateCount);
            Assert.assertEquals(1, completeCount);
            Assert.assertTrue(tween.isComplete);
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
        public function testShortTween():void
        {
            executeTween(0.1, 0.1);
        }
        
        [Test]
        public function testZeroTween():void
        {
            executeTween(0.0, 0.1);
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
            
            Assert.assertEquals(1, updateCount);
            Assert.assertEquals(1, startCount);
            Assert.assertEquals(advanceTime >= time ? 1 : 0, completeCount);
        }
    }
}