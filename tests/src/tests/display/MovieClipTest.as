// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.flexunit.asserts.assertFalse;
    import org.flexunit.asserts.assertNull;
    import org.flexunit.asserts.assertTrue;
    import org.hamcrest.number.closeTo;

    import starling.display.MovieClip;
    import starling.events.Event;
    import starling.textures.Texture;

    import tests.utils.MockTexture;

    public class MovieClipTest
    {
        private const E:Number = 0.0001;
        
        [Test]
        public function testFrameManipulation():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;

            var texture0:Texture = new MockTexture();
            var texture1:Texture = new MockTexture();
            var texture2:Texture = new MockTexture();
            var texture3:Texture = new MockTexture();
            
            var movie:MovieClip = new MovieClip(new <Texture>[texture0], fps);

            assertThat(movie.width, closeTo(texture0.width, E));
            assertThat(movie.height, closeTo(texture0.height, E));
            assertThat(movie.totalTime, closeTo(frameDuration, E));
            assertEquals(1, movie.numFrames);
            assertEquals(0, movie.currentFrame);

            movie.loop = true;
            assertTrue(movie.loop);

            movie.play();
            assertTrue(movie.isPlaying);
            
            movie.addFrame(texture1);
            assertEquals(2, movie.numFrames);
            assertEquals(texture0, movie.getFrameTexture(0));
            assertEquals(texture1, movie.getFrameTexture(1));
            assertNull(movie.getFrameSound(0));
            assertNull(movie.getFrameSound(1));
            assertThat(movie.getFrameDuration(0), closeTo(frameDuration, E));
            assertThat(movie.getFrameDuration(1), closeTo(frameDuration, E));
            
            movie.addFrame(texture2, null, 0.5);
            assertThat(movie.getFrameDuration(2), closeTo(0.5, E));
            assertThat(movie.totalTime, closeTo(1.0, E));
            
            movie.addFrameAt(2, texture3); // -> 0, 1, 3, 2
            assertEquals(4, movie.numFrames);
            assertEquals(texture1, movie.getFrameTexture(1));
            assertEquals(texture3, movie.getFrameTexture(2));
            assertEquals(texture2, movie.getFrameTexture(3));
            assertThat(movie.totalTime, closeTo(1.0 + frameDuration, E));
            
            movie.removeFrameAt(0); // -> 1, 3, 2
            assertEquals(3, movie.numFrames);
            assertEquals(texture1, movie.getFrameTexture(0));
            assertThat(movie.totalTime, closeTo(1.0, E));
            
            movie.removeFrameAt(1); // -> 1, 2
            assertEquals(2, movie.numFrames);
            assertEquals(texture1, movie.getFrameTexture(0));
            assertEquals(texture2, movie.getFrameTexture(1));
            assertThat(movie.totalTime, closeTo(0.75, E));
            
            movie.setFrameTexture(1, texture3);
            assertEquals(texture3, movie.getFrameTexture(1));
            
            movie.setFrameDuration(1, 0.75);
            assertThat(movie.totalTime, closeTo(1.0, E));
            
            movie.addFrameAt(2, texture3);
            assertEquals(texture3, movie.getFrameTexture(2));
        }
        
        [Test]
        public function testAdvanceTime():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;

            var texture0:Texture = new MockTexture();
            var texture1:Texture = new MockTexture();
            var texture2:Texture = new MockTexture();
            var texture3:Texture = new MockTexture();
            
            var movie:MovieClip = new MovieClip(new <Texture>[texture0], fps);
            movie.addFrame(texture2, null, 0.5);
            movie.addFrame(texture3);
            movie.addFrameAt(0, texture1);
            movie.play();
            movie.loop = true;
            
            assertEquals(0, movie.currentFrame);
            movie.advanceTime(frameDuration / 2.0);
            assertEquals(0, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEquals(1, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEquals(2, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEquals(2, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEquals(3, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEquals(0, movie.currentFrame);
            assertFalse(movie.isComplete);
            
            movie.loop = false;
            movie.advanceTime(movie.totalTime + frameDuration);
            assertEquals(3, movie.currentFrame);
            assertFalse(movie.isPlaying);
            assertTrue(movie.isComplete);
            
            movie.currentFrame = 0;
            assertEquals(0, movie.currentFrame);
            movie.advanceTime(frameDuration * 1.1);
            assertEquals(1, movie.currentFrame);
            
            movie.stop();
            assertFalse(movie.isPlaying);
            assertFalse(movie.isComplete);
            assertEquals(0, movie.currentFrame);
        }
            
        [Test]
        public function testChangeFps():void
        {
            var frames:Vector.<Texture> = createFrames(3);
            var movie:MovieClip = new MovieClip(frames, 4.0);
            
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
        }
        
        [Test]
        public function testCompletedEvent():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;
            var completedCount:int = 0;
            
            var frames:Vector.<Texture> = createFrames(4);
            var movie:MovieClip = new MovieClip(frames, fps);
            movie.addEventListener(Event.COMPLETE, onMovieCompleted);
            movie.loop = false;
            movie.play();
            
            assertFalse(movie.isComplete);
            movie.advanceTime(frameDuration);
            assertEquals(1, movie.currentFrame);
            assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEquals(2, movie.currentFrame);
            assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEquals(3, movie.currentFrame);
            assertEquals(0, completedCount);
            movie.advanceTime(frameDuration * 0.5);
            movie.advanceTime(frameDuration * 0.5);
            assertEquals(3, movie.currentFrame);
            assertEquals(1, completedCount);
            assertTrue(movie.isComplete);
            movie.advanceTime(movie.numFrames * 2 * frameDuration);
            assertEquals(3, movie.currentFrame);
            assertEquals(1, completedCount);
            assertTrue(movie.isComplete);
            
            movie.loop = true;
            completedCount = 0;
            
            assertFalse(movie.isComplete);
            movie.advanceTime(frameDuration);
            assertEquals(1, movie.currentFrame);
            assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEquals(2, movie.currentFrame);
            assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEquals(3, movie.currentFrame);
            assertEquals(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEquals(0, movie.currentFrame);
            assertEquals(1, completedCount);
            movie.advanceTime(movie.numFrames * 2 * frameDuration);
            assertEquals(3, completedCount);
            
            function onMovieCompleted(event:Event):void
            {
                completedCount++;
            }
        }
        
        [Test]
        public function testChangeCurrentFrameInCompletedEvent():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;
            var completedCount:int = 0;
            
            var frames:Vector.<Texture> = createFrames(4);
            var movie:MovieClip = new MovieClip(frames, fps);

            movie.loop = true;
            movie.addEventListener(Event.COMPLETE, onMovieCompleted);
            movie.play();
            movie.advanceTime(1.75);
            
            assertFalse(movie.isPlaying);
            assertEquals(0, movie.currentFrame);

            function onMovieCompleted(event:Event):void
            {
                movie.pause();
                movie.currentFrame = 0;
            }
        }
        
        [Test]
        public function testRemoveAllFrames():void
        {
            var frames:Vector.<Texture> = createFrames(2);
            var movie:MovieClip = new MovieClip(frames);
            
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
            
            assertTrue(throwsError);
        }
        
        [Test]
        public function testLastTextureInFastPlayback():void
        {
            var fps:Number = 20.0;
            var frames:Vector.<Texture> = createFrames(3);
            var movie:MovieClip = new MovieClip(frames, fps);
            movie.addEventListener(Event.COMPLETE, onMovieCompleted);
            movie.play();
            movie.advanceTime(1.0);
            
            function onMovieCompleted():void
            {
                assertEquals(frames[2], movie.texture);
            }
        }
        
        [Test]
        public function testAssignedTextureWithCompleteHandler():void
        {
            // https://github.com/PrimaryFeather/Starling-Framework/issues/232
            
            var frames:Vector.<Texture> = createFrames(2);
            var movie:MovieClip = new MovieClip(frames, 2);
            movie.loop = true;
            movie.play();
            
            movie.addEventListener(Event.COMPLETE, onComplete);
            assertEquals(frames[0], movie.texture);
            
            movie.advanceTime(0.5);
            assertEquals(frames[1], movie.texture);
            
            movie.advanceTime(0.5);
            assertEquals(frames[0], movie.texture);
            
            movie.advanceTime(0.5);
            assertEquals(frames[1], movie.texture);
            
            function onComplete():void { /* does not have to do anything */ }
        }
        
        [Test]
        public function testStopMovieInCompleteHandler():void
        {
            var frames:Vector.<Texture> = createFrames(5);
            var movie:MovieClip = new MovieClip(frames, 5);

            movie.play();
            movie.addEventListener(Event.COMPLETE, onComplete);
            movie.advanceTime(1.3);
            
            assertFalse(movie.isPlaying);
            assertThat(movie.currentTime, closeTo(0.0, E));
            assertEquals(frames[0], movie.texture);
            
            movie.play();
            movie.advanceTime(0.3);
            assertThat(movie.currentTime, closeTo(0.3, E));
            assertEquals(frames[1], movie.texture);
            
            function onComplete():void { movie.stop(); }
        }

        [Test]
        public function testReverseFrames():void
        {
            var i:int;
            var numFrames:int = 4;
            var frames:Vector.<Texture> = createFrames(numFrames);
            var movie:MovieClip = new MovieClip(frames, 5);
            movie.setFrameDuration(0, 0.4);
            movie.play();

            for (i=0; i<numFrames; ++i)
                assertEquals(movie.getFrameTexture(i), frames[i]);

            movie.advanceTime(0.5);
            movie.reverseFrames();

            for (i=0; i<numFrames; ++i)
                assertEquals(movie.getFrameTexture(i), frames[numFrames - i - 1]);

            assertEquals(movie.currentFrame, 2);
            assertThat(movie.currentTime, 0.5);
            assertThat(movie.getFrameDuration(0), closeTo(0.2, E));
            assertThat(movie.getFrameDuration(3), closeTo(0.4, E));
        }

        [Test]
        public function testSetCurrentTime():void
        {
            var actionCount:int = 0;
            var numFrames:int = 4;
            var frames:Vector.<Texture> = createFrames(numFrames);
            var movie:MovieClip = new MovieClip(frames, numFrames);
            movie.setFrameAction(1, onAction);
            movie.play();

            movie.currentTime = 0.1;
            assertEquals(0, movie.currentFrame);
            assertThat(movie.currentTime, closeTo(0.1, E));
            assertEquals(0, actionCount);

            movie.currentTime = 0.25;
            assertEquals(1, movie.currentFrame);
            assertThat(movie.currentTime, closeTo(0.25, E));
            assertEquals(0, actionCount);

            // 'advanceTime' should now get that action executed
            movie.advanceTime(0.01);
            assertEquals(1, actionCount);
            movie.advanceTime(0.01);
            assertEquals(1, actionCount);

            movie.currentTime = 0.3;
            assertEquals(1, movie.currentFrame);
            assertThat(movie.currentTime, closeTo(0.3, E));

            movie.currentTime = 1.0;
            assertEquals(3, movie.currentFrame);
            assertThat(movie.currentTime, closeTo(1.0, E));

            function onAction():void { ++actionCount; }
        }

        [Test]
        public function testBasicFrameActions():void
        {
            var actionCount:int = 0;
            var completeCount:int = 0;

            var numFrames:int = 4;
            var frames:Vector.<Texture> = createFrames(numFrames);
            var movie:MovieClip = new MovieClip(frames, numFrames);
            movie.setFrameAction(1, onFrame);
            movie.setFrameAction(3, onFrame);
            movie.loop = false;
            movie.play();

            // simple test of two actions
            movie.advanceTime(1.0);
            assertEquals(2, actionCount);

            // now pause movie in action
            movie.loop = true;
            movie.setFrameAction(2, pauseMovie);
            movie.advanceTime(1.0);
            assertEquals(3, actionCount);
            assertThat(movie.currentTime, closeTo(0.5, E));
            assertFalse(movie.isPlaying);

            // restarting the clip should execute the action at the current frame
            movie.advanceTime(1.0);
            assertFalse(movie.isPlaying);
            assertEquals(3, actionCount);

            // remove that action
            movie.play();
            movie.setFrameAction(2, null);
            movie.currentFrame = 0;
            movie.advanceTime(1.0);
            assertTrue(movie.isPlaying);
            assertEquals(5, actionCount);

            // add a COMPLETE event handler as well
            movie.addEventListener(Event.COMPLETE, onComplete);
            movie.advanceTime(1.0);
            assertEquals(7, actionCount);
            assertEquals(1, completeCount);

            // frame action should be executed before COMPLETE action, so we can pause the movie
            movie.setFrameAction(3, pauseMovie);
            movie.advanceTime(1.0);
            assertEquals(8, actionCount);
            assertFalse(movie.isPlaying);
            assertEquals(1, completeCount);

            // adding a frame action while we're in the first frame and then moving on -> no action
            movie.currentFrame = 0;
            assertEquals(0, movie.currentFrame);
            movie.setFrameAction(0, onFrame);
            movie.play();
            movie.advanceTime(0.1);
            assertEquals(8, actionCount);
            movie.advanceTime(0.1);
            assertEquals(8, actionCount);

            // but after stopping the clip, the action should be executed
            movie.stop();
            movie.play();
            movie.advanceTime(0.1);
            assertEquals(9, actionCount);
            movie.advanceTime(0.1);
            assertEquals(9, actionCount);

            function onFrame(movieParam:MovieClip, frameID:int):void
            {
                actionCount++;
                assertEquals(movie, movieParam);
                assertEquals(frameID, movie.currentFrame);
                assertThat(movie.currentTime, closeTo(frameID / numFrames, E));
            }

            function pauseMovie():void
            {
                movie.pause();
            }

            function onComplete():void
            {
                assertThat(movie.currentTime, closeTo(movie.totalTime, E));
                completeCount++;
            }
        }

        [Test]
        public function testFloatingPointIssue():void
        {
            // -> https://github.com/Gamua/Starling-Framework/issues/851

            var numFrames:int = 30;
            var completeCount:int = 0;
            var frames:Vector.<Texture> = createFrames(numFrames);
            var movie:MovieClip = new MovieClip(frames, numFrames);

            movie.loop = false;
            movie.addEventListener(Event.COMPLETE, onComplete);
            movie.currentTime = 0.9649999999999999;
            movie.advanceTime(0.03500000000000014);

            assertEquals(1, completeCount);

            function onComplete():void { completeCount++; }
        }
        
        private function createFrames(count:int):Vector.<Texture>
        {
            var frames:Vector.<Texture> = new <Texture>[];

            for (var i:int=0; i<count; ++i)
                frames.push(new MockTexture());
            
            return frames;
        }
    }
}