package
{
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.display.graphics.Fill;
	import starling.display.graphics.Stroke;
	import starling.display.materials.StandardMaterial;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.events.Event;
	import starling.textures.Texture;
	
	public class GraphicsExample extends Sprite
	{
		[Embed( source = "/assets/Rock2.png" )]
		private var RockBMP			:Class;
		
		[Embed( source = "/assets/Checker.png" )]
		private var CheckerBMP		:Class;
		
		[Embed( source = "/assets/marble_80x80.png" )]
		private var MarbleBMP		:Class;
		
		public function GraphicsExample()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded ( e:Event ):void
		{
			var top:int = 0;
			var left:int = 0;
			var right:int = 100;
			var bottom:int = 100;
			
			var fillColor:uint = 0x08acff;
			var fillAlpha:Number = 1;
			var strokeColor:int = 0xc07732;
			var strokeAlpha:Number = 1;
			var strokeThickness:int = 3;
			
			// Rect drawn with drawRect()
			var shape:Shape = new Shape();
			addChild(shape);
			
			shape.x = 100;
			shape.y = 100;
			
			shape.graphics.beginFill(fillColor, fillAlpha);
			shape.graphics.lineStyle(strokeThickness, strokeColor, strokeAlpha);
			shape.graphics.drawRect(top, left, right, bottom);
			shape.graphics.endFill();
			
			// Rect drawn with lineTo()
			shape = new Shape();
			addChild(shape);
			
			shape.x = 300;
			shape.y = 100;
			
			shape.graphics.beginFill(fillColor, 0.2);
			shape.graphics.lineStyle(5, 0xFF0000, strokeAlpha);
			shape.graphics.moveTo(left, top);
			shape.graphics.lineTo(right, top);
			shape.graphics.lineTo(right, bottom);
			shape.graphics.lineTo(left, bottom);
			shape.graphics.lineTo(left, top);
			
			shape.graphics.endFill();
			
			// Filled Circle
			shape = new Shape();
			addChild(shape);
			
			shape.x = 150;
			shape.y = 300;
			
			shape.graphics.beginFill(fillColor, 0.2);
			shape.graphics.lineStyle(5, 0x00FF00, strokeAlpha);
			shape.graphics.drawCircle(0, 0, 50);
			shape.graphics.endFill();
			
			// Line Ellipse
			shape = new Shape();
			addChild(shape);
			
			shape.x = 350;
			shape.y = 300;
			
			shape.graphics.lineStyle(3, 0x0000FF, strokeAlpha);
			shape.graphics.drawEllipse(0, 0, 75, 50);
			
			// Triangle
			shape = new Shape();
			addChild(shape);
			
			shape.x = 500;
			shape.y = 100;
			
			shape.graphics.beginFill(fillColor, 0.2);
			shape.graphics.lineStyle(2, 0xFF0000, 0.5);
			shape.graphics.moveTo(left, top);
			shape.graphics.lineTo(right, bottom);
			shape.graphics.lineTo(left, bottom);
			shape.graphics.lineTo(left, top);
			
			shape.graphics.endFill();
			
			// Rect drawn with drawRect in Sprite()
			var sprite:Sprite = new Sprite();
			addChild(sprite);
			
			sprite.x = 100;
			sprite.y = 400;
			
			sprite.graphics.beginBitmapFill(new CheckerBMP());
			sprite.graphics.lineStyle(2, 0xFF0000, 0.5);
			sprite.graphics.moveTo(left, top);
			sprite.graphics.lineTo(right, bottom);
			sprite.graphics.lineTo(left, bottom);
			sprite.graphics.lineTo(left, top);
			sprite.graphics.endFill();
			
			// Marble
			sprite = new Sprite();
			addChild(sprite);
			
			sprite.x = 350;
			sprite.y = 450;
			
			var m:Matrix = new Matrix();
			m.translate(-40, -40);
			sprite.graphics.beginBitmapFill(new MarbleBMP(), m, false);
			sprite.graphics.lineStyle(5, 0x00FF00, strokeAlpha);
			sprite.graphics.drawCircle(0, 0, 50);
			sprite.graphics.endFill();		
		}
	}
}














