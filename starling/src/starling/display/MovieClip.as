package starling.display
{
    import flash.media.Sound;
    
    import starling.animation.IAnimatable;
    import starling.events.Event;
    import starling.textures.Texture;
    
    [Event(name="movieCompleted", type="starling.events.Event")]
    public class MovieClip extends Image implements IAnimatable
    {
        private var mTextures:Vector.<Texture>;
        private var mSounds:Vector.<Sound>;
        private var mDurations:Vector.<Number>;
        
        private var mDefaultFrameDuration:Number;
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mCurrentFrame:int;
        private var mLoop:Boolean;
        private var mPlaying:Boolean;
        
        public function MovieClip(textures:Array, fps:Number=12)
        {            
            if (textures.length > 0)
            {
                super(textures[0]);
                mDefaultFrameDuration = 1.0 / fps;
                mLoop = true;
                mPlaying = true;
                mTotalTime = 0.0;
                mCurrentTime = 0.0;
                mCurrentFrame = 0;
                mTextures = new <Texture>[];
                mSounds = new <Sound>[];
                mDurations = new <Number>[];
                
                for each (var texture:Texture in textures)
                    addFrame(texture);
            }
            else
            {
                throw new ArgumentError("Empty texture array");
            }
        }
        
        // frame manipulation
        
        public function addFrame(texture:Texture, sound:Sound=null, duration:Number=-1):void
        {
            addFrameAt(numFrames, texture, sound, duration);
        }
        
        public function addFrameAt(frameID:int, texture:Texture, sound:Sound=null, 
                                   duration:Number=-1):void
        {
            if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
            if (duration < 0) duration = mDefaultFrameDuration;
            mTextures.splice(frameID, 0, texture);
            mSounds.splice(frameID, 0, sound);
            mDurations.splice(frameID, 0, duration);
            mTotalTime += duration;
        }
        
        public function removeFrameAt(frameID:int):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTotalTime -= getFrameDuration(frameID);
            mTextures.splice(frameID, 1);
            mSounds.splice(frameID, 1);
            mDurations.splice(frameID, 1);
        }
        
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mTextures[frameID];
        }
        
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTextures[frameID] = texture;
        }
        
        public function getFrameSound(frameID:int):Sound
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mSounds[frameID];
        }
        
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mSounds[frameID] = sound;
        }
        
        public function getFrameDuration(frameID:int):Number
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mDurations[frameID];
        }
        
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTotalTime -= getFrameDuration(frameID);
            mTotalTime += duration;
            mDurations[frameID] = duration;
        }
        
        // helper methods
        
        private function updateCurrentFrame():void
        {
            texture = mTextures[mCurrentFrame];
        }
        
        private function playCurrentSound():void
        {
            var sound:Sound = mSounds[mCurrentFrame];
            if (sound) sound.play();
        }
        
        // playback methods
        
        public function play():void
        {
            mPlaying = true;
        }
        
        public function pause():void
        {
            mPlaying = false;
        }
        
        public function stop():void
        {
            mPlaying = false;
            currentFrame = 0;
        }
        
        // IAnimatable
        
        public function advanceTime(passedTime:Number):void
        {
            if (mLoop && mCurrentTime == mTotalTime) mCurrentTime = 0.0;
            if (!mPlaying || passedTime == 0.0 || mCurrentTime == mTotalTime) return;
            
            var i:int = 0;
            var durationSum:Number = 0.0;
            var previousTime:Number = mCurrentTime;
            var restTime:Number = mTotalTime - mCurrentTime;
            var carryOverTime:Number = passedTime > restTime ? passedTime - restTime : 0.0;
            mCurrentTime = Math.min(mTotalTime, mCurrentTime + passedTime);
            
            for each (var duration:Number in mDurations)
            {
                if (durationSum + duration >= mCurrentTime)
                {
                    if (mCurrentFrame != i)
                    {
                        mCurrentFrame = i;
                        updateCurrentFrame();
                        playCurrentSound();
                    }
                    break;
                }
                
                ++i;
                durationSum += duration;
            }
            
            if (previousTime < mTotalTime && mCurrentTime == mTotalTime &&
                hasEventListener(Event.MOVIE_COMPLETED))
            {
                dispatchEvent(new Event(Event.MOVIE_COMPLETED));
            }
                
            advanceTime(carryOverTime);
        }
        
        public function get isComplete():Boolean 
        {
            return false;
        }
        
        // properties  
        
        public function get totalTime():Number { return mTotalTime; }
        public function get numFrames():int { return mTextures.length; }
        
        public function get loop():Boolean { return mLoop; }
        public function set loop(value:Boolean):void { mLoop = value; }
        
        public function get currentFrame():int { return mCurrentFrame; }
        public function set currentFrame(value:int):void
        {
            mCurrentFrame = value;
            mCurrentTime = 0.0;
            
            for (var i:int=0; i<value; ++i)
                mCurrentTime += getFrameDuration(i);
            
            updateCurrentFrame();
        }
        
        public function get fps():Number { return 1.0 / mDefaultFrameDuration; }
        public function set fps(value:Number):void
        {
            var newFrameDuration:Number = value == 0.0 ? Number.MAX_VALUE : 1.0 / value;
            var acceleration:Number = newFrameDuration / mDefaultFrameDuration;
            mCurrentTime *= acceleration;
            mDefaultFrameDuration = newFrameDuration;
            
            for (var i:int=0; i<numFrames; ++i)
                setFrameDuration(i, getFrameDuration(i) * acceleration);
        }
        
        public function get isPlaying():Boolean 
        {
            if (mPlaying)
                return mLoop || mCurrentTime < mTotalTime;
            else
                return false;
        }
    }
}