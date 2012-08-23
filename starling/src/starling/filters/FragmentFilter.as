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
    import starling.textures.Texture;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    public class FragmentFilter
    {
        private const PMA:Boolean = true;
        
        private var mNumPasses:int;
        private var mPaddingX:int;
        private var mPaddingY:int;
        private var mPassTextures:Vector.<Texture>;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
        /** helper objects. */
        private static var sBounds:Rectangle = new Rectangle();
        private static var sMatrix:Matrix = new Matrix();
        
        public function FragmentFilter(numPasses:int=1, paddingX:int=0, paddingY:int=0)
        {
            if (numPasses < 1) throw new ArgumentError("At least one pass is required.");
            
            mNumPasses = numPasses;
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
            for each (var texture:Texture in mPassTextures)
                texture.dispose();
        }
        
        public function render(object:DisplayObject, support:RenderSupport, parentAlpha:Number):void
        {
            var stage:Stage = object.stage;
            if (stage == null) return;
            
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            // get bounds in stage coordinates
            object.getBounds(stage, sBounds);
            sBounds.inflate(mPaddingX, mPaddingY);
            sBounds.width  = getNextPowerOfTwo(sBounds.width);
            sBounds.height = getNextPowerOfTwo(sBounds.height);
            
            // TODO: intersect with stage bounds & set scissor rectangle accordingly
            updatePassTextures(sBounds.width, sBounds.height);
            
            // update the vertices that span up the filter rectangle 
            updateBuffers(context, sBounds.width, sBounds.height);
            
            // draw the original object into a render texture
            renderBaseTexture(object, sBounds.x, sBounds.y);
            
            // now prepare filter passes
            support.finishQuadBatch();
            support.raiseDrawCount(mNumPasses);
            RenderSupport.setBlendFactors(PMA); // TODO: check blend modes
            
            support.pushMatrix();
            sMatrix.copyFrom(support.projectionMatrix); // save original projection matrix
            
            support.loadIdentity();
            support.setOrthographicProjection(sBounds.width, sBounds.height);
            
            // set shader attributes
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            
            for (var i:int=0; i<mNumPasses; ++i)
            {
                if (i < mNumPasses - 1) // intermediate pass - draw into texture  
                {
                    context.setRenderToTexture(mPassTextures[i+1].base);
                    RenderSupport.clear();
                }
                else // final pass -- draw into back buffer, at original position
                {
                    context.setRenderToBackBuffer();
                    support.projectionMatrix.copyFrom(sMatrix); // restore projection matrix
                    support.translateMatrix(sBounds.x, sBounds.y);
                    
                    support.applyBlendMode(false);
                }
                
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
                context.setTextureAt(0, mPassTextures[i].base);
                
                renderFilter(i, support, context);
            }
            
            // reset shader attributes
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setTextureAt(0, null);
            
            support.popMatrix();
        }
        
        // helper methods
        
        private function renderBaseTexture(object:DisplayObject, offsetX:Number, offsetY:Number):void
        {
            // move object to top left
            sMatrix.identity();
            sMatrix.translate(-offsetX, -offsetY);
            
            var basePassTexture:RenderTexture = mPassTextures[0] as RenderTexture;
            basePassTexture.draw(object, sMatrix);
        }
        
        private function updateBuffers(context:Context3D, width:Number, height:Number):void
        {
            mVertexData.setPosition(1, width, 0);
            mVertexData.setPosition(2, 0, height);
            mVertexData.setPosition(3, width, height);
            
            if (mVertexBuffer == null)
            {
                mVertexBuffer = context.createVertexBuffer(4, VertexData.ELEMENTS_PER_VERTEX);
                mIndexBuffer  = context.createIndexBuffer(6);
                mIndexBuffer.uploadFromVector(mIndexData, 0, 6);
            }
            
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, 4);
        }
        
        private function updatePassTextures(width:int, height:int):void
        {
            var needsUpdate:Boolean = mPassTextures == null || 
                mPassTextures[0].width != width || mPassTextures[0].height != height;  
            
            if (needsUpdate)
            {
                if (mPassTextures)
                    for each (var texture:Texture in mPassTextures)
                        texture.dispose();
                else
                    mPassTextures = new Vector.<Texture>(mNumPasses, true);
                
                var scale:Number = Starling.contentScaleFactor; 
                mPassTextures[0] = new RenderTexture(width, height, false, scale);
                
                for (var i:int=1; i<mNumPasses; ++i)
                    mPassTextures[i] = Texture.empty(width, height, PMA, true, scale);
            }
        }
        
        // protected methods

        protected function createPrograms():void
        {
            throw new Error("Method has to be implemented in subclass!");
        }

        protected function renderFilter(pass:int, support:RenderSupport, context:Context3D):void
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

        // properties
        
        public function get numPasses():int { return mNumPasses; }
    }
}