package starling.animation
{
    import flash.errors.IllegalOperationError;
    import flash.media.Sound;
    import flash.media.SoundTransform;

    import starling.animation.IAnimatable;
    import starling.display.DisplayObject;
    import starling.events.Event;
    import starling.events.EventDispatcher;
    import starling.utils.MathUtil;

    /** Encapsulated the logic for time and frame logic for MovieClips and similar classes. */
    public class MovieBehavior extends EventDispatcher implements IAnimatable
    {
        private var _frames:Vector.<MovieFrame>;
        private var _defaultFrameDuration:Number;
        private var _currentTime:Number;
        private var _currentFrame:int;
        private var _loop:Boolean;
        private var _playing:Boolean;
        private var _muted:Boolean;
        private var _wasStopped:Boolean;
        private var _target:DisplayObject;
        private var _onFrameChanged:Function;
        private var _soundTransform:SoundTransform;

        private static const E:Number = 0.00001;

        /** Creates a new movie behavior for the given target. Whenever the frame changes,
         *  the callback will be executed. */
        public function MovieBehavior(target:DisplayObject, onFrameChanged:Function,
                                      frameRate:Number=24)
        {
            if (frameRate <= 0) throw new ArgumentError("Invalid frame rate");
            if (target == null) throw new ArgumentError("Target cannot be null");
            if (onFrameChanged == null) throw new ArgumentError("Callback cannot be null");

            _target = target;
            _onFrameChanged = onFrameChanged;
            _defaultFrameDuration = 1.0 / frameRate;
            _frames = new <MovieFrame>[];
            _loop = true;
            _playing = true;
            _currentTime = 0.0;
            _currentFrame = 0;
            _wasStopped = true;
        }

        // frame manipulation

        /** Adds an additional frame, optionally with a sound and a custom duration. If the
         *  duration is omitted, the default framerate is used (as specified in the constructor). */
        public function addFrame(sound:Sound=null, duration:Number=-1):void
        {
            addFrameAt(numFrames, sound, duration);
        }

        /** Adds a frame at a certain index, optionally with a sound and a custom duration. */
        public function addFrameAt(frameID:int, sound:Sound=null,
                                   duration:Number=-1):void
        {
            if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
            if (duration < 0) duration = _defaultFrameDuration;

            var frame:MovieFrame = new MovieFrame(duration);
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

        /** Returns the sound of a certain frame. */
        public function getFrameSound(index:int):Sound
        {
            return getFrameAt(index).sound;
        }

        /** Sets the sound of a certain frame. The sound will be played whenever the frame
         *  is displayed. */
        public function setFrameSound(index:int, sound:Sound):void
        {
            getFrameAt(index).sound = sound;
        }

        // frame actions

        public function addFrameAction(index:int, action:Function):void
        {
            getFrameAt(index).addAction(action);
        }

        public function getFrameActionAt(frame:int, index:int):Function
        {
            return getFrameAt(frame).getActionAt(index);
        }

        public function setFrameActionAt(frame:int, index:int, action:Function):void
        {
            getFrameAt(frame).setActionAt(index, action);
        }

        public function removeFrameAction(index:int, action:Function):void
        {
            getFrameAt(index).removeAction(action);
        }

        public function removeFrameActions(index:int):void
        {
            getFrameAt(index).removeActions();
        }

        public function getFrameActions(frameID:int):Vector.<Function>
        {
            return getFrameAt(frameID).actions;
        }

        /** Returns the duration of a certain frame (in seconds). */
        public function getFrameDuration(frameID:int):Number
        {
            return getFrameAt(frameID).duration;
        }

        /** Sets the duration of a certain frame (in seconds). */
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            getFrameAt(frameID).duration = duration;
            updateStartTimes();
        }

        /** Reverses the order of all frames, making the clip run from end to start.
         *  Makes sure that the currently visible frame stays the same. */
        public function reverseFrames():void
        {
            _frames.reverse();
            updateStartTimes();
            _currentTime = totalTime - _currentTime;
            _currentFrame = numFrames - _currentFrame - 1;
        }

        private function getFrameAt(index:int):MovieFrame
        {
            if (index < 0 || index >= numFrames) throw new ArgumentError("Invalid frame index");
            return _frames[index];
        }

        // helpers

        private function updateStartTimes():void
        {
            var numFrames:int = this.numFrames;
            var prevFrame:MovieFrame = _frames[0];
            prevFrame.startTime = 0;

            for (var i:int=1; i<numFrames; ++i)
            {
                _frames[i].startTime = prevFrame.startTime + prevFrame.duration;
                prevFrame = _frames[i];
            }
        }

        // IAnimatable

        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            if (!_playing) return;

            // The tricky part in this method is that whenever a callback is executed
            // (a frame action or a 'COMPLETE' event handler), that callback might modify the clip.
            // Thus, we have to start over with the remaining time whenever that happens.

            var frame:MovieFrame = _frames[_currentFrame];
            var totalTime:Number = this.totalTime;

            if (_wasStopped)
            {
                // if the clip was stopped and started again,
                // sound and action of this frame need to be repeated.

                _wasStopped = false;
                frame.playSound(_soundTransform);

                if (frame.numActions)
                {
                    frame.executeActions(_target, _currentFrame);
                    advanceTime(passedTime);
                    return;
                }
            }

            if (_currentTime >= totalTime)
            {
                if (_loop)
                {
                    _currentTime = 0.0;
                    _currentFrame = 0;
                    _onFrameChanged(0);
                    frame = _frames[0];
                    frame.playSound(_soundTransform);

                    if (frame.numActions)
                    {
                        frame.executeActions(_target, _currentFrame);
                        advanceTime(passedTime);
                        return;
                    }
                }
                else return;
            }

            var finalFrame:int = _frames.length - 1;
            var dispatchCompleteEvent:Boolean = false;
            var previousFrame:int = _currentFrame;
            var restTimeInFrame:Number;
            var numActions:int;
            var changedFrame:Boolean;

            while (_currentTime + passedTime >= frame.endTime)
            {
                changedFrame = false;
                restTimeInFrame = frame.duration - _currentTime + frame.startTime;
                passedTime -= restTimeInFrame;
                _currentTime = frame.startTime + frame.duration;

                if (_currentFrame == finalFrame)
                {
                    _currentTime = totalTime; // prevent floating point problem

                    if (hasEventListener(Event.COMPLETE))
                    {
                        dispatchCompleteEvent = true;
                    }
                    else if (_loop)
                    {
                        _currentTime = 0;
                        _currentFrame = 0;
                        changedFrame = true;
                    }
                    else return;
                }
                else
                {
                    _currentFrame += 1;
                    changedFrame = true;
                }

                frame = _frames[_currentFrame];
                numActions = frame.numActions;


                if (changedFrame)
                    frame.playSound(_soundTransform);

                if (dispatchCompleteEvent)
                {
                    _onFrameChanged(_currentFrame);
                    dispatchEventWith(Event.COMPLETE);
                    advanceTime(passedTime);
                    return;
                }
                else if (numActions)
                {
                    _onFrameChanged(_currentFrame);
                    frame.executeActions(_target, _currentFrame);
                    advanceTime(passedTime);
                    return;
                }
            }

            if (previousFrame != _currentFrame)
                _onFrameChanged(_currentFrame);

            _currentTime += passedTime;
        }

        // properties

        /** The total number of frames. */
        public function get numFrames():int { return _frames.length; }
        public function set numFrames(value:int):void
        {
            for (var i:int=numFrames; i<value; ++i)
                _frames[i] = new MovieFrame(_defaultFrameDuration, _defaultFrameDuration * i);

            _frames.length = value;
        }

        /** The total duration of the clip in seconds. */
        public function get totalTime():Number
        {
            var lastFrame:MovieFrame = _frames[_frames.length-1];
            return lastFrame.startTime + lastFrame.duration;
        }
        /** The time that has passed since the clip was started (each loop starts at zero). */
        public function get currentTime():Number { return _currentTime; }
        public function set currentTime(value:Number):void
        {
            value = MathUtil.clamp(value, 0, totalTime);

            var prevFrame:int = _currentFrame;
            _currentFrame = value / _defaultFrameDuration;
            _currentTime = value;

            if (prevFrame != _currentFrame)
                _onFrameChanged(_currentFrame);
        }

        public function get frameRate():Number { return 1.0 / _defaultFrameDuration; }
        public function set frameRate(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid frameRate: " + value);

            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / _defaultFrameDuration;
            _currentTime *= acceleration;
            _defaultFrameDuration = newFrameDuration;

            for (var i:int=0; i<numFrames; ++i)
                _frames[i].duration *= acceleration;

            updateStartTimes();
        }

        /** If enabled, no new sounds will be started during playback. Sounds that are already
         *  playing are not affected. */
        public function get muted():Boolean { return _muted; }
        public function set muted(value:Boolean):void { _muted = value; }

        /** Indicates if the clip should loop. @default true */
        public function get loop():Boolean { return _loop; }
        public function set loop(value:Boolean):void { _loop = value; }

        /** The SoundTransform object used for playback of all frame sounds. @default null */
        public function get soundTransform():SoundTransform { return _soundTransform; }
        public function set soundTransform(value:SoundTransform):void { _soundTransform = value; }

        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return _currentFrame; }
        public function set currentFrame(value:int):void
        {
            value = MathUtil.clamp(value, 0, numFrames);

            var prevFrame:int = _currentFrame;
            _currentTime = _defaultFrameDuration * value;
            _currentFrame = value;

            if (prevFrame != _currentFrame)
                _onFrameChanged(_currentFrame);
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
import flash.media.SoundTransform;

import starling.display.DisplayObject;

class MovieFrame
{
    private var _actions:Vector.<Function>;
    public var duration:Number;
    public var startTime:Number;
    public var sound:Sound;

    public function MovieFrame(duration:Number=0.1, startTime:Number=0)
    {
        this._actions = new <Function>[];
        this.duration = duration;
        this.startTime = startTime;
    }

    public function playSound(transform:SoundTransform):void
    {
        if (sound) sound.play(0, 0, transform);
    }

    public function addAction(action:Function):void
    {
        setActionAt(_actions.length, action);
    }

    public function getActionAt(index:int):Function
    {
        return _actions[index];
    }

    public function setActionAt(index:int, action:Function):void
    {
        if (action == null) throw new ArgumentError("action cannot be null");
        if (_actions == null) _actions = new <Function>[];
        if (_actions.length-1 < index) _actions.length = index+1;
        if (_actions.indexOf(action) == -1) _actions[index] = action;
    }

    public function removeAction(action:Function):void
    {
        if (_actions)
        {
            var index:int = _actions.indexOf(action);
            if (index >= 0) _actions.removeAt(index);
        }
    }

    public function get actions():Vector.<Function>
    {
        return _actions;
    }

    public function removeActions():void
    {
        if (_actions) _actions.length = 0;
    }

    public function executeActions(target:DisplayObject, frameID:int):void
    {
        if (_actions)
        {
            for (var i:int=0, len:int=_actions.length; i<len; ++i)
            {
                var action:Function = _actions[i];
                var numArgs:int = action.length;

                if (numArgs == 0) action();
                else if (numArgs == 1) action(target);
                else if (numArgs == 2) action(target, frameID);
                else throw new Error("Frame actions support zero, one or two parameters: " +
                        "movie:MovieClip, frameID:int");
            }
        }
    }

    public function get numActions():int { return _actions ? _actions.length : 0; }

    public function get endTime():Number { return startTime + duration; }
}
