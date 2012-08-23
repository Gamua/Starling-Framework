package starling.display.graphics
{
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.materials.IMaterial;
	import starling.display.materials.StandardMaterial;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.display.shaders.fragment.VertexColorFragmentShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.textures.Texture;
	
	/**
	 * Abstract, do not instantiate directly
	 * Used as a base-class for all the drawing API sub-display objects (Like Fill and Stroke).
	 */
	public class Graphic extends DisplayObject
	{
		protected var _material		:IMaterial;
		protected var vertexBuffer	:VertexBuffer3D;
		protected var indexBuffer	:IndexBuffer3D;
		
		public function Graphic()
		{
			_material = new StandardMaterial( new StandardVertexShader(), new VertexColorFragmentShader() );
		}
		
		override public function dispose():void
		{
			super.dispose();
			
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
		}
		
		override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			return new Rectangle();
		}
		
		public function set material( value:IMaterial ):void
		{
			_material = value;
		}
		
		public function get material():IMaterial
		{
			return _material;
		}
		
		override public function render( renderSupport:RenderSupport, alpha:Number ):void
		{
			var pma:Boolean = false;
			if ( material.textures.length > 0 && material.textures[0].premultipliedAlpha )
			{
				pma = true;
			}
			RenderSupport.setDefaultBlendFactors(pma);
			_material.drawTriangles( Starling.context, renderSupport.mvpMatrix3D, vertexBuffer, indexBuffer );
		}
	}
}