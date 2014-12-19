package starling.display
{
	import flash.utils.Dictionary;
	
	import starling.textures.Texture;
	
	public class Animation extends MovieClip
	{
		private var animationsDictionary:Dictionary;
		private var nameCurrentAnimation:String;
		
		public function Animation(textures:Vector.<Texture>, nameAnimation:String, fps:Number=30)
		{
			nameCurrentAnimation = nameAnimation;
			animationsDictionary = new Dictionary();
			super(textures[0], fps);
		}
		override internal function init(textures:Vector.<Texture>, fps:Number):void
		{
			if (fps <= 0) throw new ArgumentError("Invalid add animation fps: " + fps);
			var dataAnimation:DataAnimation = new DataAnimation(textures, fps);
			animationsDictionary[nameCurrentAnimation] = dataAnimation;
			switchAnimation(nameCurrentAnimation);
		}
		// frame manipulation
		public function addAnimation(textures:Vector.<Texture>, nameAnimation:String, fps:Number=30, setCurrent:Boolean = false):void
		{
			if (fps <= 0) throw new ArgumentError("Invalid add animation fps: " + fps);
			if (!nameAnimation || nameAnimation.length == 0) throw new ArgumentError("Invalid add animation name: " + nameAnimation);
			
			if (animationsDictionary[nameAnimation]) throw new ArgumentError("animation with name " + nameAnimation + " already exists");
			
			var dataAnimation:DataAnimation = new DataAnimation(textures, fps);
			animationsDictionary[nameAnimation] = dataAnimation;
						
			if(setCurrent)	switchAnimation(nameAnimation);
		}
		public function switchAnimation(nameAnimation:String, play:Boolean = true, loop:Boolean = false):void
		{
			if(!animationsDictionary[nameAnimation]) throw new ArgumentError("Invalid switch animation name: " + nameAnimation);
			if(nameCurrentAnimation == nameAnimation) return;
			
			nameCurrentAnimation = nameAnimation;
			var dataAnimation:DataAnimation = animationsDictionary[nameAnimation];
			
			mTextures = dataAnimation.textures;
			this.texture = mTextures[0];
			mDefaultFrameDuration = dataAnimation.defaultFrameDuration;
			mLoop = loop;
			mPlaying = play;
			mCurrentTime = 0.0;
			mCurrentFrame = 0;
			mSounds = dataAnimation.sounds;
			mDurations = dataAnimation.durations;
			mStartTimes = dataAnimation.startTimes;
			
			//readjustSize();
		}
		public function removeAnimation(nameAnimation:String):void
		{
			if (!nameAnimation || nameAnimation.length == 0) throw new ArgumentError("Invalid remove animation name: " + nameAnimation);
			if (nameAnimation == nameCurrentAnimation) throw new ArgumentError("You can not delete current animation named: " + nameAnimation);
			
			if (animationsDictionary[nameAnimation])
				delete animationsDictionary[nameAnimation];
			
		}
	}
}