package starling.display.graphics
{
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.textures.Texture;
	
	public class TriangleFan extends Graphic
	{
		public static const VERTEX_STRIDE	:int = 9;
		
		protected var vertices		:Vector.<Number>;
		protected var indices		:Vector.<uint>;
		protected var numVertices	:uint = 0;
		protected var _closed 		:Boolean = false;
		
		public function TriangleFan()
		{
			vertices = new Vector.<Number>();
			indices = new Vector.<uint>();
		}
		
		public function addVertex( 	x:Number, y:Number, color:uint = 0xFFFFFF, alpha:Number = 1, u:Number = 0, v:Number = 0 ):void
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
			
			var r:Number = (color >> 16) / 255;
			var g:Number = ((color & 0x00FF00) >> 8) / 255;
			var b:Number = (color & 0x0000FF) / 255;
			
			vertices.push( x, y, 0, r, g, b, alpha, u, v );
			numVertices++;
			
			if ( numVertices < 3 )
			{
				indices.push( numVertices-1 );
			}
			else
			{
				indices.push( 0, numVertices - 2, numVertices - 1 );
			}
		}
		
		override public function render( renderSupport:RenderSupport, alpha:Number ):void
		{
			if ( numVertices < 3 ) return;
			
			if ( vertexBuffer == null )
			{
				vertexBuffer = Starling.context.createVertexBuffer( numVertices, VERTEX_STRIDE );
				vertexBuffer.uploadFromVector( vertices, 0, numVertices )
				indexBuffer = Starling.context.createIndexBuffer( indices.length );
				indexBuffer.uploadFromVector( indices, 0, indices.length );
			}
			
			super.render( renderSupport, alpha );
		}
	}
}