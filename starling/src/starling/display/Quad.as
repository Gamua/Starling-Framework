package starling.display
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.utils.VertexData;

    public class Quad extends DisplayObject
    {
        public static const PROGRAM_NAME:String = "QuadProgram";
        
        protected var mVertexData:VertexData;
        protected var mVertexBuffer:VertexBuffer3D;
        protected var mIndexBuffer:IndexBuffer3D;
        
        public function Quad(width:Number, height:Number, color:uint=0xffffff)
        {
            mVertexData = new VertexData(4);            
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height);            
            mVertexData.setUniformColor(color);
        }
        
        public override function dispose():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            super.dispose();
        }
        
        public override function getBounds(targetSpace:DisplayObject):Rectangle
        {
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            var i:int;
            
            if (targetSpace == this) // optimization
            {
                for (i=0; i<4; ++i)
                {
                    var pos:Vector3D = mVertexData.getPosition(i);
                    minX = Math.min(minX, pos.x);
                    maxX = Math.max(maxX, pos.x);
                    minY = Math.min(minY, pos.y);
                    maxY = Math.max(maxY, pos.y);
                }
            }
            else
            {
                var transformationMatrix:Matrix = getTransformationMatrixToSpace(targetSpace);
                var point:Point = new Point();
                
                for (i=0; i<4; ++i)
                {
                    point.x = mVertexData.getPosition(i).x;
                    point.y = mVertexData.getPosition(i).y;
                    var transformedPoint:Point = transformationMatrix.transformPoint(point);
                    minX = Math.min(minX, transformedPoint.x);
                    maxX = Math.max(maxX, transformedPoint.x);
                    minY = Math.min(minY, transformedPoint.y);
                    maxY = Math.max(maxY, transformedPoint.y);                    
                }
            }
            
            return new Rectangle(minX, minY, maxX-minX, maxY-minY);
        }
        
        public function setVertexColor(vertexID:int, color:uint):void
        {
            mVertexData.setColor(vertexID, color);
        }
        
        public function getVertexColor(vertexID:int):uint
        {
            return mVertexData.getColor(vertexID);
        }
        
        public function get color():uint { return mVertexData.getColor(0); }
        
        public function set color(value:uint):void 
        {
            mVertexData.setUniformColor(value);
            createVertexBuffer();
        }
        
        public override function render(support:RenderSupport):void
        {
            var context:Context3D = Starling.context;
            var alphaVector:Vector.<Number> = new <Number>[alpha, alpha, alpha, alpha];
            
            if (context == null) throw new MissingContextError();
            if (mVertexBuffer == null) createVertexBuffer();
            if (mIndexBuffer == null) createIndexBuffer();
            
            context.setProgram(Starling.current.getProgram(PROGRAM_NAME));
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_3);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, alphaVector, 1);
            context.drawTriangles(mIndexBuffer, 0, 2);
            
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
        }
        
        protected function createVertexBuffer():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            mVertexBuffer = mVertexData.toVertexBuffer();
        }
        
        protected function createIndexBuffer():void
        {
            if (mIndexBuffer) mIndexBuffer.dispose();
            mIndexBuffer = Starling.context.createIndexBuffer(6);
            mIndexBuffer.uploadFromVector(Vector.<uint>([0, 1, 2, 1, 2, 3]), 0, 6);
        }
        
        public static function registerPrograms(target:Starling):void
        {
            // create a vertex and fragment program - from assembly
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, 
                "m44 op, va0, vc0  \n" +  // 4x4 matrix transform to output clipspace
                "mov v0, va1       \n"    // pass color to fragment program 
            );
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler(); 
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
                "mul ft0, v0, fc0  \n" +  // multiply alpha (fc0) by color (vc0)
                "mov oc, ft0       \n"    // output color
            );
            
            target.registerProgram(PROGRAM_NAME, vertexProgramAssembler.agalcode,
                                               fragmentProgramAssembler.agalcode);
        }
    }
}