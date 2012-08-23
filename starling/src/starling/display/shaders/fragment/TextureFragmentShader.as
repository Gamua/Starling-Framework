package starling.display.shaders.fragment
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;
	import starling.display.shaders.AbstractShader;
	
	public class TextureFragmentShader extends AbstractShader
	{
		public function TextureFragmentShader()
		{
			var agal:String =
			"tex ft1, v1, fs0 <2d, repeat, linear> \n" +
			"mov oc, ft1"
			
			compileAGAL( Context3DProgramType.FRAGMENT, agal );
		}
	}
}