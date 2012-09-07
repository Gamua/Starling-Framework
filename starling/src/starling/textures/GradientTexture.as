package starling.textures
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import starling.textures.Texture;
	
	public class GradientTexture
	{
		static public function create(width:Number, height:Number, type:String, colors:Array, alphas:Array, ratios:Array, matrix:Matrix=null, spreadMethod:String="pad", interpolationMethod:String="rgb", focalPointRatio:Number=0):Texture
		{
			var shape:Shape = new Shape();
			shape.graphics.beginGradientFill( type, colors, alphas, ratios, matrix, spreadMethod, interpolationMethod, focalPointRatio );
			shape.graphics.drawRect(0, 0, width, height);
			
			var bitmapData:BitmapData = new BitmapData(width, height, true);
			bitmapData.draw( shape );
			
			return Texture.fromBitmapData(bitmapData);
		}
	}
}