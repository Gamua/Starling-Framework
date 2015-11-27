// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
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
        private var _frames:Vector.<MovieClipFrame>;
        private var _defaultFrameDuration:Number;
        private var _currentTime:Number;
        private var _currentFrame:int;
        private var _loop:Boolean;
        private var _playing:Boolean;
        private var _muted:Boolean;
        private var _wasStopped:Boolean;
        private var _soundTransform:SoundTransform;

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
            
            _defaultFrameDuration = 1.0 / fps;
            _loop = true;
            _playing = true;
            _currentTime = 0.0;
            _currentFrame = 0;
            _wasStopped = true;
            _frames = new <MovieClipFrame>[];

            for (var i:int=0; i<numFrames; ++i)
                _frames[i] = new MovieClipFrame(
                        textures[i], _defaultFrameDuration, _defaultFrameDuration * i);
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
            if (duration < 0) duration = _defaultFrameDuration;

            var frame:MovieClipFrame = new MovieClipFrame(texture, duration);
            frame.sound = sound;
            _frames.insertAt(frameID, frame);

            if (frameID == numFrames)
            {
                var prevStartTime:Number = frameID > 0 ? _frames[frameID - 1].startTime : 0.0;
                var prevDuration:Number  = frameID > 0 ? _frames[frameID - 1].duration  : 0.0;
                frame.startTime = prevStartTime + prevDuration;
            }
            else
                updateStartTimes();
        }
        
        /** Removes the frame at a certain ID. The successors will move down. */
        public function removeFrameAt(frameID:int):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            if (numFrames == 1) throw new IllegalOperationError("Movie clip must not be empty");

            _frames.removeAt(frameID);

            if (frameID != numFrames)
                updateStartTimes();
        }
        
        /** Returns the texture of a certain frame. */
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return _frames[frameID].texture;
        }
        
        /** Sets the texture of a certain frame. */
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            _frames[frameID].texture = texture;
        }
        
        /** Returns the sound of a certain frame. */
        public function getFrameSound(frameID:int):Sound
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return _frames[frameID].sound;
        }
        
        /** Sets the sound of a certain frame. The sound will be played whenever the frame 
         *  is displayed. */
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            _frames[frameID].sound = sound;
        }
        
        /** Returns the duration of a certain frame (in seconds). */
        public function getFrameDuration(frameID:int):Number
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return _frames[frameID].duration;
        }
        
        /** Sets the duration of a certain frame (in seconds). */
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            _frames[frameID].duration = duration;
            updateStartTimes();
        }

        /** Reverses the order of all frames, making the clip run from end to start.
         *  Makes sure that the currently visible frame stays the same. */
        public function reverseFrames():void
        {
            _frames.reverse();
            _currentTime = totalTime - _currentTime;
            _currentFrame = numFrames - _currentFrame - 1;
            updateStartTimes();
        }
        
        // playback methods
        
        /** Starts playback. Beware that the clip has to be added to a juggler, too! */
        public function play():void
        {
            _playing = true;
        }
        
        /** Pauses playback. */
        public function pause():void
        {
            _playing = false;
        }
        
        /** Stops playback, resetting "currentFrame" to zero. */
        public function stop():void
        {
            _playing = false;
            _wasStopped = true;
            currentFrame = 0;
        }

        // helpers
        
        private function updateStartTimes():void
        {
            var numFrames:int = this.numFrames;
            var prevFrame:MovieClipFrame = _frames[0];
            prevFrame.startTime = 0;
            
            for (var i:int=1; i<numFrames; ++i)
            {
                _frames[i].startTime = prevFrame.startTime + prevFrame.duration;
                prevFrame = _frames[i];
            }
        }

        private function playSound(frame:int):void
        {
            if (!_muted)
            {
                var sound:Sound = _frames[frame].sound;
                if (sound) sound.play(0, 0, _soundTransform);
            }
        }

        // IAnimatable

        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            if (!_playing || passedTime <= 0.0) return;

            var finalFrame:int;
            var previousFrame:int = _currentFrame;
            var restTime:Number = 0.0;
            var dispatchCompleteEvent:Boolean = false;
            var totalTime:Number = this.totalTime;

            if (_wasStopped)
            {
                // if the clip was stopped and started again,
                // we need to play the frame's sound manually.

                _wasStopped = false;
                playSound(_currentFrame);
            }

            if (_loop && _currentTime >= totalTime)
            { 
                _currentTime = 0.0;
                _currentFrame = 0;
            }
            
            if (_currentTime < totalTime)
            {
                _currentTime += passedTime;
                finalFrame = _frames.length - 1;
                
                while (_currentTime > _frames[_currentFrame].startTime +
                                      _frames[_currentFrame].duration)
                {
                    if (_currentFrame == finalFrame)
                    {
                        if (_loop && !hasEventListener(Event.COMPLETE))
                        {
                            _currentTime -= totalTime;
                            _currentFrame = 0;
                        }
                        else
                        {
                            restTime = _currentTime - totalTime;
                            dispatchCompleteEvent = true;
                            _currentFrame = finalFrame;
                            _currentTime = totalTime;
                            break;
                        }
                    }
                    else
                    {
                        _currentFrame++;
                    }

                    if (!_muted && _frames[_currentFrame].sound)
                        playSound(_currentFrame);
                }
                
                // special case when we reach *exactly* the total time.
                if (_currentFrame == finalFrame && _currentTime == totalTime)
                    dispatchCompleteEvent = true;
            }
            
            if (_currentFrame != previousFrame)
                texture = _frames[_currentFrame].texture;
            
            if (dispatchCompleteEvent)
                dispatchEventWith(Event.COMPLETE);
            
            if (_loop && restTime > 0.0)
                advanceTime(restTime);
        }
        
        // properties  
        
        /** The total duration of the clip in seconds. */
        public function get totalTime():Number 
        {
            var lastFrame:MovieClipFrame = _frames[_frames.length-1];
            return lastFrame.startTime + lastFrame.duration;
        }
        
        /** The time that has passed since the clip was started (each loop starts at zero). */
        public function get currentTime():Number { return _currentTime; }
        
        /** The total number of frames. */
        public function get numFrames():int { return _frames.length; }
        
        /** Indicates if the clip should loop. */
        public function get loop():Boolean { return _loop; }
        public function set loop(value:Boolean):void { _loop = value; }
        
        /** If enabled, no new sounds will be started during playback. Sounds that are already
         *  playing are not affected. */
        public function get muted():Boolean { return _muted; }
        public function set muted(value:Boolean):void { _muted = value; }

        /** The SoundTransform object used for playback of all frame sounds. @default null */
        public function get soundTransform():SoundTransform { return _soundTransform; }
        public function set soundTransform(value:SoundTransform):void { _soundTransform = value; }

        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return _currentFrame; }
        public function set currentFrame(value:int):void
        {
            _currentFrame = value;
            _currentTime = 0.0;
            
            for (var i:int=0; i<value; ++i)
                _currentTime += getFrameDuration(i);
            
            texture = _frames[_currentFrame].texture;
            if (_playing && !_wasStopped) playSound(_currentFrame);
        }
        
        /** The default number of frames per second. Individual frames can have different 
         *  durations. If you change the fps, the durations of all frames will be scaled 
         *  relatively to the previous value. */
        public function get fps():Number { return 1.0 / _defaultFrameDuration; }
        public function set fps(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid fps: " + value);
            
            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / _defaultFrameDuration;
            _currentTime *= acceleration;
            _defaultFrameDuration = newFrameDuration;
            
            for (var i:int=0; i<numFrames; ++i)
                _frames[i].duration *= acceleration;

            updateStartTimes();
        }
        
        /** Indicates if the clip is still playing. Returns <code>false</code> when the end 
         *  is reached. */
        public function get isPlaying():Boolean 
        {
            if (_playing)
                return _loop || _currentTime < totalTime;
            else
                return false;
        }

        /** Indicates if a (non-looping) movie has come to its end. */
        public function get isComplete():Boolean
        {
            return !_loop && _currentTime >= totalTime;
        }
    }
}

import flash.media.Sound;
import starling.textures.Texture;

class MovieClipFrame
{
    public function MovieClipFrame(texture:Texture, duration:Number=0.1,  startTime:Number=0)
    {
        this.texture = texture;
        this.duration = duration;
        this.startTime = startTime;
    }

    public var texture:Texture;
    public var sound:Sound;
    public var duration:Number;
    public var startTime:Number;
}