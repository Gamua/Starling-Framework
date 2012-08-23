package starling.display.shaders.vertex
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.getTimer;
	import starling.display.shaders.AbstractShader;
	
	public class RippleVertexShader extends AbstractShader
	{
		public function RippleVertexShader()
		{
			var agal:String =
			"mul vt0, va0.x, vc4.y \n" +	// Calculate vert.x * frequency. Store in 0
			"add vt1, vc4.x, vt0 \n" + 		// Calculate phase + scaledX. Store in 1
			"sin vt2, vt1 \n" +
			"mul vt3, vt2, vc4.z \n" +
			"add vt4, va0.y, vt3 \n" +
			"mov vt5, va0 \n" +
			"mov vt5.y, vt4 \n" +
			
			"m44 op, vt5, vc0 \n" +			// Apply view matrix
			
			"mov v0, va1 \n" +				// Copy color to v0
			"mov v1, va2 \n"				// Copy UV to v1
			
			compileAGAL( Context3DProgramType.VERTEX, agal );
		}
		
		override public function setConstants( context:Context3D, firstRegister:int ):void
		{
			var phase:Number = getTimer()/200;
			var frequency:Number = 0.02;
			var amplitude:Number = 5;
			context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, firstRegister, Vector.<Number>([ phase, frequency, amplitude, 1 ]) );
		}
	}
}