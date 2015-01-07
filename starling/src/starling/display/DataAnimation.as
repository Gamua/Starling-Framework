package starling.display
{
	import flash.media.Sound;
	
	import starling.textures.Texture;

	internal final class DataAnimation
	{
		internal var textures:Vector.<Texture>;
		internal var durations:Vector.<Number>;
		internal var startTimes:Vector.<Number>;
		internal var sounds:Vector.<Sound>; 
		internal var defaultFrameDuration:Number;
		public function DataAnimation(textures:Vector.<Texture>, fps:Number)
		{
			this.textures = textures;
			var numFrames:uint = textures.length;
			
			defaultFrameDuration = 1.0 / fps;
			durations = new Vector.<Number>(numFrames);
			startTimes = new Vector.<Number>(numFrames);
			sounds = new Vector.<Sound>(numFrames);
			
			for (var i:int=0; i < numFrames; ++i)
			{
				durations[i] = defaultFrameDuration;
				startTimes[i] = i * defaultFrameDuration;
			}
			
		}
	}
}