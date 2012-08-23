package starling.display.graphics
{
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.textures.Texture;
	
	public class Stroke extends Graphic
	{
		public static const VERTEX_STRIDE	:int = 9;
		
		protected var vertices	:Vector.<StrokeVertex>;
		protected var _closed 	:Boolean = false;
		
		public function Stroke()
		{
			vertices = new Vector.<StrokeVertex>();
		}
		
		public function addVertex( 	x:Number, y:Number, thickness:Number = 1,
									color0:uint = 0xFFFFFF,  alpha0:Number = 1,
									color1:uint = 0xFFFFFF, alpha1:Number = 1 ):void
		{
			if ( vertexBuffer )
			{
				vertexBuffer.dispose();
				vertexBuffer = null;
			}
			
			if ( indexBuffer )
			{
				indexBuffer.dispose();
				indexBuffer = null;
			}
			
			var u:Number = 0;
			var textures:Vector.<Texture> = _material.textures;
			if ( vertices.length > 0 && textures.length > 0 )
			{
				var prevVertex:StrokeVertex = vertices[vertices.length - 1];
				var dx:Number = x - prevVertex.x;
				var dy:Number = y - prevVertex.y;
				var d:Number = Math.sqrt(dx*dx+dy*dy);
				u = prevVertex.u + (d / textures[0].width);
			}
			
			var r0:Number = (color0 >> 16) / 255;
			var g0:Number = ((color0 & 0x00FF00) >> 8) / 255;
			var b0:Number = (color0 & 0x0000FF) / 255;
			var r1:Number = (color1 >> 16) / 255;
			var g1:Number = ((color1 & 0x00FF00) >> 8) / 255;
			var b1:Number = (color1 & 0x0000FF) / 255;
			
			vertices.push( new StrokeVertex( x, y, 0, r0, g0, b0, alpha0, r1, g1, b1, alpha1, u, 0, thickness ) );
		}
		
		override public function render( renderSupport:RenderSupport, alpha:Number ):void
		{
			if ( vertices.length < 2 ) return;
			
			if ( vertexBuffer == null )
			{
				var indices:Vector.<uint> = new Vector.<uint>();
				var renderVertices:Vector.<Number> = new Vector.<Number>();
				
				createPolyLine(vertices, _closed, renderVertices, indices );
				
				if ( indices.length < 3 ) return;
				vertexBuffer = Starling.context.createVertexBuffer( renderVertices.length / VERTEX_STRIDE, VERTEX_STRIDE );
				vertexBuffer.uploadFromVector( renderVertices, 0, renderVertices.length / VERTEX_STRIDE )
				indexBuffer = Starling.context.createIndexBuffer( indices.length );
				indexBuffer.uploadFromVector( indices, 0, indices.length );
			}
			
			super.render( renderSupport, alpha );
		}
		
		private static function createPolyLine( vertices:Vector.<StrokeVertex>, closed:Boolean, outputVertices:Vector.<Number>, outputIndices:Vector.<uint> ):void
		{
			var numVertices:int = vertices.length;
			for ( var i:int = 0; i < numVertices; i++ )
			{
				var v1:StrokeVertex = vertices[i];
				var v0:StrokeVertex = i > 0 ? vertices[i - 1] : StrokeVertex(v1.clone());
				var v2:StrokeVertex = i < numVertices-1 ? vertices[i + 1] : StrokeVertex(v1.clone());
				
				var d0x:Number = v1.x - v0.x;
				var d0y:Number = v1.y - v0.y;
				var d1x:Number = v2.x - v1.x;
				var d1y:Number = v2.y - v1.y;
				
				if ( i == numVertices - 1 )
				{
					v2.x += d0x;
					v2.y += d0y;
					
					d1x = v2.x - v1.x;
					d1y = v2.y - v1.y;
				}
				
				if ( i == 0 )
				{
					v0.x -= d1x;
					v0.y -= d1y;
					
					d0x = v1.x - v0.x;
					d0y = v1.y - v0.y;
				}
				
				var n0x:Number = -d0y
				var n0y:Number =  d0x;
				var n0m:Number = Math.sqrt(n0x * n0x + n0y * n0y);
				n0x /= n0m;
				n0y /= n0m;
				
				var n1x:Number = -d1y
				var n1y:Number =  d1x;
				var n1m:Number = Math.sqrt(n1x * n1x + n1y * n1y);
				n1x /= n1m;
				n1y /= n1m;
				
				
				
				var p0x:Number = v1.x + n0x * v1.thickness * 0.5;
				var p0y:Number = v1.y + n0y * v1.thickness * 0.5;
				var p2x:Number = v1.x + n1x * v1.thickness * 0.5;
				var p2y:Number = v1.y + n1y * v1.thickness * 0.5;
				
				var i0:Array = intersection(p0x, p0y, p0x +d0x, p0y + d0y, p2x, p2y, p2x + d1x, p2y + d1y );
				
				var p1x:Number = v1.x - n0x * v1.thickness * 0.5;
				var p1y:Number = v1.y - n0y * v1.thickness * 0.5;
				var p3x:Number = v1.x - n1x * v1.thickness * 0.5;
				var p3y:Number = v1.y - n1y * v1.thickness * 0.5;
				
				var i1:Array = intersection(p1x, p1y, p1x +d0x, p1y + d0y, p3x, p3y, p3x + d1x, p3y + d1y );
				
				outputVertices.push(i0[0], i0[1], v1.z, v1.r2, v1.g2, v1.b2, v1.a2, v1.u, 1 );
				outputVertices.push(i1[0], i1[1], v1.z, v1.r, v1.g, v1.b, v1.a, v1.u, 0 );
				
				if ( i < numVertices - 1 )
				{
					var i2:Number = i * 2;
					outputIndices.push(i2, i2 + 2, i2 + 1, i2 + 1, i2 + 2, i2 + 3);
				}
			}
		}
		
		private static const EPSILON:Number = 0.0000001
		static public function intersection( a0x:Number, a0y:Number, a1x:Number, a1y:Number, b0x:Number, b0y:Number, b1x:Number, b1y:Number ):Array
		{
			var ux:Number = a1x - a0x;
			var uy:Number = a1y - a0y;
			
			var vx:Number = b1x - b0x;
			var vy:Number = b1y - b0y;
			
			var wx:Number = a0x - b0x;
			var wy:Number = a0y - b0y;
			
			var D:Number = ux * vy - uy * vx
			if (Math.abs(D) < EPSILON) return [a0x, a0y];
			var t:Number = (vx * wy - vy * wx) / D
			return [ a0x + t * (a1x - a0x), a0y + t * (a1y - a0y) ];
		}
		
		public function get closed():Boolean {
			return _closed;
		}
		public function set closed(value:Boolean):void {
			_closed = value;
		}
		
		public function get numVertices():int
		{
			return vertices.length;
		}
	}
}

internal class StrokeVertex
{
	public var x	:Number;
	public var y	:Number;
	public var z	:Number;
	public var r	:Number;
	public var g	:Number;
	public var b	:Number;
	public var a	:Number;
	public var u	:Number;
	public var v	:Number;
	
	public var thickness:Number;
	public var r2:Number;
	public var g2:Number;
	public var b2:Number;
	public var a2:Number;
	
	public function StrokeVertex( 	x:Number = 0, y:Number = 0, z:Number = 0,
									r:Number = 1, g:Number = 1, b:Number = 1, a:Number = 1,
									r2:Number = 1, g2:Number = 1, b2:Number = 1, a2:Number = 1,
									u:Number = 0, v:Number = 0,
									thickness:Number = 1 )
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.u = u;
		this.v = v;
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
		this.r2 = r2;
		this.g2 = g2;
		this.b2 = b2;
		this.a2 = a2;
		this.thickness = thickness;
	}
	
	public function clone():StrokeVertex
	{
		return new StrokeVertex(x, y, z, r, g, b, a, r2, g2, b2, a2, u, v);
	}
}