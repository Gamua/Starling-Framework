package starling.display
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.graphics.Fill;
	import starling.display.graphics.Stroke;
	import starling.display.materials.IMaterial;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.textures.Texture;
	
	public class Shape extends DisplayObjectContainer
	{
		private var penPositionPrev	:Point;
		private var penPosition		:Point;
		
		private var penDown			:Boolean = false;
		private var currentFill		:Fill;
		private var currentStroke	:Stroke;
		
		private var showProfiling	:Boolean;
		
		public var graphics			:Graphics;
		
		public function Shape( showProfiling:Boolean = false )
		{
			this.showProfiling = showProfiling
			penPosition = new Point();
			penPositionPrev = new Point();
			
			graphics	= new Graphics(this, showProfiling);
		}
		
		override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            return new Rectangle();
        }
		/*
		public function clear():void
		{
			while ( numChildren > 0 )
			{
				var child:DisplayObject = getChildAt(0);
				child.dispose();
				removeChildAt(0);
			}
		}
		
		//TODO: This should be removed
		public function beginStroke( closed:Boolean = false ):Stroke
		{
			currentStroke = new Stroke();
			addChild(currentStroke);
			return currentStroke;
		}
		
		public function beginTexturedStroke( texture:Texture, closed:Boolean = false ):Stroke
		{
			currentStroke = new Stroke();
			currentStroke.material.fragmentShader = new TextureVertexColorFragmentShader();
			currentStroke.material.textures[0] = texture;
			addChild(currentStroke);
			return currentStroke;
		}
		
		public function endStroke():void
		{
			currentStroke = null;
		}
		
		public function beginFill():Fill
		{
			currentFill = new Fill(showProfiling)
			addChild(currentFill);
			return currentFill;
		}
		
		public function beginTexturedFill( texture:Texture, m:Matrix = null ):Fill
		{
			currentFill = new Fill(showProfiling)
			currentFill.material.fragmentShader = new TextureVertexColorFragmentShader();
			currentFill.material.textures[0] = texture;
			if ( m )
			{
				currentFill.uvMatrix = m;
			}
			addChild(currentFill);
			return currentFill;
		}
		
		public function endFill():void
		{
			currentFill = null;
		}
		
		public function moveTo( x:Number, y:Number ):void
		{
			if ( currentStroke )
			{
				var material:IMaterial = currentStroke.material;
				endStroke();
				beginStroke();
				currentStroke.material = material;
			}
			endFill();
			penPositionPrev.x = penPosition.x;
			penPositionPrev.y = penPosition.y;
			penPosition.x = x;
			penPosition.y = y;
			penDown = false;
		}
		
		public function lineTo( x:Number, y:Number, thickness:Number = 1, color1:uint = 0xFFFFFF, alpha1:Number = 1, color2:uint = 0xFFFFFF, alpha2:Number = 1 ):void
		{
			penPositionPrev.x = penPosition.x;
			penPositionPrev.y = penPosition.y;
			penPosition.x = x;
			penPosition.y = y;
			
			if ( currentFill )
			{
				currentFill.addVertex( x, y, color1, alpha1 );
			}
			
			
			if ( currentStroke )
			{
				if ( penDown == false )
				{
					penDown = true;
					currentStroke.addVertex( penPositionPrev.x, penPositionPrev.y, thickness, color1, alpha1, color2, alpha2 );
				}
				
				currentStroke.addVertex( x, y, thickness, color1, alpha1, color2, alpha2 );
			}
		}
		*/
		
		override public function render( renderSupport:RenderSupport, alpha:Number ):void
		{
			super.render(renderSupport, alpha);
		}
	}
}