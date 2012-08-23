package starling.display.shaders.fragment
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;
	import starling.display.shaders.AbstractShader;
	
	public class TextureVertexColorFragmentShader extends AbstractShader
	{
		public function TextureVertexColorFragmentShader()
		{
			var agal:String =
			"tex ft1, v1, fs0 <2d, repeat, linear> \n" +
			"mul oc, ft1, v0"
			
			compileAGAL( Context3DProgramType.FRAGMENT, agal );
		}
	}
}