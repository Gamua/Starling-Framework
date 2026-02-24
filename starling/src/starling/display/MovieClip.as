// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
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
    import starling.animation.MovieBehavior;
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
     *  appears, or execute a callback (a "frame action").</p>
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
        private var _textures:Vector.<Texture>;
        private var _behavior:MovieBehavior;

        /** Creates a movie clip from the provided textures and with the specified default framerate.
         *  The movie will have the size of the first frame. */
        public function MovieClip(textures:Vector.<Texture>, fps:Number=12)
        {
            if (textures.length > 0)
            {
                super(textures[0]);
                _textures = textures;
                _behavior = new MovieBehavior(this, onFrameChanged, fps);
                _behavior.numFrames = textures.length;
                _behavior.addEventListener(Event.COMPLETE, onComplete);
            }
            else
            {
                throw new ArgumentError("Empty texture array");
            }
        }

        private function onComplete():void
        {
            dispatchEventWith(Event.COMPLETE);
        }

        private function onFrameChanged(frameIndex:int):void
        {
            texture = _textures[frameIndex];
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
            _behavior.addFrameAt(frameID, sound, duration)
            _textures.insertAt(frameID, texture);
        }

        /** Removes the frame at a certain ID. The successors will move down. */
        public function removeFrameAt(frameID:int):void
        {
            _textures.removeAt(frameID);
            _behavior.removeFrameAt(frameID);
        }

        /** Returns the texture of a certain frame. */
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return _textures[frameID];
        }

        /** Sets the texture of a certain frame. */
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            _textures[frameID] = texture;
        }

        /** Returns the sound of a certain frame. */
        public function getFrameSound(frameID:int):Sound
        {
            return _behavior.getFrameSound(frameID);
        }

        /** Sets the sound of a certain frame. The sound will be played whenever the frame
         *  is displayed. */
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            _behavior.setFrameSound(frameID, sound);
        }

        public function addFrameAction(index:int, action:Function):void
        {
            _behavior.addFrameAction(index, action);
        }

        public function removeFrameAction(index:int, action:Function):void
        {
            _behavior.removeFrameAction(index, action);
        }

        public function removeFrameActions(index:int):void
        {
            _behavior.removeFrameActions();
        }

        public function getFrameActions(frameID:int):Vector.<Function>
        {
            return _behavior.getFrameActions(frameID);
        }

        /** Returns the method that is executed at a certain frame. */
        [Deprecated(since = "2.8.1", replacement = "getFrameActions")]
        public function getFrameAction(frameID:int):Function
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return _behavior.getFrameAt(frameID).actions[0];
        }

        /** Sets an action that will be executed whenever a certain frame is reached.
         *
         * @param frameID   The frame at which the action will be executed.
         * @param action    A callback with two optional parameters:
         *                  <code>function(movie:MovieClip, frameID:int):void;</code>
         */
        [Deprecated(since = "2.8.1", replacement = "addFrameAction")]
        public function setFrameAction(frameID:int, action:Function):void
        {
            _behavior.setFrameActionAt(frameID, 0, action);
        }

        /** Returns the duration of a certain frame (in seconds). */
        public function getFrameDuration(frameID:int):Number
        {
            return _behavior.getFrameDuration(frameID);
        }

        /** Sets the duration of a certain frame (in seconds). */
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            _behavior.setFrameDuration(frameID, duration);
        }

        /** Reverses the order of all frames, making the clip run from end to start.
         *  Makes sure that the currently visible frame stays the same. */
        public function reverseFrames():void
        {
            _textures.reverse();
            _behavior.reverseFrames();
        }

        // playback methods

        /** Starts playback. Beware that the clip has to be added to a juggler, too! */
        public function play():void { _behavior.play(); }

        /** Pauses playback. */
        public function pause():void { _behavior.pause(); }

        /** Stops playback, resetting "currentFrame" to zero. */
        public function stop():void { _behavior.stop(); }

        // IAnimatable

        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void { _behavior.advanceTime(passedTime); }

        // properties

        /** The total number of frames. */
        public function get numFrames():int { return _behavior.numFrames; }

        /** The total duration of the clip in seconds. */
        public function get totalTime():Number { return _behavior.totalTime; }

        /** The time that has passed since the clip was started (each loop starts at zero). */
        public function get currentTime():Number { return _behavior.currentTime; }
        public function set currentTime(value:Number):void { _behavior.currentTime = value; }

        /** Indicates if the clip should loop. @default true */
        public function get loop():Boolean { return _behavior.loop; }
        public function set loop(value:Boolean):void { _behavior.loop = value; }

        /** If enabled, no new sounds will be started during playback. Sounds that are already
         *  playing are not affected. */
        public function get muted():Boolean { return _behavior.muted; }
        public function set muted(value:Boolean):void { _behavior.muted = value; }

        /** The SoundTransform object used for playback of all frame sounds. @default null */
        public function get soundTransform():SoundTransform { return _behavior.soundTransform; }
        public function set soundTransform(value:SoundTransform):void { _behavior.soundTransform = value; }

        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return _behavior.currentFrame; }
        public function set currentFrame(value:int):void { _behavior.currentFrame = value; }

        /** The default number of frames per second. Individual frames can have different
         *  durations. If you change the fps, the durations of all frames will be scaled
         *  relatively to the previous value. */
        public function get fps():Number { return _behavior.frameRate; }
        public function set fps(value:Number):void { _behavior.frameRate = value; }
        public function get frameRate():Number { return _behavior.frameRate; }
        public function set frameRate(value:Number):void { _behavior.frameRate = value; }

        /** Indicates if the clip is still playing. Returns <code>false</code> when the end
         *  is reached. */
        public function get isPlaying():Boolean { return _behavior.isPlaying; }

        /** Indicates if a (non-looping) movie has come to its end. */
        public function get isComplete():Boolean { return _behavior.isComplete; }
    }
}