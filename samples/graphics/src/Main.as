package  
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import starling.core.Starling;
	
	[SWF( width="800", height="600", backgroundColor="#CCCCCC", frameRate="60" )]
	public class Main extends Sprite 
	{
		private var starling	:Starling;
		
		public function Main() 
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
			
			//starling = new Starling( Sandbox, stage );
			starling = new Starling( GraphicsExample, stage );
			//starling = new Starling( FillExample, stage );
			//starling = new Starling( Profiling, stage );
			
			starling.antiAliasing = 1;
			starling.start();
		}
		
	}

}