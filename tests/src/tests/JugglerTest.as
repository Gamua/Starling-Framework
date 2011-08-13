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
    
    import starling.animation.Juggler;
    import starling.animation.Tween;
    import starling.display.Quad;

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
    }
}