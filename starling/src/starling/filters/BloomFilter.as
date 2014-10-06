// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.IndexBuffer3D;
	import flash.geom.Rectangle;
	import starling.filters.BlurFilter;
	import starling.filters.FragmentFilter;
	import starling.textures.Texture;
	import starling.utils.getNextPowerOfTwo;
	import starling.display.DisplayObject;
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.QuadBatch;
	import starling.utils.VertexData;


	/**
	 * BloomFilter - provides a fog/bloom style effect
	 *
	 * In essence this filter takes the object you apply it to and:
	 *   1. Copies it to a new layer
	 *   2. Applies a guassian blur to it
	 *   3. 'Blends' that layer with the original using the "lighten" blendmode
	 */
	public class BloomFilter extends FragmentFilter
	{
		protected var _lighten:Program3D = null; // lighten AGAL program
		protected var _blur:BlurFilter = null; // blur filter to apply to the new layer

		protected var _blurTex:Texture = null; // new layer
		protected var _renderSupport:RenderSupport = null; // rendersupport to use new layer


		public function BloomFilter(size:Number = 12)
		{
			super();
			_blur = new BlurFilter(size, size);
		}

		public override function dispose():void
		{
			_lighten.dispose();
			_blur.dispose();

			_blurTex.dispose();
			_renderSupport.dispose();
			super.dispose();
		}

		protected override function createPrograms():void
		{
			var fragmentProgramCode:String =
			"tex ft0, v0,  fs0 <2d, repeat, linear, mipnone>  \n" +
			"tex ft1, v0,  fs1 <2d, repeat, linear, mipnone>  \n" +
			"max ft2, ft1, ft0 \n" +
			"mov oc, ft2 \n";
		
			_lighten = assembleAgal(fragmentProgramCode);
		}

		protected override function activate(pass:int, context:Context3D, texture:Texture):void
		{
			context.setTextureAt(1, _blurTex.base);
			context.setProgram(_lighten)
		}

		protected override function deactivate(pass:int, context:Context3D, texture:Texture):void
		{
			context.setTextureAt(1, null);
		}

		public override function render(object:DisplayObject, support:RenderSupport, parentAlpha:Number):void
		{

			if (_blurTex == null) {
				var sBounds:Rectangle = new Rectangle();
				var sBoundsPot:Rectangle = new Rectangle();
				var scale:Number = Starling.current.contentScaleFactor;
				calculateBounds(object, object.stage, resolution * scale, false, sBounds, sBoundsPot);
				// setup the texture (new layer) and the rendersupport to use it
				_blurTex = Texture.empty(
					sBoundsPot.width, 
					sBoundsPot.height, 
					PMA, 
					false, 
					true, 
					resolution * scale
				);
				_renderSupport = new RenderSupport();
				_renderSupport.renderTarget = _blurTex;

			}
			_blur.render(object, _renderSupport, parentAlpha);
			super.render(object, support, parentAlpha);
		}
	}
}
