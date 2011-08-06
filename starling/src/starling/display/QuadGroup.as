package starling.display
{
    import flash.display3D.*;
    import flash.display3D.textures.TextureBase;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.errors.MissingContextError;
    import starling.utils.VertexData;
    import starling.utils.rad2deg;
    
    internal class QuadGroup
    {
        private var mVertexData:VertexData;
        private var mIndices:Vector.<uint>;
        private var mTexture:TextureBase;
        
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexBuffer:IndexBuffer3D;
        
        public function QuadGroup(texture:TextureBase)
        {
            mVertexData = new VertexData(0);
            mIndices = new <uint>[];
            mTexture = texture;
        }
        
        public function dispose():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
        }
        
        public function addQuadData(vertexData:VertexData):void
        {
            var numVertices:int = mVertexData.numVertices;
            mIndices.push(numVertices,     numVertices + 1, numVertices + 2, 
                numVertices + 1, numVertices + 3, numVertices + 2);
            mVertexData.append(vertexData);
        }
        
        public function finish():void
        {
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            mIndices.fixed = true; // no more changes allowed
            
            mVertexBuffer = context.createVertexBuffer(mVertexData.numVertices, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.data, 0, mVertexData.numVertices);
            
            mIndexBuffer = context.createIndexBuffer(mIndices.length);
            mIndexBuffer.uploadFromVector(mIndices, 0, mIndices.length);
        }
        
        public function render(support:RenderSupport, alpha:Number):void
        {
            var context:Context3D = Starling.context;
            var alphaVector:Vector.<Number> = new <Number>[alpha, alpha, alpha, alpha];
            
            if (context == null) throw new MissingContextError();
            
            var program:String = mTexture ? Image.PROGRAM_NAME : Quad.PROGRAM_NAME;
            
            context.setProgram(Starling.current.getProgram(program));
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_3);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, alphaVector, 1);
            
            if (mTexture)
            {
                context.setTextureAt(1, mTexture);
                context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            }
            
            context.drawTriangles(mIndexBuffer, 0, mIndices.length / 3);
            
            context.setTextureAt(1, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(2, null);
        }
        
        public function get texture():TextureBase { return mTexture; }
        
        public static function compile(container:DisplayObjectContainer):Vector.<QuadGroup>
        {
            var quadGroups:Vector.<QuadGroup> = new <QuadGroup>[];
            var matrixStack:Vector.<Matrix3D> = new <Matrix3D>[new Matrix3D()];
            var alphaStack:Vector.<Number> = new <Number>[1.0];
            
            compileObject(container, quadGroups, matrixStack, alphaStack);
            
            for each (var quadGroup:QuadGroup in quadGroups)
                quadGroup.finish();
                
            return quadGroups;
        }
        
        private static function compileObject(object:DisplayObject, 
                                              quadGroups:Vector.<QuadGroup>,
                                              matrixStack:Vector.<Matrix3D>, 
                                              alphaStack:Vector.<Number>):void
        {
            // ignore transparent objects, except root
            if (quadGroups.length != 0 && (object.alpha == 0.0 || !object.visible)) return;
            
            var currentMatrix:Matrix3D = matrixStack[matrixStack.length-1];
            var currentAlpha:Number = alphaStack[alphaStack.length-1];
            var i:int;
            
            if (object is DisplayObjectContainer)
            {
                var container:DisplayObjectContainer = object as DisplayObjectContainer;
                
                for (i=0; i<container.numChildren; ++i)
                {
                    var child:DisplayObject = container.getChildAt(i);
                    
                    var childMatrix:Matrix3D = currentMatrix.clone();
                    RenderSupport.transformMatrixForObject(childMatrix, child);
                    
                    matrixStack.push(childMatrix);
                    alphaStack.push(child.alpha);
                    
                    compileObject(child, quadGroups, matrixStack, alphaStack);
                    
                    matrixStack.pop();
                    alphaStack.pop();
                }
            }
            else if (object is Quad)
            {
                var quad:Quad = object as Quad;
                var vertexData:VertexData = quad.vertexData;
                
                for (i=0; i<vertexData.numVertices; ++i)
                    vertexData.transformVertex(i, currentMatrix, currentAlpha);
                
                var image:Image = object as Image;
                var texture:TextureBase = image ? image.texture.base : null;
                
                if (quadGroups.length == 0 || quadGroups[quadGroups.length-1].texture != texture)
                    quadGroups.push(new QuadGroup(texture));
                
                quadGroups[quadGroups.length-1].addQuadData(vertexData);
            }
            else
            {
                throw new Error("Unsupported display object: " + getQualifiedClassName(object));
            }
        }
    }
}