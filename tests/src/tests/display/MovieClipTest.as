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
    import starling.display.MovieClip;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.unit.UnitTest;

    import utils.MockTexture;

    public class MovieClipTest extends UnitTest
    {
        private const E:Number = 0.0001;

        public function testFrameManipulation():void
        {
            var fps:Number = 4.0;
            var frameDuration:Number = 1.0 / fps;

            var texture0:Texture = new MockTexture();
            var texture1:Texture = new MockTexture();
            var texture2:Texture = new MockTexture();
            var texture3:Texture = new MockTexture();

            var movie:MovieClip = new MovieClip(new <Texture>[texture0], fps);

            assertEquivalent(movie.width, texture0.width);
            assertEquivalent(movie.height, texture0.height);
            assertEquivalent(movie.totalTime, frameDuration);
            assertEqual(1, movie.numFrames);
            assertEqual(0, movie.currentFrame);

            movie.loop = true;
            assertTrue(movie.loop);

            movie.play();
            assertTrue(movie.isPlaying);

            movie.addFrame(texture1);
            assertEqual(2, movie.numFrames);
            assertEqual(texture0, movie.getFrameTexture(0));
            assertEqual(texture1, movie.getFrameTexture(1));
            assertNull(movie.getFrameSound(0));
            assertNull(movie.getFrameSound(1));
            assertEquivalent(movie.getFrameDuration(0), frameDuration);
            assertEquivalent(movie.getFrameDuration(1), frameDuration);

            movie.addFrame(texture2, null, 0.5);
            assertEquivalent(movie.getFrameDuration(2), 0.5);
            assertEquivalent(movie.totalTime, 1.0);

            movie.addFrameAt(2, texture3); // -> 0, 1, 3, 2
            assertEqual(4, movie.numFrames);
            assertEqual(texture1, movie.getFrameTexture(1));
            assertEqual(texture3, movie.getFrameTexture(2));
            assertEqual(texture2, movie.getFrameTexture(3));
            assertEquivalent(movie.totalTime, 1.0 + frameDuration);

            movie.removeFrameAt(0); // -> 1, 3, 2
            assertEqual(3, movie.numFrames);
            assertEqual(texture1, movie.getFrameTexture(0));
            assertEquivalent(movie.totalTime, 1.0);

            movie.removeFrameAt(1); // -> 1, 2
            assertEqual(2, movie.numFrames);
            assertEqual(texture1, movie.getFrameTexture(0));
            assertEqual(texture2, movie.getFrameTexture(1));
            assertEquivalent(movie.totalTime, 0.75);

            movie.setFrameTexture(1, texture3);
            assertEqual(texture3, movie.getFrameTexture(1));

            movie.setFrameDuration(1, 0.75);
            assertEquivalent(movie.totalTime, 1.0);

            movie.addFrameAt(2, texture3);
            assertEqual(texture3, movie.getFrameTexture(2));
        }

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

            assertEqual(0, movie.currentFrame);
            movie.advanceTime(frameDuration / 2.0);
            assertEqual(0, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEqual(1, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEqual(2, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEqual(2, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEqual(3, movie.currentFrame);
            movie.advanceTime(frameDuration);
            assertEqual(0, movie.currentFrame);
            assertFalse(movie.isComplete);

            movie.loop = false;
            movie.advanceTime(movie.totalTime + frameDuration);
            assertEqual(3, movie.currentFrame);
            assertFalse(movie.isPlaying);
            assertTrue(movie.isComplete);

            movie.currentFrame = 0;
            assertEqual(0, movie.currentFrame);
            movie.advanceTime(frameDuration * 1.1);
            assertEqual(1, movie.currentFrame);

            movie.stop();
            assertFalse(movie.isPlaying);
            assertFalse(movie.isComplete);
            assertEqual(0, movie.currentFrame);
        }

        public function testChangeFps():void
        {
            var frames:Vector.<Texture> = createFrames(3);
            var movie:MovieClip = new MovieClip(frames, 4.0);

            assertEquivalent(movie.fps, 4.0);

            movie.fps = 3.0;
            assertEquivalent(movie.fps, 3.0);
            assertEquivalent(movie.getFrameDuration(0), 1.0 / 3.0);
            assertEquivalent(movie.getFrameDuration(1), 1.0 / 3.0);
            assertEquivalent(movie.getFrameDuration(2), 1.0 / 3.0);

            movie.setFrameDuration(1, 1.0);
            assertEquivalent(movie.getFrameDuration(1), 1.0);

            movie.fps = 6.0;
            assertEquivalent(movie.getFrameDuration(1), 0.5);
            assertEquivalent(movie.getFrameDuration(0), 1.0 / 6.0);
        }

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
            assertEqual(1, movie.currentFrame);
            assertEqual(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEqual(2, movie.currentFrame);
            assertEqual(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEqual(3, movie.currentFrame);
            assertEqual(0, completedCount);
            movie.advanceTime(frameDuration * 0.5);
            movie.advanceTime(frameDuration * 0.5);
            assertEqual(3, movie.currentFrame);
            assertEqual(1, completedCount);
            assertTrue(movie.isComplete);
            movie.advanceTime(movie.numFrames * 2 * frameDuration);
            assertEqual(3, movie.currentFrame);
            assertEqual(1, completedCount);
            assertTrue(movie.isComplete);

            movie.loop = true;
            completedCount = 0;

            assertFalse(movie.isComplete);
            movie.advanceTime(frameDuration);
            assertEqual(1, movie.currentFrame);
            assertEqual(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEqual(2, movie.currentFrame);
            assertEqual(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEqual(3, movie.currentFrame);
            assertEqual(0, completedCount);
            movie.advanceTime(frameDuration);
            assertEqual(0, movie.currentFrame);
            assertEqual(1, completedCount);
            movie.advanceTime(movie.numFrames * 2 * frameDuration);
            assertEqual(3, completedCount);

            function onMovieCompleted(event:Event):void
            {
                completedCount++;
            }
        }

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
            assertEqual(0, movie.currentFrame);

            function onMovieCompleted(event:Event):void
            {
                movie.pause();
                movie.currentFrame = 0;
            }
        }

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
                assertEqual(frames[2], movie.texture);
            }
        }

        public function testAssignedTextureWithCompleteHandler():void
        {
            // https://github.com/PrimaryFeather/Starling-Framework/issues/232

            var frames:Vector.<Texture> = createFrames(2);
            var movie:MovieClip = new MovieClip(frames, 2);
            movie.loop = true;
            movie.play();

            movie.addEventListener(Event.COMPLETE, onComplete);
            assertEqual(frames[0], movie.texture);

            movie.advanceTime(0.5);
            assertEqual(frames[1], movie.texture);

            movie.advanceTime(0.5);
            assertEqual(frames[0], movie.texture);

            movie.advanceTime(0.5);
            assertEqual(frames[1], movie.texture);

            function onComplete():void { /* does not have to do anything */ }
        }

        public function testStopMovieInCompleteHandler():void
        {
            var frames:Vector.<Texture> = createFrames(5);
            var movie:MovieClip = new MovieClip(frames, 5);

            movie.play();
            movie.addEventListener(Event.COMPLETE, onComplete);
            movie.advanceTime(1.3);

            assertFalse(movie.isPlaying);
            assertEquivalent(movie.currentTime, 0.0);
            assertEqual(frames[0], movie.texture);

            movie.play();
            movie.advanceTime(0.3);
            assertEquivalent(movie.currentTime, 0.3);
            assertEqual(frames[1], movie.texture);

            function onComplete():void { movie.stop(); }
        }

        public function testReverseFrames():void
        {
            var i:int;
            var numFrames:int = 4;
            var frames:Vector.<Texture> = createFrames(numFrames);
            var movie:MovieClip = new MovieClip(frames, 5);
            movie.setFrameDuration(0, 0.4);
            movie.play();

            for (i=0; i<numFrames; ++i)
                assertEqual(movie.getFrameTexture(i), frames[i]);

            movie.advanceTime(0.5);
            movie.reverseFrames();

            for (i=0; i<numFrames; ++i)
                assertEqual(movie.getFrameTexture(i), frames[numFrames - i - 1]);

            assertEqual(movie.currentFrame, 2);
            assertEquivalent(movie.currentTime, 0.5);
            assertEquivalent(movie.getFrameDuration(0), 0.2);
            assertEquivalent(movie.getFrameDuration(3), 0.4);
        }

        public function testSetCurrentTime():void
        {
            var actionCount:int = 0;
            var numFrames:int = 4;
            var frames:Vector.<Texture> = createFrames(numFrames);
            var movie:MovieClip = new MovieClip(frames, numFrames);
            movie.setFrameAction(1, onAction);
            movie.play();

            movie.currentTime = 0.1;
            assertEqual(0, movie.currentFrame);
            assertEquivalent(movie.currentTime, 0.1);
            assertEqual(0, actionCount);

            movie.currentTime = 0.25;
            assertEqual(1, movie.currentFrame);
            assertEquivalent(movie.currentTime, 0.25);
            assertEqual(0, actionCount);

            // 'advanceTime' should now get that action executed
            movie.advanceTime(0.01);
            assertEqual(1, actionCount);
            movie.advanceTime(0.01);
            assertEqual(1, actionCount);

            movie.currentTime = 0.3;
            assertEqual(1, movie.currentFrame);
            assertEquivalent(movie.currentTime, 0.3);

            movie.currentTime = 1.0;
            assertEqual(3, movie.currentFrame);
            assertEquivalent(movie.currentTime, 1.0);

            function onAction():void { ++actionCount; }
        }

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
            assertEqual(2, actionCount);

            // now pause movie in action
            movie.loop = true;
            movie.setFrameAction(2, pauseMovie);
            movie.advanceTime(1.0);
            assertEqual(3, actionCount);
            assertEquivalent(movie.currentTime, 0.5);
            assertFalse(movie.isPlaying);

            // restarting the clip should execute the action at the current frame
            movie.advanceTime(1.0);
            assertFalse(movie.isPlaying);
            assertEqual(3, actionCount);

            // remove that action
            movie.play();
            movie.setFrameAction(2, null);
            movie.currentFrame = 0;
            movie.advanceTime(1.0);
            assertTrue(movie.isPlaying);
            assertEqual(5, actionCount);

            // add a COMPLETE event handler as well
            movie.addEventListener(Event.COMPLETE, onComplete);
            movie.advanceTime(1.0);
            assertEqual(7, actionCount);
            assertEqual(1, completeCount);

            // frame action should be executed before COMPLETE action, so we can pause the movie
            movie.setFrameAction(3, pauseMovie);
            movie.advanceTime(1.0);
            assertEqual(8, actionCount);
            assertFalse(movie.isPlaying);
            assertEqual(1, completeCount);

            // adding a frame action while we're in the first frame and then moving on -> no action
            movie.currentFrame = 0;
            assertEqual(0, movie.currentFrame);
            movie.setFrameAction(0, onFrame);
            movie.play();
            movie.advanceTime(0.1);
            assertEqual(8, actionCount);
            movie.advanceTime(0.1);
            assertEqual(8, actionCount);

            // but after stopping the clip, the action should be executed
            movie.stop();
            movie.play();
            movie.advanceTime(0.1);
            assertEqual(9, actionCount);
            movie.advanceTime(0.1);
            assertEqual(9, actionCount);

            function onFrame(movieParam:MovieClip, frameID:int):void
            {
                actionCount++;
                assertEqual(movie, movieParam);
                assertEqual(frameID, movie.currentFrame);
                assertEquivalent(movie.currentTime, frameID / numFrames);
            }

            function pauseMovie():void
            {
                movie.pause();
            }

            function onComplete():void
            {
                assertEquivalent(movie.currentTime, movie.totalTime);
                completeCount++;
            }
        }

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
            movie.advanceTime(0.1);

            assertEqual(1, completeCount);

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