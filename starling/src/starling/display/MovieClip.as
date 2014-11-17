// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.errors.IllegalOperationError;
    import flash.media.Sound;
    import flash.media.SoundTransform;

    import starling.animation.IAnimatable;
    import starling.events.Event;
    import starling.textures.Texture;
    
    /** Dispatched whenever the movie has displayed its last frame. */
    [Event(name="complete", type="starling.events.Event")]
    
    /** A MovieClip is a simple way to display an animation depicted by a list of textures.
     *  
     *  <p>Pass the frames of the movie in a vector of textures to the constructor. The movie clip 
     *  will have the width and height of the first frame. If you group your frames with the help 
     *  of a texture atlas (which is recommended), use the <code>getTextures</code>-method of the 
     *  atlas to receive the textures in the correct (alphabetic) order.</p> 
     *  
     *  <p>You can specify the desired framerate via the constructor. You can, however, manually 
     *  give each frame a custom duration. You can also play a sound whenever a certain frame 
     *  appears.</p>
     *  
     *  <p>The methods <code>play</code> and <code>pause</code> control playback of the movie. You
     *  will receive an event of type <code>Event.COMPLETE</code> when the movie finished
     *  playback. If the movie is looping, the event is dispatched once per loop.</p>
     *  
     *  <p>As any animated object, a movie clip has to be added to a juggler (or have its 
     *  <code>advanceTime</code> method called regularly) to run. The movie will dispatch 
     *  an event of type "Event.COMPLETE" whenever it has displayed its last frame.</p>
     *  
     *  @see starling.textures.TextureAtlas
     */    
    public class MovieClip extends Image implements IAnimatable
    {
        private var mTextures:Vector.<Texture>;
        private var mSounds:Vector.<Sound>;
        private var mDurations:Vector.<Number>;
        private var mStartTimes:Vector.<Number>;

        private var mDefaultFrameDuration:Number;
        private var mCurrentTime:Number;
        private var mCurrentFrame:int;
        private var mLoop:Boolean;
        private var mPlaying:Boolean;
        private var mMuted:Boolean;
        private var mSoundTransform:SoundTransform = null;
        
        /** Creates a movie clip from the provided textures and with the specified default framerate.
         *  The movie will have the size of the first frame. */  
        public function MovieClip(textures:Vector.<Texture>, fps:Number=12)
        {
            if (textures.length > 0)
            {
                super(textures[0]);
                init(textures, fps);
            }
            else
            {
                throw new ArgumentError("Empty texture array");
            }
        }
        
        private function init(textures:Vector.<Texture>, fps:Number):void
        {
            if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);
            var numFrames:int = textures.length;
            
            mDefaultFrameDuration = 1.0 / fps;
            mLoop = true;
            mPlaying = true;
            mCurrentTime = 0.0;
            mCurrentFrame = 0;
            mTextures = textures.concat();
            mSounds = new Vector.<Sound>(numFrames);
            mDurations = new Vector.<Number>(numFrames);
            mStartTimes = new Vector.<Number>(numFrames);
            
            for (var i:int=0; i<numFrames; ++i)
            {
                mDurations[i] = mDefaultFrameDuration;
                mStartTimes[i] = i * mDefaultFrameDuration;
            }
        }
        
        // frame manipulation
        
        /** Adds an additional frame, optionally with a sound and a custom duration. If the 
         *  duration is omitted, the default framerate is used (as specified in the constructor). */   
        public function addFrame(texture:Texture, sound:Sound=null, duration:Number=-1):void
        {
            addFrameAt(numFrames, texture, sound, duration);
        }
        
        /** Adds a frame at a certain index, optionally with a sound and a custom duration. */
        public function addFrameAt(frameID:int, texture:Texture, sound:Sound=null, 
                                   duration:Number=-1):void
        {
            if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
            if (duration < 0) duration = mDefaultFrameDuration;
            
            mTextures.splice(frameID, 0, texture);
            mSounds.splice(frameID, 0, sound);
            mDurations.splice(frameID, 0, duration);
            
            if (frameID > 0 && frameID == numFrames) 
                mStartTimes[frameID] = mStartTimes[int(frameID-1)] + mDurations[int(frameID-1)];
            else
                updateStartTimes();
        }
        
        /** Removes the frame at a certain ID. The successors will move down. */
        public function removeFrameAt(frameID:int):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            if (numFrames == 1) throw new IllegalOperationError("Movie clip must not be empty");
            
            mTextures.splice(frameID, 1);
            mSounds.splice(frameID, 1);
            mDurations.splice(frameID, 1);
            
            updateStartTimes();
        }
        
        /** Returns the texture of a certain frame. */
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mTextures[frameID];
        }
        
        /** Sets the texture of a certain frame. */
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTextures[frameID] = texture;
        }
        
        /** Returns the sound of a certain frame. */
        public function getFrameSound(frameID:int):Sound
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mSounds[frameID];
        }
        
        /** Sets the sound of a certain frame. The sound will be played whenever the frame 
         *  is displayed. */
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mSounds[frameID] = sound;
        }
        
        /** Returns the duration of a certain frame (in seconds). */
        public function getFrameDuration(frameID:int):Number
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mDurations[frameID];
        }
        
        /** Sets the duration of a certain frame (in seconds). */
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mDurations[frameID] = duration;
            updateStartTimes();
        }
        
        // playback methods
        
        /** Starts playback. Beware that the clip has to be added to a juggler, too! */
        public function play():void
        {
            mPlaying = true;
        }
        
        /** Pauses playback. */
        public function pause():void
        {
            mPlaying = false;
        }
        
        /** Stops playback, resetting "currentFrame" to zero. */
        public function stop():void
        {
            mPlaying = false;
            currentFrame = 0;
        }
        
        // helpers
        
        private function updateStartTimes():void
        {
            var numFrames:int = this.numFrames;
            
            mStartTimes.length = 0;
            mStartTimes[0] = 0;
            
            for (var i:int=1; i<numFrames; ++i)
                mStartTimes[i] = mStartTimes[int(i-1)] + mDurations[int(i-1)];
        }
        
        // IAnimatable
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            if (!mPlaying || passedTime <= 0.0) return;
            
            var finalFrame:int;
            var previousFrame:int = mCurrentFrame;
            var restTime:Number = 0.0;
            var breakAfterFrame:Boolean = false;
            var dispatchCompleteEvent:Boolean = false;
            var totalTime:Number = this.totalTime;
            
            if (mLoop && mCurrentTime >= totalTime)
            { 
                mCurrentTime = 0.0; 
                mCurrentFrame = 0; 
            }
            
            if (mCurrentTime < totalTime)
            {
                mCurrentTime += passedTime;
                finalFrame = mTextures.length - 1;
                
                while (mCurrentTime > mStartTimes[mCurrentFrame] + mDurations[mCurrentFrame])
                {
                    if (mCurrentFrame == finalFrame)
                    {
                        if (mLoop && !hasEventListener(Event.COMPLETE))
                        {
                            mCurrentTime -= totalTime;
                            mCurrentFrame = 0;
                        }
                        else
                        {
                            breakAfterFrame = true;
                            restTime = mCurrentTime - totalTime;
                            dispatchCompleteEvent = true;
                            mCurrentFrame = finalFrame;
                            mCurrentTime = totalTime;
                        }
                    }
                    else
                    {
                        mCurrentFrame++;
                    }
                    
                    var sound:Sound = mSounds[mCurrentFrame];
                    if (sound && !mMuted) sound.play(0, 0, mSoundTransform);
                    if (breakAfterFrame) break;
                }
                
                // special case when we reach *exactly* the total time.
                if (mCurrentFrame == finalFrame && mCurrentTime == totalTime)
                    dispatchCompleteEvent = true;
            }
            
            if (mCurrentFrame != previousFrame)
                texture = mTextures[mCurrentFrame];
            
            if (dispatchCompleteEvent)
                dispatchEventWith(Event.COMPLETE);
            
            if (mLoop && restTime > 0.0)
                advanceTime(restTime);
        }
        
        // properties  
        
        /** The total duration of the clip in seconds. */
        public function get totalTime():Number 
        {
            var numFrames:int = mTextures.length;
            return mStartTimes[int(numFrames-1)] + mDurations[int(numFrames-1)];
        }
        
        /** The time that has passed since the clip was started (each loop starts at zero). */
        public function get currentTime():Number { return mCurrentTime; }
        
        /** The total number of frames. */
        public function get numFrames():int { return mTextures.length; }
        
        /** Indicates if the clip should loop. */
        public function get loop():Boolean { return mLoop; }
        public function set loop(value:Boolean):void { mLoop = value; }
        
        /** If enabled, no new sounds will be started during playback. Sounds that are already
         *  playing are not affected. */
        public function get muted():Boolean { return mMuted; }
        public function set muted(value:Boolean):void { mMuted = value; }

        /** The SoundTransform object used for playback of all frame sounds. @default null */
        public function get soundTransform():SoundTransform { return mSoundTransform; }
        public function set soundTransform(value:SoundTransform):void { mSoundTransform = value; }

        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return mCurrentFrame; }
        public function set currentFrame(value:int):void
        {
            mCurrentFrame = value;
            mCurrentTime = 0.0;
            
            for (var i:int=0; i<value; ++i)
                mCurrentTime += getFrameDuration(i);
            
            texture = mTextures[mCurrentFrame];
            if (!mMuted && mSounds[mCurrentFrame]) mSounds[mCurrentFrame].play();
        }
        
        /** The default number of frames per second. Individual frames can have different 
         *  durations. If you change the fps, the durations of all frames will be scaled 
         *  relatively to the previous value. */
        public function get fps():Number { return 1.0 / mDefaultFrameDuration; }
        public function set fps(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid fps: " + value);
            
            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / mDefaultFrameDuration;
            mCurrentTime *= acceleration;
            mDefaultFrameDuration = newFrameDuration;
            
            for (var i:int=0; i<numFrames; ++i) 
                mDurations[i] *= acceleration;

            updateStartTimes();
        }
        
        /** Indicates if the clip is still playing. Returns <code>false</code> when the end 
         *  is reached. */
        public function get isPlaying():Boolean 
        {
            if (mPlaying)
                return mLoop || mCurrentTime < totalTime;
            else
                return false;
        }

        /** Indicates if a (non-looping) movie has come to its end. */
        public function get isComplete():Boolean
        {
            return !mLoop && mCurrentTime >= totalTime;
        }
    }
}