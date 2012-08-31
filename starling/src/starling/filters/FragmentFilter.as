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
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Stage;
    import starling.errors.AbstractClassError;
    import starling.errors.MissingContextError;
    import starling.textures.Texture;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    /** The FragmentFilter class is the base class for all filter effects.
     *  
     *  <p>All other filters of this package extend this class. You can attach them to any display
     *  object through the 'filter' property. To combine several filters, group them in a 
     *  'FilterChain' instance.</p>
     *  
     *  <p>Create your own filters by extending this class.</p>
     */ 
    public class FragmentFilter
    {
        protected const PMA:Boolean = true;
        protected const STD_VERTEX_SHADER:String = 
            "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
            "mov v0, va1      \n";  // pass texture coordinates to fragment program
        
        private var mNumPasses:int;
        private var mPassTextures:Vector.<Texture>;
        private var mMode:String;
        private var mResolution:Number;
        
        private var mMarginTop:Number;
        private var mMarginBottom:Number;
        private var mMarginLeft:Number;
        private var mMarginRight:Number;
        
        private var mBaseImage:Image;
        private var mOffsetX:Number;
        private var mOffsetY:Number;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
        /** helper objects. */
        private var mBounds:Rectangle  = new Rectangle();
        private var mProjMatrix:Matrix = new Matrix();
        
        public function FragmentFilter(numPasses:int=1, resolution:Number=1.0)
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.filters::FragmentFilter")
            {
                throw new AbstractClassError();
            }
            
            if (numPasses < 1) throw new ArgumentError("At least one pass is required.");
            
            mNumPasses = numPasses;
            mMarginTop = mMarginBottom = mMarginLeft = mMarginRight = 0.0;
            mMode = FragmentFilterMode.REPLACE;
            mOffsetX = mOffsetY = 0;
            mResolution = resolution;
            
            mVertexData = new VertexData(4);
            mVertexData.setTexCoords(0, 0, 0);
            mVertexData.setTexCoords(1, 1, 0);
            mVertexData.setTexCoords(2, 0, 1);
            mVertexData.setTexCoords(3, 1, 1);
            
            mIndexData = new <uint>[0, 1, 2, 1, 3, 2];
            mIndexData.fixed = true;
            
            createPrograms();
            
            // TODO: handle device loss
            // TODO: check blend modes
            // TODO: intersect object bounds with stage bounds & set scissor rectangle accordingly
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
            
            if (mode == FragmentFilterMode.ABOVE)
                object.render(support, parentAlpha);
            
            // save original projection matrix and render target
            mProjMatrix.copyFrom(support.projectionMatrix); 
            var previousRenderTarget:Texture = support.renderTarget;
            
            if (previousRenderTarget)
                throw new IllegalOperationError(
                    "It's currently not possible to stack filters! " +
                    "This limitation will be removed in a future Stage3D version.");
            
            // get bounds in stage coordinates
            // can be expensive, so we optimize at least for full-screen effects
            if (object == stage || object == Starling.current.root)
                mBounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
            else
                object.getBounds(stage, mBounds);
            
            var deltaMargin:Number = mResolution == 1.0 ? 0.0 : 1.0 / mResolution; // to avoid hard edges
            mBounds.x -= mMarginLeft + deltaMargin;
            mBounds.y -= mMarginTop  + deltaMargin;
            mBounds.width  += mMarginLeft + mMarginRight  + 2*deltaMargin;
            mBounds.height += mMarginTop  + mMarginBottom + 2*deltaMargin;
            
            mBounds.width  = getNextPowerOfTwo(mBounds.width  * mResolution);
            mBounds.height = getNextPowerOfTwo(mBounds.height * mResolution);
            
            updatePassTextures(mBounds.width, mBounds.height);
            
            // update the vertices that span up the filter rectangle 
            updateBuffers(context, mBounds.width, mBounds.height);
            
            // now prepare filter passes
            support.finishQuadBatch();
            support.raiseDrawCount(mNumPasses);
            
            support.pushMatrix();
            support.loadIdentity();
            support.setOrthographicProjection(mBounds.width, mBounds.height);
            
            // draw the original object into a render texture
            var matrix:Matrix = support.modelViewMatrix; 
            object.getTransformationMatrix(stage, matrix);
            matrix.translate(-mBounds.x, -mBounds.y);
            matrix.scale(mResolution, mResolution);
            
            support.renderTarget = mPassTextures[0];
            support.clear();
            
            object.render(support, parentAlpha);
            
            support.finishQuadBatch();
            support.loadIdentity();
            
            // set shader attributes
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            
            // draw all passes
            for (var i:int=0; i<mNumPasses; ++i)
            {
                if (i < mNumPasses - 1) // intermediate pass - draw into texture  
                {
                    support.renderTarget = getPassTexture(i+1);
                    support.clear();
                }
                else // final pass -- draw into back buffer, at original position
                {
                    support.renderTarget = previousRenderTarget;
                    support.projectionMatrix.copyFrom(mProjMatrix); // restore projection matrix
                    support.translateMatrix(mBounds.x + mOffsetX, mBounds.y + mOffsetY);
                    support.scaleMatrix(1.0/mResolution, 1.0/mResolution);
                    support.applyBlendMode(false);
                }
                
                var passTexture:Texture = getPassTexture(i);
                
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);
                context.setTextureAt(0, passTexture.base);
                
                activate(i, context, passTexture);
                context.drawTriangles(mIndexBuffer, 0, 2);
                deactivate(i, context, passTexture);
            }
            
            // reset shader attributes
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setTextureAt(0, null);
            
            support.popMatrix();
            
            if (mode == FragmentFilterMode.BELOW)
                object.render(support, parentAlpha);
        }
        
        // helper methods
        
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
            var numPassTextures:int = mNumPasses > 1 ? 2 : 1;
            
            var needsUpdate:Boolean = mPassTextures == null || 
                mPassTextures.length != numPassTextures ||
                mPassTextures[0].width != width || mPassTextures[0].height != height;  
            
            if (needsUpdate)
            {
                if (mPassTextures)
                {
                    for each (var texture:Texture in mPassTextures) texture.dispose();
                    mPassTextures.length = numPassTextures;
                }
                else
                {
                    mPassTextures = new Vector.<Texture>(numPassTextures);
                }
                
                for (var i:int=0; i<numPassTextures; ++i)
                    mPassTextures[i] = Texture.empty(width, height, PMA, true);
            }
        }
        
        private function getPassTexture(pass:int):Texture
        {
            return mPassTextures[pass % 2];
        }
        
        // protected methods

        protected function createPrograms():void
        {
            throw new Error("Method has to be implemented in subclass!");
        }

        protected function activate(pass:int, context:Context3D, texture:Texture):void
        {
            throw new Error("Method has to be implemented in subclass!");
        }
        
        protected function deactivate(pass:int, context:Context3D, texture:Texture):void
        {
            // clean up resources
        }
        
        protected function assembleAgal(fragmentShader:String, vertexShader:String=null):Program3D
        {
            if (vertexShader == null) vertexShader = STD_VERTEX_SHADER;
            
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
        
        public function get resolution():Number { return mResolution; }
        public function set resolution(value:Number):void { mResolution = value; }
        
        public function get mode():String { return mMode; }
        public function set mode(value:String):void { mMode = value; }
        
        public function get offsetX():Number { return mOffsetX; }
        public function set offsetX(value:Number):void { mOffsetX = value; }
        
        public function get offsetY():Number { return mOffsetY; }
        public function set offsetY(value:Number):void { mOffsetY = value; }
        
        protected function set numPasses(value:int):void { mNumPasses = value; }
        protected function get numPasses():int { return mNumPasses; }
        
        protected function get marginTop():Number { return mMarginTop; }
        protected function set marginTop(value:Number):void { mMarginTop = value; }
        
        protected function get marginBottom():Number { return mMarginBottom; }
        protected function set marginBottom(value:Number):void { mMarginBottom = value; }
        
        protected function get marginLeft():Number { return mMarginLeft; }
        protected function set marginLeft(value:Number):void { mMarginLeft = value; }
        
        protected function get marginRight():Number { return mMarginRight; }
        protected function set marginRight(value:Number):void { mMarginRight = value; }
    }
}