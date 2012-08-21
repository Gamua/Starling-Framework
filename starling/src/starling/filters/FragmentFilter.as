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
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Stage;
    import starling.errors.MissingContextError;
    import starling.textures.RenderTexture;
    import starling.utils.MatrixUtil;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    public class FragmentFilter
    {
        private var mTargetTexture:RenderTexture;
        private var mPaddingX:int;
        private var mPaddingY:int;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
        // helper objects
        private static var sBounds:Rectangle = new Rectangle();
        private static var sMatrix:Matrix = new Matrix();
        private static var sPosition:Point = new Point();
        
        public function FragmentFilter(paddingX:int=0, paddingY:int=0)
        {
            mPaddingX = paddingX;
            mPaddingY = paddingY;
            
            mVertexData = new VertexData(4);
            mVertexData.setTexCoords(0, 0, 0);
            mVertexData.setTexCoords(1, 1, 0);
            mVertexData.setTexCoords(2, 0, 1);
            mVertexData.setTexCoords(3, 1, 1);
            
            mIndexData = new <uint>[0, 1, 2, 1, 3, 2];
            mIndexData.fixed = true;
            
            createPrograms();
            
            // TODO: handle device loss
        }
        
        public function dispose():void
        {
            if (mTargetTexture) mTargetTexture.dispose();
        }
        
        public function render(object:DisplayObject, support:RenderSupport, parentAlpha:Number):void
        {
            var stage:Stage = object.stage;
            if (stage == null) return;
            
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            // draw object into render texture
            
            // get bounds in stage coordinates
            object.getBounds(stage, sBounds);
            sBounds.inflate(mPaddingX, mPaddingY);
            sBounds.width  = getNextPowerOfTwo(sBounds.width);
            sBounds.height = getNextPowerOfTwo(sBounds.height);
            
            // move object to top left
            sMatrix.identity();
            sMatrix.translate(-sBounds.x, -sBounds.y);
            
            if (mTargetTexture == null || 
                mTargetTexture.width != sBounds.width || mTargetTexture.height != sBounds.height)
            {
                if (mTargetTexture) mTargetTexture.dispose();
                mTargetTexture = new RenderTexture(sBounds.width, sBounds.height , false);
            }
            
            mTargetTexture.draw(object, sMatrix);
            
            // update vertex- and index buffers
            
            mVertexData.setPosition(0, sBounds.x, sBounds.y);
            mVertexData.setPosition(1, sBounds.right, sBounds.y);
            mVertexData.setPosition(2, sBounds.x, sBounds.bottom);
            mVertexData.setPosition(3, sBounds.right, sBounds.bottom);
            
            if (mVertexBuffer == null)
            {
                mVertexBuffer = context.createVertexBuffer(4, VertexData.ELEMENTS_PER_VERTEX);
                mIndexBuffer  = context.createIndexBuffer(6);
                mIndexBuffer.uploadFromVector(mIndexData, 0, 6);
            }
            
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, 4);
            
            // now draw the texture
            
            support.pushMatrix();
            support.loadIdentity();
            
            support.finishQuadBatch();
            support.raiseDrawCount(); // TODO: raise depending on number of passes
            support.applyBlendMode(false);
            
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setTextureAt(0, mTargetTexture.base);
            
            renderFilter(support, context);
            
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setTextureAt(0, null);
            
            support.popMatrix();
        }

        protected function createPrograms():void
        {
            throw new Error("Method has to be implemented in subclass!");
        }

        protected function renderFilter(support:RenderSupport, context:Context3D):void
        {
            throw new Error("Method has to be implemented in subclass!");
        }
        
        protected function drawTriangles(context:Context3D):void
        {
            context.drawTriangles(mIndexBuffer, 0, 2);
        }
        
        protected function assembleAgal(vertexShader:String, fragmentShader:String):Program3D
        {
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexShader);
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader);
            
            var context:Context3D = Starling.context;
            var program:Program3D = context.createProgram();
            program.upload(vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);          
            
            return program;
        }
    }
}