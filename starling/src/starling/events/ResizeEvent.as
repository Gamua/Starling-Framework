package starling.events
{
	public class ResizeEvent extends Event
	{
		public static const RESIZE:String = "resize";
		
		private var mWidth:int;
		private var mHeight:int;
		
		public function ResizeEvent(type:String, width:int, height:int, bubbles:Boolean=false)
		{
			super(type, bubbles);
			mWidth = width;
			mHeight = height;
		}
		
		public function get width():int { return mWidth; }
		public function get height():int { return mHeight; }
	}
}