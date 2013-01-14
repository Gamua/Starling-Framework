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
    import org.flexunit.asserts.assertEquals;
    import org.hamcrest.number.closeTo;
    
    import starling.animation.Juggler;
    import starling.animation.Tween;
    import starling.display.Quad;
    import starling.events.Event;

    public class JugglerTest
    {
        private const E:Number = 0.0001;
        
        [Test]
        public function testModificationWithinCallback():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            var startReached:Boolean = false;
            juggler.add(tween);
            
            tween.onComplete = function():void 
            {
                var otherTween:Tween = new Tween(quad, 1.0);
                otherTween.onStart = function():void 
                { 
                    startReached = true; 
                };
                juggler.add(otherTween);
            };
            
            juggler.advanceTime(0.4); // -> 0.4 (start)
            juggler.advanceTime(0.4); // -> 0.8 (update)
            juggler.advanceTime(0.4); // -> 1.2 (complete)
            juggler.advanceTime(0.4); // -> 1.6 (start of new tween)
            
            Assert.assertTrue(startReached);
        }
        
        [Test]
        public function testContains():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            
            Assert.assertFalse(juggler.contains(tween));
            juggler.add(tween);
            Assert.assertTrue(juggler.contains(tween));
        }
        
        [Test]
        public function testPurge():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            
            var tween1:Tween = new Tween(quad, 1.0);
            var tween2:Tween = new Tween(quad, 2.0);
            
            juggler.add(tween1);
            juggler.add(tween2);
            
            tween1.animate("x", 100);
            tween2.animate("y", 100);
            
            Assert.assertTrue(tween1.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            Assert.assertTrue(tween2.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            
            juggler.purge();
            
            Assert.assertFalse(tween1.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            Assert.assertFalse(tween2.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            
            juggler.advanceTime(10);
            
            Assert.assertEquals(0, quad.x);
            Assert.assertEquals(0, quad.y);
        }
        
        [Test]
        public function testPurgeFromAdvanceTime():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            
            var tween1:Tween = new Tween(quad, 1.0);
            var tween2:Tween = new Tween(quad, 1.0);
            var tween3:Tween = new Tween(quad, 1.0);
            
            juggler.add(tween1);
            juggler.add(tween2);
            juggler.add(tween3);
            
            tween2.onUpdate = juggler.purge;
            
            // if this doesn't crash, we're fine =)
            juggler.advanceTime(0.5);
        }
        
        [Test]
        public function testRemoveTweensWithTarget():void
        {
            var juggler:Juggler = new Juggler();
            
            var quad1:Quad = new Quad(100, 100);
            var quad2:Quad = new Quad(100, 100);
            
            var tween1:Tween = new Tween(quad1, 1.0);
            var tween2:Tween = new Tween(quad2, 1.0);
            
            tween1.animate("rotation", 1.0);
            tween2.animate("rotation", 1.0);
            
            juggler.add(tween1);
            juggler.add(tween2);
            
            juggler.removeTweens(quad1);
            juggler.advanceTime(1.0);
            
            assertThat(quad1.rotation, closeTo(0.0, E));
            assertThat(quad2.rotation, closeTo(1.0, E));   
        }
        
        [Test]
        public function testAddTwice():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            
            juggler.add(tween);
            juggler.add(tween);
            
            assertThat(tween.currentTime, closeTo(0.0, E));
            juggler.advanceTime(0.5);
            assertThat(tween.currentTime, closeTo(0.5, E));
        }
        
        [Test]
        public function testModifyJugglerInCallback():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            
            var tween1:Tween = new Tween(quad, 1.0);
            tween1.animate("x", 100);
            
            var tween2:Tween = new Tween(quad, 0.5);
            tween2.animate("y", 100);
            
            var tween3:Tween = new Tween(quad, 0.5);
            tween3.animate("scaleX", 0.5);
            
            tween2.onComplete = function():void {
                juggler.remove(tween1);
                juggler.add(tween3);
            };
            
            juggler.add(tween1);
            juggler.add(tween2);
            
            juggler.advanceTime(0.5);
            juggler.advanceTime(0.5);
            
            assertThat(quad.x, closeTo(50.0, E));
            assertThat(quad.y, closeTo(100.0, E));
            assertThat(quad.scaleX, closeTo(0.5, E));
        }
        
        [Test]
        public function testModifyJugglerTwiceInCallback():void
        {
            // https://github.com/PrimaryFeather/Starling-Framework/issues/155
            
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            
            var tween1:Tween = new Tween(quad, 1.0);
            var tween2:Tween = new Tween(quad, 1.0);
            tween2.fadeTo(0);
            
            juggler.add(tween1);
            juggler.add(tween2);
            
            juggler.remove(tween1); // sets slot in array to null
            tween2.onUpdate = juggler.remove;
            tween2.onUpdateArgs = [tween2];
            
            juggler.advanceTime(0.5);
            juggler.advanceTime(0.5);
            
            assertThat(quad.alpha, closeTo(0.5, E));
        }
        
        [Test]
        public function testTweenConvenienceMethod():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            
            var completeCount:int = 0;
            var startCount:int = 0;
            
            juggler.tween(quad, 1.0, {
                x: 100,
                onStart: onStart,
                onComplete: onComplete
            });
                
            juggler.advanceTime(0.5);
            assertEquals(1, startCount);
            assertEquals(0, completeCount);
            assertThat(quad.x, closeTo(50, E));
            
            juggler.advanceTime(0.5);
            assertEquals(1, startCount);
            assertEquals(1, completeCount);
            assertThat(quad.x, closeTo(100, E));
                
            function onComplete():void { completeCount++; }
            function onStart():void { startCount++; }
        }
    }
}