// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display.Bitmap;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.VertexData;
    
    public class Image extends Quad
    {
        private var mTexture:Texture;
        private var mSmoothing:String;
        
        public function Image(texture:Texture)
        {
            if (texture)
            {
                var frame:Rectangle = texture.frame;
                var width:Number  = frame ? frame.width  : texture.width;
                var height:Number = frame ? frame.height : texture.height;
                
                super(width, height);
                
                mVertexData.premultipliedAlpha = texture.premultipliedAlpha;
                mVertexData.setTexCoords(0, 0.0, 0.0);
                mVertexData.setTexCoords(1, 1.0, 0.0);
                mVertexData.setTexCoords(2, 0.0, 1.0);
                mVertexData.setTexCoords(3, 1.0, 1.0);
                mTexture = texture;
                mSmoothing = TextureSmoothing.BILINEAR;
            }
            else
            {
                throw new ArgumentError("Texture cannot be null");                
            }
        }
        
        public static function fromBitmap(bitmap:Bitmap):Image
        {
            return new Image(Texture.fromBitmap(bitmap));
        }
        
        public function setTexCoords(vertexID:int, coords:Point):void
        {
            mVertexData.setTexCoords(vertexID, coords.x, coords.y);
            if (mVertexBuffer) createVertexBuffer();
        }
        
        public function getTexCoords(vertexID:int):Point
        {
            return mVertexData.getTexCoords(vertexID);
        }
        
        public override function get vertexData():VertexData
        {
            return mTexture.adjustVertexData(mVertexData);
        }
        
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void 
        { 
            if (value == null)
            {
                throw new ArgumentError("Texture cannot be null");
            }
            else if (value != mTexture)
            {
                mTexture = value;
                mVertexData.premultipliedAlpha = mTexture.premultipliedAlpha;
                if (mVertexBuffer) createVertexBuffer();
            }
        }
        
        public function get smoothing():String { return mSmoothing; }
        public function set smoothing(value:String):void 
        {
            if (TextureSmoothing.isValid(value))
                mSmoothing = value;
            else
                throw new ArgumentError("Invalid smoothing mode: " + smoothing);
        }
        
        public override function render(support:RenderSupport, alpha:Number):void
        {
            alpha *= this.alpha;
            
            var pma:Boolean = mTexture.premultipliedAlpha;
            var programName:String = getProgramName(mTexture.mipMapping, mTexture.repeat, mSmoothing);
            var context:Context3D = Starling.context;
            
            if (context == null) throw new MissingContextError();
            if (mVertexBuffer == null) createVertexBuffer();
            if (mIndexBuffer  == null) createIndexBuffer();
            
            var alphaVector:Vector.<Number> = pma ? new <Number>[alpha, alpha, alpha, alpha] :
                                                    new <Number>[1.0, 1.0, 1.0, alpha];
            support.setDefaultBlendFactors(pma);
            
            context.setProgram(Starling.current.getProgram(programName));
            context.setTextureAt(1, mTexture.base);
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_4);
            context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, alphaVector, 1);
            context.drawTriangles(mIndexBuffer, 0, 2);
            
            context.setTextureAt(1, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(2, null);
        }

        public static function registerPrograms(target:Starling):void
        {
            // create vertex and fragment programs - from assembly.
            // each combination of repeat/mipmap/smoothing has its own fragment shader.
            
            var vertexProgramCode:String =
                "m44 op, va0, vc0  \n" +  // 4x4 matrix transform to output clipspace
                "mov v0, va1       \n" +  // pass color to fragment program
                "mov v1, va2       \n";   // pass texture coordinates to fragment program

            var fragmentProgramCode:String =
                "tex ft1, v1, fs1 <???> \n" +  // sample texture 1
                "mul ft2, ft1, v0       \n" +  // multiply color with texel color
                "mul oc, ft2, fc0       \n";   // multiply color with alpha

            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            
            var smoothingTypes:Array = [
                TextureSmoothing.NONE,
                TextureSmoothing.BILINEAR,
                TextureSmoothing.TRILINEAR
            ];
            
            for each (var repeat:Boolean in [true, false])
            {
                for each (var mipmap:Boolean in [true, false])
                {
                    for each (var smoothing:String in smoothingTypes)
                    {
                        var options:Array = ["2d", repeat ? "repeat" : "clamp"];
                        
                        if (smoothing == TextureSmoothing.NONE)
                            options.push("nearest", mipmap ? "mipnearest" : "mipnone");
                        else if (smoothing == TextureSmoothing.BILINEAR)
                            options.push("linear", mipmap ? "mipnearest" : "mipnone");
                        else
                            options.push("linear", mipmap ? "miplinear" : "mipnone");
                        
                        fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
                            fragmentProgramCode.replace("???", options.join())); 
                        
                        target.registerProgram(getProgramName(mipmap, repeat, smoothing),
                            vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
                    }
                }
            }
        }
        
        public static function getProgramName(mipMap:Boolean=true, repeat:Boolean=false, 
                                              smoothing:String="bilinear"):String
        {
            // this method is called very often, so it should return quickly when called with 
            // the default parameters (no-repeat, mipmap, bilinear)
            
            var name:String = "image|";
            
            if (!mipMap) name += "N";
            if (repeat)  name += "R";
            if (smoothing != TextureSmoothing.BILINEAR) name += smoothing.charAt(0);
            
            return name;
        }
    }
}