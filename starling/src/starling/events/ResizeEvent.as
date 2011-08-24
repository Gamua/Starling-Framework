// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

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