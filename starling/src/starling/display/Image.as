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
    import starling.utils.VertexData;
    
    public class Image extends Quad
    {
        public static const PROGRAM_NAME:String = "ImageProgram";
        
        private var mTexture:Texture;
                
        public function Image(texture:Texture)
        {
            if (texture)
            {
                var frame:Rectangle = texture.frame;
                var width:Number  = frame ? frame.width  : texture.width;
                var height:Number = frame ? frame.height : texture.height;
                
                super(width, height);
                
                mVertexData.setTexCoords(0, 0.0, 0.0);
                mVertexData.setTexCoords(1, 1.0, 0.0);
                mVertexData.setTexCoords(2, 0.0, 1.0);
                mVertexData.setTexCoords(3, 1.0, 1.0);
                mTexture = texture;
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
            createVertexBuffer();
        }
        
        public function getTexCoords(vertexID:int):Point
        {
            return mVertexData.getTexCoords(vertexID);
        }
        
        protected override function createVertexBuffer():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();            
            mVertexBuffer = mTexture.adjustVertexData(mVertexData).toVertexBuffer();
        }
        
        public override function render(support:RenderSupport):void
        {
            if (mVertexBuffer == null) createVertexBuffer();
            var context:Context3D = Starling.context;
            var alphaVector:Vector.<Number> = new <Number>[alpha, alpha, alpha, alpha];
            
            if (context == null) throw new MissingContextError();
            
            context.setProgram(support.getProgram(PROGRAM_NAME));
            context.setTextureAt(1, mTexture.nativeTexture);
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_3);
            context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, alphaVector, 1);
            context.drawTriangles(support.quadIndexBuffer, 0, 2);
            
            context.setTextureAt(1, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(2, null);
        }
        
        public static function registerPrograms(support:RenderSupport):void
        {
            // create a vertex and fragment program - from assembly
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, 
                "m44 op, va0, vc0  \n" +  // 4x4 matrix transform to output clipspace
                "mov v0, va1       \n" +  // pass color to fragment program
                "mov v1, va2       \n"    // pass texture coordinates to fragment program
            );
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler(); 
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
                "tex ft1, v1, fs1 <2d,clamp,linear> \n" + // sample texture 1
                "mul ft2, ft1, v0                   \n" + // multiply color with texel color
                "mul oc, ft2, fc0                   \n"   // multiply color with alpha
            );
            
            support.registerProgram(PROGRAM_NAME, vertexProgramAssembler.agalcode,
                                                fragmentProgramAssembler.agalcode);
        }
        
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void 
        { 
            if (value)
            {
                mTexture = value;
                createVertexBuffer();
            }
            else throw new ArgumentError("Texture cannot be null");
        }
    }
}