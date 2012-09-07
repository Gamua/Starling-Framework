package
{
	import flash.display.GradientType;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.display.graphics.Fill;
	import starling.display.graphics.Stroke;
	import starling.display.graphics.TriangleFan;
	import starling.display.materials.StandardMaterial;
	import starling.display.shaders.fragment.TextureVertexColorFragmentShader;
	import starling.display.shaders.fragment.VertexColorFragmentShader;
	import starling.display.shaders.vertex.RippleVertexShader;
	import starling.display.shaders.vertex.StandardVertexShader;
	import starling.events.Event;
	import starling.textures.GradientTexture;
	import starling.textures.Texture;
	import starling.utils.Color;
	
	public class Sandbox extends Sprite
	{
		[Embed( source = "/assets/Rock.png" )]
		private var RockBMP		:Class;
		[Embed( source = "/assets/Grass.png" )]
		private var GrassBMP		:Class;
		[Embed( source = "/assets/Leaves.png" )]
		private var LeavesBMP		:Class;
		
		private var rockTexture	:Texture;
		private var grassTexture:Texture;
		private var leavesTexture:Texture;
		
		public function Sandbox()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded ( e:Event ):void
		{
			rockTexture = Texture.fromBitmap( new RockBMP(), false );
			grassTexture = Texture.fromBitmap( new GrassBMP(), false );
			leavesTexture = Texture.fromBitmap( new LeavesBMP(), false );
			
			var w:Number = stage.stageWidth;
			var h:Number = stage.stageHeight;
			
			
			var skyFill:Fill = new Fill();
			// Create a gradient texture, 1x4 px.
			// It doesn't need to be high resolution, as the texture's linear interpolation
			// will produce a gradient between pixel values anyway.
			var m:Matrix = new Matrix();
			m.createGradientBox( 1, 4, Math.PI*0.5 );
			var skyGradientTexture:Texture = GradientTexture.create( 2, 4, GradientType.LINEAR, [ 0x8ac9d2, 0xf4a886, 0xfec28c ], [1, 1, 1], [0, 128, 255], m );
			skyFill.uvMatrix.scale( w / skyGradientTexture.width, h / skyGradientTexture.height );
			skyFill.material.fragmentShader = new TextureVertexColorFragmentShader();
			skyFill.material.textures[0] = skyGradientTexture;
			skyFill.addVertex( 0, 0 );
			skyFill.addVertex( w, 0 );
			skyFill.addVertex( w, h );
			skyFill.addVertex( 0, h );
			addChild(skyFill);
			
			var waterColorTop:uint = 0x08acff;
			var waterColorBottom:uint = 0x0073ad;
			var waterColorSurface:uint = 0x61caff;
			
			var waterHeight:Number = h-100;
			var waterFill:Fill = new Fill();
			waterFill.addVertex(0, waterHeight, waterColorTop );
			waterFill.addVertex(w, waterHeight, waterColorTop );
			waterFill.addVertex(w, h, waterColorBottom );
			waterFill.addVertex(0, h, waterColorBottom );
			addChild(waterFill);
			
			var waterSurfaceThickness:Number = 20;
			var waterSurfaceStroke:Stroke = new Stroke();
			waterSurfaceStroke.material.vertexShader = new RippleVertexShader();
			for ( var i:int = 0; i < 50; i++ )
			{
				var ratio:Number = i / 49;
				waterSurfaceStroke.addVertex( ratio * w, waterHeight - waterSurfaceThickness*0.25, waterSurfaceThickness, waterColorSurface, 1, waterColorTop, 1 );
			}
			addChild(waterSurfaceStroke);
			
			var tree:Shape = createTree( w*0.75, h-140 );
			addChild(tree);
			
			var landFill:Fill = new Fill();
			landFill.material.fragmentShader = new TextureVertexColorFragmentShader();
			landFill.material.textures[0] = rockTexture;
			var landStroke:Stroke = new Stroke();
			landStroke.material.fragmentShader = new TextureVertexColorFragmentShader();
			landStroke.material.textures[0] = grassTexture;
			
			var landHeight:Number = 200;
			var landDetail:int = 30;
			for ( i = 0; i < landDetail; i++ )
			{
				ratio = i / (landDetail-1);
				var x:Number = ratio * w;
				var termA:Number = Math.cos( ratio * Math.PI * 2.34 );
				var termB:Number = Math.sin( ratio * Math.PI * 1.12 );
				var y:Number = h - ((termA+termB)+1) * 0.4 * landHeight;
				y += Math.random() * 40;
				landFill.addVertex( x, y );
				
				var thickness:Number = (30 + Math.random() * 30)// * (y > (waterHeight-40) ? 0 : 1);
				landStroke.addVertex( x, y, thickness  );
			}
			landFill.addVertex(w, h+40);
			landFill.addVertex(0, h+40);
			addChild(landFill);
			addChild(landStroke);
		}
		
		private function createTree( x:Number, y:Number, depth:int = 2 ):Shape
		{
			var shape:Shape = new Shape();
			
			var spreadMin:Number = Math.PI * 0.05;
			var spreadMax:Number = Math.PI * 0.3;
			var attenuation:Number = 0.7;
			var attenuationRandomFactor:Number = 0.2;
			var depthAttenuationRandomFactor:Number = 1;
			
			var nodes:Array = [ { x:x, y:y, depth:depth, angle: -Math.PI * 0.5, length:100, thickness:40 } ];
			
			var leaves:Vector.<TriangleFan> = new Vector.<TriangleFan>();
			
			while ( nodes.length > 0 )
			{
				var node:Object = nodes.pop();
				
				var nx:Number = Math.cos( node.angle );
				var ny:Number = Math.sin( node.angle );
				var x2:Number = node.x + nx * node.length;
				var y2:Number = node.y + ny * node.length;
				
				var stroke:Stroke = new Stroke();
				stroke.addVertex( node.x, node.y, node.thickness, 0xc07732, 1, 0xc07732 );
				stroke.addVertex( x2, y2, node.thickness * attenuation, 0xc07732, 1, 0xc07732 );
				shape.addChild(stroke);
				
				if ( node.depth <= 0 )
				{
					var triangleFan:TriangleFan = new TriangleFan();
					triangleFan.material.fragmentShader = new TextureVertexColorFragmentShader();
					triangleFan.material.textures[0] = leavesTexture;
					triangleFan.x = x2;
					triangleFan.y = y2;
					triangleFan.rotation = Math.random() * 360;
					leaves.push(triangleFan);
					triangleFan.addVertex(0, 0, 0xFFFFFF, 1, 0, 1);
					var radius:Number = 30 + Math.random() * 30;
					var numBumps:int = 2 + Math.random() * 1;
					var bumpSize:Number = 5 + Math.random() * 5;
					var leavesDetail:int = 30;
					for ( var i:int = 0; i < leavesDetail; i++ )
					{
						var ratio:Number = i / (leavesDetail-2);
						var angle:Number = ratio * Math.PI * 2;
						nx = Math.cos(angle);
						ny = Math.sin(angle);
						
						var currRadius:Number = radius + Math.sin( (angle * numBumps) % Math.PI ) * 15;
						trace(Math.sin( (angle * 2) % Math.PI ));
						//currRadius += Math.random() * 5;
						
						triangleFan.addVertex( nx * currRadius, ny * currRadius, 0xFFFFFF, 1, ratio, 0 );
					}
					
					continue;
				}
				
				nodes.push( {	x:x2, 
								y:y2, 
								depth:node.depth - Math.ceil(Math.random() * depthAttenuationRandomFactor), 
								angle:node.angle - (spreadMin + Math.random() * spreadMax), 
								length:node.length * (attenuation + Math.random() * attenuationRandomFactor),
								thickness:node.thickness * attenuation } );
				
				nodes.push( {	x:x2, 
								y:y2, 
								depth:node.depth - Math.ceil(Math.random() * depthAttenuationRandomFactor), 
								angle:node.angle + (spreadMin + Math.random() * spreadMax), 
								length:node.length * (attenuation + Math.random() * attenuationRandomFactor),
								thickness:node.thickness * attenuation } );
				
			}
			
			for each ( var leaf:TriangleFan in leaves )
			{
				shape.addChild(leaf);
			}
			
			return shape;
		}
	}
}