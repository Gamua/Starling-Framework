package starling.display
{
	import flash.display.Bitmap;
	import flash.geom.Matrix;
	
	import starling.display.graphics.Fill;
	import starling.display.graphics.Stroke;
	import starling.display.materials.StandardMaterial;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.textures.Texture;

	public class Graphics
	{
		private var _currentFillColor	:uint;
		private var _currentFillAlpha	:Number;
		
		private var _strokeThickness	:Number
		private var _strokeColor		:uint;
		private var _strokeAlpha		:Number;
		
		private var _currentStroke				:Stroke;
		private var _currentFill				:Fill;
		private var _currentFillIsBitmapFill	:Boolean;
		
		private var _container			:DisplayObjectContainer;
		
		private var showProfiling		:Boolean;
		
		public function Graphics(displayObjectContainer:DisplayObjectContainer, showProfiling:Boolean = false)
		{
			_container = displayObjectContainer;
			this.showProfiling = showProfiling;
		}
		
		public function clear():void
		{
			while ( _container.numChildren > 0 )
			{
				var child:DisplayObject = _container.getChildAt(0);
				child.dispose();
				_container.removeChildAt(0);
			}
		}
		
		public function beginBitmapFill(bitmap:Bitmap, matrix:Matrix = null, repeat:Boolean = true):void//, smooth:Boolean = false ) 
		{
			_currentFillColor = NaN;
			_currentFillAlpha = NaN;
			_currentFillIsBitmapFill = true;
			
			_currentFill = new Fill(showProfiling);
			_currentFill.material = new StandardMaterial( new StandardVertexShader(), new TextureVertexColorFragmentShader() );
			_currentFill.material.textures[0] = Texture.fromBitmap( bitmap, false );
			
			if ( matrix ) {
				_currentFill.uvMatrix = matrix;
			}
			
			_container.addChild(_currentFill);
		}
		
		public function beginFill(color:uint, alpha:Number = 1.0):void
		{
			_currentFillColor = color;
			_currentFillAlpha = alpha;
			_currentFillIsBitmapFill = false;
			
			_currentFill = new Fill(showProfiling);
			_container.addChild(_currentFill);
		}
		public function endFill():void
		{
			if ( _currentFill && _currentFill.numVertices < 3 ) {
				_container.removeChild(_currentFill);
			}
			
			_currentFillColor 	= NaN;
			_currentFillAlpha 	= NaN;
			_currentFill 		= null;
		}
		
		public function drawCircle(x:Number, y:Number, radius:Number):void
		{
			drawEllipse(x, y, radius, radius);
		}
		
		public function drawEllipse(x:Number, y:Number, width:Number, height:Number):void
		{
			var segmentSize:Number = 2;
			var angle:Number = 270;
			var startAngle:Number = angle;
			
			var xpos:Number = (Math.cos(deg2rad(startAngle)) * width) + x;
			var ypos:Number = (Math.sin(deg2rad(startAngle)) * height) + y;
			moveTo(xpos, ypos);
			
			while (angle - 360 < startAngle) 
			{
				angle += segmentSize;
				
				xpos = (Math.cos(deg2rad(angle)) * width) + x;
				ypos = (Math.sin(deg2rad(angle)) * height) + y;
				
				lineTo(xpos,ypos);
			}
		}
		private function deg2rad (deg:Number):Number {
			return deg * Math.PI / 180;
		}
		
		public function drawRect(x:Number, y:Number, width:Number, height:Number):void
		{
			moveTo(x, y);
			lineTo(x + width, y);
			lineTo(x + width, y + height);
			lineTo(x, y + height);
			lineTo(x, y);
		}
		
		public function lineStyle(thickness:Number = NaN, color:uint = 0, alpha:Number = 1.0):void//, pixelHinting:Boolean = false, scaleMode:String = "normal", caps:String = null, joints:String = null, miterLimit:Number = 3):void
		{
			_strokeThickness	= thickness;
			_strokeColor		= color;
			_strokeAlpha		= alpha;
		}
		
		public function lineTo(x:Number, y:Number):void
		{
			if (!_currentStroke) {
				newStroke();
			}
			
			_currentStroke.addVertex( x, y, _strokeThickness, _strokeColor, _strokeAlpha, _strokeColor );
			
			if (_currentFill) {
				if (_currentFillIsBitmapFill) {
					_currentFill.addVertex(x, y);
				} else {
					_currentFill.addVertex(x, y, _currentFillColor, _currentFillAlpha );
				}
			}
		}
		
		public function moveTo(x:Number, y:Number):void
		{
			newStroke();
			
			_currentStroke.addVertex( x, y, _strokeThickness, _strokeColor, _strokeAlpha, _strokeColor );
			
			if (_currentFill) {
				if (_currentFillIsBitmapFill) {
					_currentFill.addVertex(x, y);
				} else {
					_currentFill.addVertex(x, y, _currentFillColor, _currentFillAlpha );
				}
			}
		}
		
		private function newStroke():void
		{
			if ( _currentStroke && _currentStroke.numVertices < 2 ) {
				_container.removeChild(_currentStroke);
			}
			_currentStroke = new Stroke();
			_container.addChild(_currentStroke);
		}
	}
}