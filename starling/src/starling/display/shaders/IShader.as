package starling.display.shaders
{
	import flash.display3D.Context3D;
	import flash.utils.ByteArray;
	
	public interface IShader
	{
		function get opCode():ByteArray
		function setConstants( context:Context3D, firstRegister:int ):void
	}
}