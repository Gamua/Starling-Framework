package
{
	import starling.core.Starling;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	public class Profiling extends Sprite
	{
		[Embed( source = "/assets/Checker.png" )]
		private var CheckerBMP		:Class;
		private var checkerTexture	:Texture;
		private var shape			:Shape;
		
		public function Profiling()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded ( e:Event ):void
		{
			shape = new Shape(true);
			addChild(shape);
			
			checkerTexture = Texture.fromBitmap( new CheckerBMP(), false );
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private var numFrames:int = 0;
		private function enterFrameHandler( event:Event ):void
		{
			shape.clear();
			
			shape.beginTexturedFill( checkerTexture );
			for ( var i:int = 0; i < 3 * 100; i++ )
			{
				shape.lineTo( Math.random() * Starling.current.nativeStage.stageWidth, Math.random() * Starling.current.nativeStage.stageHeight );
			}
			
			numFrames++;
			if ( numFrames == 500 )
			{
				trace("Finished");
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			}
		}
	}
}