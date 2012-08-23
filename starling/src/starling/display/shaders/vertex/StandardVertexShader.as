package starling.display.shaders.vertex
{
	import flash.display3D.Context3DProgramType;
	import starling.display.shaders.AbstractShader;
	
	public class StandardVertexShader extends AbstractShader
	{
		public function StandardVertexShader()
		{
			var agal:String =
			"m44 op, va0, vc0 \n" +			// Apply matrix
			"mov v0, va1 \n" +				// Copy color to v0
			"mov v1, va2 \n"				// Copy UV to v1
			
			compileAGAL( Context3DProgramType.VERTEX, agal );
		}
	}
}