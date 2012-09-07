package
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import starling.core.Starling;
	import starling.display.graphics.Fill;
	import starling.display.materials.StandardMaterial;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	public class FillExample extends Sprite
	{
		[Embed( source = "/assets/Checker.png" )]
		private var CheckerBMP		:Class;
		
		private var currentPoint	:Point;
		private var prevPoint		:Point;
		private var distance		:Number;
		//private var checkerTexture	:Texture;
		private var fill			:Fill;
		
		public function FillExample()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded ( e:Event ):void
		{
			//checkerTexture = Texture.fromBitmap( new CheckerBMP(), false );
			
			fill = new Fill();
			fill.material = new StandardMaterial( new StandardVertexShader(), new TextureVertexColorFragmentShader() );
			fill.material.textures[0] = Texture.fromBitmap( new CheckerBMP(), false );
			addChild(fill);
			
			currentPoint = new Point();
			prevPoint = new Point();
			
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}
		
		private function mouseDownHandler( event:MouseEvent ):void
		{
			currentPoint.x =  Starling.current.nativeStage.mouseX;
			currentPoint.y =  Starling.current.nativeStage.mouseY;
			prevPoint.x = currentPoint.x;
			prevPoint.y = currentPoint.y;
			
			distance = 0;
			
			fill.clear();
			fill.addVertex( currentPoint.x, currentPoint.y );
			
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
		}
		
		private function mouseMoveHandler( event:MouseEvent ):void
		{
			currentPoint.x += (Starling.current.nativeStage.mouseX - currentPoint.x) * 1;
			currentPoint.y += (Starling.current.nativeStage.mouseY - currentPoint.y) * 1;
				
			var dx:Number = currentPoint.x - prevPoint.x;
			var dy:Number = currentPoint.y - prevPoint.y;
			var d:Number = Math.sqrt( dx * dx + dy * dy );
			
			if ( d > 5 )
			{
				distance += d;
				
				prevPoint.x = currentPoint.x;
				prevPoint.y = currentPoint.y;
				
				fill.addVertex( currentPoint.x, currentPoint.y );
			}
		}
		
		private function mouseUpHandler( event:MouseEvent ):void
		{
			Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
		}
	}
}