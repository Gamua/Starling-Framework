package starling.display
{
	import starling.display.graphics.Fill;
	import starling.display.graphics.Stroke;

	public class Graphics
	{
		private var _currentFillColor	:uint;
		private var _currentFillAlpha	:Number;
		
		private var _strokeThickness	:Number
		private var _strokeColor		:uint;
		private var _strokeAlpha		:Number;
		
		private var _currentStroke		:Stroke;
		private var _currentFill		:Fill;
		
		private var _container			:DisplayObjectContainer;
		
		public function Graphics(displayObjectContainer:DisplayObjectContainer)
		{
			_container = displayObjectContainer;
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
		
		public function beginFill(color:uint, alpha:Number = 1.0):void
		{
			_currentFillColor = color;
			_currentFillAlpha = alpha;
			
			_currentFill = new Fill();
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
				_currentFill.addVertex(x, y, _currentFillColor, _currentFillAlpha );
			}
		}
		
		public function moveTo(x:Number, y:Number):void
		{
			newStroke();
			
			_currentStroke.addVertex( x, y, _strokeThickness, _strokeColor, _strokeAlpha, _strokeColor );
			
			if (_currentFill) {
				_currentFill.addVertex(x, y, _currentFillColor, _currentFillAlpha );
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