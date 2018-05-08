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
    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertTrue;
    import org.hamcrest.number.closeTo;

    import starling.animation.Juggler;
    import starling.animation.Tween;
    import starling.display.Quad;
    import starling.display.Sprite;
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
            
            assertTrue(startReached);
        }
        
        [Test]
        public function testContains():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad, 1.0);
            
            assertFalse(juggler.contains(tween));
            juggler.add(tween);
            assertTrue(juggler.contains(tween));
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
            
            assertTrue(tween1.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            assertTrue(tween2.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            
            juggler.purge();
            
            assertFalse(tween1.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            assertFalse(tween2.hasEventListener(Event.REMOVE_FROM_JUGGLER));
            
            juggler.advanceTime(10);
            
            assertEquals(0, quad.x);
            assertEquals(0, quad.y);
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
        public function testContainsTweens():void
        {
            var juggler:Juggler = new Juggler();
            var quad1:Quad = new Quad(100, 100);
            var quad2:Quad = new Quad(100, 100);
            var tween:Tween = new Tween(quad1, 1.0);
            
            juggler.add(tween);
            
            assertTrue(juggler.containsTweens(quad1));
            assertFalse(juggler.containsTweens(quad2));
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
        
        [Test]
        public function testDelayedCallConvenienceMethod():void
        {
            var juggler:Juggler = new Juggler();
            var counter:int = 0;
            
            juggler.delayCall(raiseCounter, 1.0);
            juggler.delayCall(raiseCounter, 2.0, 2);
            
            juggler.advanceTime(0.5);
            assertEquals(0, counter);
            
            juggler.advanceTime(1.0);
            assertEquals(1, counter);
            
            juggler.advanceTime(1.0);
            assertEquals(3, counter);
            
            juggler.delayCall(raiseCounter, 1.0, 3);
            
            juggler.advanceTime(1.0);
            assertEquals(6, counter);
            
            function raiseCounter(byValue:int=1):void
            {
                counter += byValue;
            }
        }
        
        [Test]
        public function testRepeatCall():void
        {
            var juggler:Juggler = new Juggler();
            var counter:int = 0;
            
            juggler.repeatCall(raiseCounter, 0.25, 4, 1);
            assertEquals(0, counter);
            
            juggler.advanceTime(0.25);
            assertEquals(1, counter);
            
            juggler.advanceTime(0.5);
            assertEquals(3, counter);
            
            juggler.advanceTime(10);
            assertEquals(4, counter);
            
            function raiseCounter(byValue:int=1):void
            {
                counter += byValue;
            }
        }
        
        [Test]
        public function testEndlessRepeatCall():void
        {
            var juggler:Juggler = new Juggler();
            var counter:int = 0;
            
            var id:uint = juggler.repeatCall(raiseCounter, 1.0);
            assertEquals(0, counter);
            
            juggler.advanceTime(50);
            assertEquals(50, counter);
            
            juggler.removeByID(id);
            
            juggler.advanceTime(50);
            assertEquals(50, counter);
            
            function raiseCounter():void
            {
                counter += 1;
            }
        }

        [Test]
        public function testRemoveByID():void
        {
            var juggler:Juggler = new Juggler();
            var counter:int = 0;
            var id:uint = juggler.delayCall(raiseCounter, 1.0);
            assertTrue(id > 0);

            juggler.advanceTime(0.5);
            var outID:uint = juggler.removeByID(id);
            juggler.advanceTime(1.0);

            assertEquals(outID, id);
            assertEquals(0, counter);

            var quad:Quad = new Quad(100, 100);

            id = juggler.tween(quad, 1.0, { x: 100 });
            assertTrue(id > 0);

            juggler.advanceTime(0.5);
            assertThat(quad.x, closeTo(50, E));

            outID = juggler.removeByID(id);
            assertFalse(juggler.containsTweens(quad));
            assertEquals(id, outID);

            juggler.advanceTime(0.5);
            assertThat(quad.x, closeTo(50, E));

            id = juggler.removeByID(id);
            assertEquals(0, id);

            function raiseCounter():void
            {
                counter += 1;
            }
        }

        [Test]
        public function testRemoveNextTweenByID():void
        {
            var juggler:Juggler = new Juggler();
            var quad:Quad = new Quad(100, 100);

            var tween:Tween = new Tween(quad, 1.0);
            tween.moveTo(1.0, 0.0);

            var tween2:Tween = new Tween(quad, 1.0);
            tween2.moveTo(1.0, 1.0);
            tween.nextTween = tween2;

            var id:uint = juggler.add(tween);
            juggler.advanceTime(1.0);
            juggler.advanceTime(0.5);
            id = juggler.removeByID(id);
            assertFalse(juggler.containsTweens(quad));
            assertTrue(id != 0);

            id = juggler.removeByID(id);
            assertEquals(0, id);

            juggler.advanceTime(0.5);
            assertThat(quad.x, closeTo(1.0, E));
            assertThat(quad.y, closeTo(0.5, E));
        }

        [Test]
        public function testRemoveDelayedCall():void
        {
            var counter:int = 0;
            var juggler:Juggler = new Juggler();

            juggler.repeatCall(raiseCounter, 1.0, 0);
            juggler.advanceTime(3.0);

            assertEquals(3, counter);
            assertTrue(juggler.containsDelayedCalls(raiseCounter));

            juggler.removeDelayedCalls(raiseCounter);
            juggler.advanceTime(10.0);

            assertFalse(juggler.containsDelayedCalls(raiseCounter));
            assertEquals(3, counter);

            function raiseCounter():void
            {
                counter += 1;
            }
        }

        [Test]
        public function testElapsed():void
        {
            var juggler:Juggler = new Juggler();
            assertThat(juggler.elapsedTime, closeTo(0.0, E));
            juggler.advanceTime(0.25);
            juggler.advanceTime(0.5);
            assertThat(juggler.elapsedTime, closeTo(0.75, E));
        }

        [Test]
        public function testTimeScale():void
        {
            var juggler:Juggler = new Juggler();
            var sprite:Sprite = new Sprite();
            var tween:Tween = new Tween(sprite, 1.0);
            tween.animate("x", 100);

            juggler.add(tween);
            juggler.timeScale = 0.5;
            juggler.advanceTime(1.0);

            assertThat(tween.currentTime, closeTo(0.5, E));
            assertThat(sprite.x, closeTo(50, E));

            juggler.timeScale = 2.0;
            juggler.advanceTime(0.25);

            assertThat(tween.currentTime, closeTo(1.0, E));
            assertThat(sprite.x, closeTo(100, E));
        }
    }
}