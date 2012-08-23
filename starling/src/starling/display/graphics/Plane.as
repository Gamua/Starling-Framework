package starling.display.graphics
{
	import starling.core.RenderSupport;
	public class Plane extends Graphic
	{
		private var vertices		:Vector.<Number>;
		private var indices			:Vector.<uint>
		private var _width			:Number;
		private var _height			:Number;
		private var _numVerticesX	:uint;
		private var _numVerticesY	:uint;
		
		private var _numTriangles	:int;
		
		public function Plane( width:Number = 1, height:Number = 1, numVerticesX:uint = 2, numVerticesY:uint = 2 )
		{
			_width = width;
			_height = height;
			_numVerticesX = numVerticesX;
			_numVerticesY = numVerticesY;
			validate();
		}
		
		public function validate():void
		{
			vertices = new Vector.<Number>();
			var numVertices:int = _numVerticesX * _numVerticesY;
			var segmentWidth:Number = _width / (_numVerticesX-1);
			var segmentHeight:Number = _height / (_numVerticesY-1);
			var halfWidth:Number = _width * 0.5;
			var halfHeight:Number = _height * 0.5;
			for ( var i:int = 0; i < numVertices; i++ )
			{
				var column:int = i % _numVerticesX;
				var row:int = i / _numVerticesX;
				var u:Number = column / (_numVerticesX-1);
				var v:Number = row / (_numVerticesY-1);
				var x:Number = segmentWidth * column;
				var y:Number = segmentHeight * row;
				vertices.push( x, y, 0, u, v, 1, 1, 1 );
			}
			
			indices = new Vector.<uint>();
			var numQuads:int = (_numVerticesX-1) * (_numVerticesY-1);
			for ( i = 0; i < numQuads; i++ )
			{
				indices.push( i, i+1, i+_numVerticesX+1, i+_numVerticesX+1, i+_numVerticesX, i );
			}
		}
	}
}