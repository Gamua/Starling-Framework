package starling.display.shaders
{
	import com.adobe.utils.AGALMiniAssembler;
	import flash.display3D.Context3D;
	import flash.utils.ByteArray;
	
	public class AbstractShader implements IShader
	{
		private static var assembler:AGALMiniAssembler;
		
		protected var _opCode	:ByteArray;
		
		public function AbstractShader()
		{
			
		}
		
		protected function compileAGAL( shaderType:String, agal:String ):void
		{
			if ( assembler == null )
			{
				assembler = new AGALMiniAssembler();
			}
			assembler.assemble( shaderType, agal );
			_opCode = assembler.agalcode;
		}
		
		public function get opCode():ByteArray
		{
			return _opCode;
		}
		
		public function setConstants( context:Context3D, firstRegister:int ):void
		{
			
		}
	}

}