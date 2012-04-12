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
    
    import starling.display.MovieClip;
    import starling.events.Event;
    import starling.textures.ConcreteTexture;
    import starling.textures.Texture;

    public class MovieClipTest
    {
        private const E:Number = 0.0001;
        
        [Test]
        public function testFrameManipulation():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;
            
            var texture0:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture1:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture2:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture3:Texture = new ConcreteTexture(null, 16, 16, false, false);
            
            var movie:MovieClip = new MovieClip(new <Texture>[texture0], fps);
            
            assertThat(movie.width, closeTo(texture0.width, E));
            assertThat(movie.height, closeTo(texture0.height, E));
            assertThat(movie.totalTime, closeTo(frameDuration, E));
            Assert.assertEquals(1, movie.numFrames);
            Assert.assertEquals(0, movie.currentFrame);
            Assert.assertEquals(true, movie.loop);
            Assert.assertEquals(true, movie.isPlaying);
            
            movie.pause();
            Assert.assertFalse(movie.isPlaying);
            
            movie.play();
            Assert.assertTrue(movie.isPlaying);
            
            movie.addFrame(texture1);
            Assert.assertEquals(2, movie.numFrames);
            Assert.assertEquals(texture0, movie.getFrameTexture(0));
            Assert.assertEquals(texture1, movie.getFrameTexture(1));
            Assert.assertNull(movie.getFrameSound(0));
            Assert.assertNull(movie.getFrameSound(1));
            assertThat(movie.getFrameDuration(0), closeTo(frameDuration, E));
            assertThat(movie.getFrameDuration(1), closeTo(frameDuration, E));
            
            movie.addFrame(texture2, null, 0.5);
            assertThat(movie.getFrameDuration(2), closeTo(0.5, E));
            assertThat(movie.totalTime, closeTo(1.0, E));
            
            movie.addFrameAt(2, texture3); // -> 0, 1, 3, 2
            Assert.assertEquals(4, movie.numFrames);
            Assert.assertEquals(texture1, movie.getFrameTexture(1));
            Assert.assertEquals(texture3, movie.getFrameTexture(2));
            Assert.assertEquals(texture2, movie.getFrameTexture(3));
            assertThat(movie.totalTime, closeTo(1.0 + frameDuration, E));
            
            movie.removeFrameAt(0); // -> 1, 3, 2
            Assert.assertEquals(3, movie.numFrames);
            Assert.assertEquals(texture1, movie.getFrameTexture(0));
            assertThat(movie.totalTime, closeTo(1.0, E));
            
            movie.removeFrameAt(1); // -> 1, 2
            Assert.assertEquals(2, movie.numFrames);
            Assert.assertEquals(texture1, movie.getFrameTexture(0));
            Assert.assertEquals(texture2, movie.getFrameTexture(1));
            assertThat(movie.totalTime, closeTo(0.75, E));
            
            movie.setFrameTexture(1, texture3);
            Assert.assertEquals(texture3, movie.getFrameTexture(1));
            
            movie.setFrameDuration(1, 0.75);
            assertThat(movie.totalTime, closeTo(1.0, E));
            
            movie.addFrameAt(2, texture3);
            Assert.assertEquals(texture3, movie.getFrameTexture(2));
        }
        
        [Test]
        public function testAdvanceTime():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;
            
            var texture0:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture1:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture2:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture3:Texture = new ConcreteTexture(null, 16, 16, false, false);
            
            var movie:MovieClip = new MovieClip(new <Texture>[texture0], fps);
            movie.addFrame(texture1);
            movie.addFrame(texture2, null, 0.5);
            movie.addFrame(texture3);
            
            Assert.assertEquals(0, movie.currentFrame);
            movie.advanceTime(frameDuration / 2.0);
            Assert.assertEquals(0, movie.currentFrame);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(1, movie.currentFrame);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(2, movie.currentFrame);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(2, movie.currentFrame);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(3, movie.currentFrame);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(0, movie.currentFrame);
            Assert.assertFalse(movie.isComplete);
            
            movie.loop = false;
            movie.advanceTime(movie.totalTime + frameDuration);
            Assert.assertEquals(3, movie.currentFrame);
            Assert.assertFalse(movie.isPlaying);
            Assert.assertTrue(movie.isComplete);
            
            movie.currentFrame = 0;
            Assert.assertEquals(0, movie.currentFrame);
            movie.advanceTime(frameDuration * 1.1);
            Assert.assertEquals(1, movie.currentFrame);
            
            movie.stop();
            Assert.assertFalse(movie.isPlaying);
            Assert.assertFalse(movie.isComplete);
            Assert.assertEquals(0, movie.currentFrame);
        }
            
        [Test]
        public function testChangeFps():void
        {
            var texture0:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture1:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture2:Texture = new ConcreteTexture(null, 16, 16, false, false);
            
            var movie:MovieClip = new MovieClip(new <Texture>[texture0, texture1, texture2], 4.0);
            assertThat(movie.fps, closeTo(4.0, E));
            
            movie.fps = 3.0;
            assertThat(movie.fps, closeTo(3.0, E));
            assertThat(movie.getFrameDuration(0), closeTo(1.0 / 3.0, E));
            assertThat(movie.getFrameDuration(1), closeTo(1.0 / 3.0, E));
            assertThat(movie.getFrameDuration(2), closeTo(1.0 / 3.0, E));
            
            movie.setFrameDuration(1, 1.0);
            assertThat(movie.getFrameDuration(1), closeTo(1.0, E));
            
            movie.fps = 6.0;
            assertThat(movie.getFrameDuration(1), closeTo(0.5, E));
            assertThat(movie.getFrameDuration(0), closeTo(1.0 / 6.0, E));
            
            movie.fps = 0.0;
            assertThat(movie.fps, closeTo(0.0, E));
        }
        
        [Test]
        public function testCompletedEvent():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;
            var completedCount:int = 0;
            
            var texture0:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture1:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture2:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture3:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var textures:Vector.<Texture> = new <Texture>[texture0, texture1, texture2, texture3];
            
            var movie:MovieClip = new MovieClip(textures, fps);
            movie.addEventListener(Event.COMPLETE, onMovieCompleted);
            movie.loop = false;
            
            Assert.assertFalse(movie.isComplete);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(1, completedCount);
            Assert.assertTrue(movie.isComplete);
            movie.advanceTime(movie.numFrames * 2 * frameDuration);
            Assert.assertEquals(1, completedCount);
            Assert.assertTrue(movie.isComplete);
            
            movie.loop = true;
            completedCount = 0;
            
            Assert.assertFalse(movie.isComplete);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            Assert.assertEquals(1, completedCount);
            movie.advanceTime(movie.numFrames * 2 * frameDuration);
            Assert.assertEquals(3, completedCount);
            
            function onMovieCompleted(event:Event):void
            {
                completedCount++;
            }
        }
        
        [Test]
        public function testRemoveAllFrames():void
        {
            var texture0:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var texture1:Texture = new ConcreteTexture(null, 16, 16, false, false);
            var movie:MovieClip = new MovieClip(new <Texture>[texture0, texture1]);
            
            // it must not be allowed to remove the last frame 
            movie.removeFrameAt(0);
            var throwsError:Boolean = false;
            
            try
            {
                movie.removeFrameAt(0);
            }
            catch (error:Error)
            {
                throwsError = true;
            }
            
            Assert.assertTrue(throwsError);
        }
        
    }
}