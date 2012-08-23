package starling.display.shaders.fragment
{
	import flash.display3D.Context3DProgramType;
	import starling.display.shaders.AbstractShader;
	
	public class VertexColorFragmentShader extends AbstractShader
	{
		public function VertexColorFragmentShader()
		{
			var agal:String = "mov oc, v0"
			compileAGAL( Context3DProgramType.FRAGMENT, agal );
		}
	}
}