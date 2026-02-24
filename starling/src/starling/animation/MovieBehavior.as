package starling.animation
{
    import starling.animation.IAnimatable;
    import starling.display.DisplayObject;
    import starling.events.Event;
    import starling.events.EventDispatcher;
    import starling.utils.MathUtil;

    /** Encapsulated the logic for time and frame logic for MovieClips and similar classes. */
    internal class MovieBehavior extends EventDispatcher implements IAnimatable
    {
        private var _frames:Vector.<MovieFrame>;
        private var _defaultFrameDuration:Number;
        private var _currentTime:Number;
        private var _currentFrame:int;
        private var _loop:Boolean;
        private var _playing:Boolean;
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

        // frame actions

        public function addFrameAction(index:int, action:Function):void
        {
            getFrameAt(index).addAction(action);
        }

        public function removeFrameAction(index:int, action:Function):void
        {
            getFrameAt(index).removeAction(action);
        }

        public function removeFrameActions(index:int):void
        {
            getFrameAt(index).removeActions();
        }

        private function getFrameAt(index:int):MovieFrame
        {
            if (index < 0 || index >= numFrames) throw new ArgumentError("Invalid frame index");
            return _frames[index];
        }

        // IAnimatable

        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            if (!_playing) return;

            // The tricky part in this method is that whenever a callback is executed
            // (a frame action or a 'COMPLETE' event handler), that callback might modify the movie.
            // Thus, we have to start over with the remaining time whenever that happens.

            var frame:MovieFrame = _frames[_currentFrame];
            var totalTime:Number = this.totalTime;

            if (_wasStopped)
            {
                // if the clip was stopped and started again,
                // actions of this frame need to be repeated.

                _wasStopped = false;

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
            var frameStartTime:Number = _currentFrame * _defaultFrameDuration;
            var dispatchCompleteEvent:Boolean = false;
            var previousFrame:int = _currentFrame;
            var restTimeInFrame:Number;
            var numActions:int;

            while (_currentTime + passedTime >= frameStartTime + _defaultFrameDuration)
            {
                restTimeInFrame = _defaultFrameDuration - _currentTime + frameStartTime;
                passedTime -= restTimeInFrame;
                _currentTime = frameStartTime + _defaultFrameDuration;

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
                        frameStartTime = 0;
                    }
                    else return;
                }
                else
                {
                    _currentFrame += 1;
                    frameStartTime += _defaultFrameDuration;
                }

                frame = _frames[_currentFrame];
                numActions = frame.numActions;

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
                _frames[i] = new MovieFrame();

            _frames.length = value;
        }

        /** The total duration of the clip in seconds. */
        public function get totalTime():Number { return numFrames * _defaultFrameDuration; }

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
            if (value <= 0) throw new ArgumentError("Invalid frame rate");

            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / _defaultFrameDuration;
            _currentTime *= acceleration;
            _defaultFrameDuration = newFrameDuration;
        }

        /** Indicates if the clip should loop. @default true */
        public function get loop():Boolean { return _loop; }
        public function set loop(value:Boolean):void { _loop = value; }

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

import starling.display.DisplayObject;

class MovieFrame
{
    private var _actions:Vector.<Function>;

    public function MovieFrame()
    { }

    public function addAction(action:Function):void
    {
        if (action == null) throw new ArgumentError("action cannot be null");
        if (_actions == null) _actions = new <Function>[];
        if (_actions.indexOf(action) == -1) _actions[_actions.length] = action;
    }

    public function removeAction(action:Function):void
    {
        if (_actions)
        {
            var index:int = _actions.indexOf(action);
            if (index >= 0) _actions.removeAt(index);
        }
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
}