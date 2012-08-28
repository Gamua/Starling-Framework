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
    import starling.textures.RenderTexture;
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
        private static var sBounds:Rectangle = new Rectangle();
        private static var sMatrix:Matrix = new Matrix();
        
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
            
            // get bounds in stage coordinates
            // can be expensive, so we optimize at least for full-screen effects
            if (object == stage || object == Starling.current.root)
                sBounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
            else
                object.getBounds(stage, sBounds);
            
            var deltaMargin:Number = mResolution == 1.0 ? 0.0 : 1.0 / mResolution; // to avoid hard edges
            sBounds.x -= mMarginLeft + deltaMargin;
            sBounds.y -= mMarginTop  + deltaMargin;
            sBounds.width  += mMarginLeft + mMarginRight  + 2*deltaMargin;
            sBounds.height += mMarginTop  + mMarginBottom + 2*deltaMargin;
            
            sBounds.width  = getNextPowerOfTwo(sBounds.width  * mResolution);
            sBounds.height = getNextPowerOfTwo(sBounds.height * mResolution);
            
            // TODO: intersect with stage bounds & set scissor rectangle accordingly
            updatePassTextures(sBounds.width, sBounds.height);
            
            // update the vertices that span up the filter rectangle 
            updateBuffers(context, sBounds.width, sBounds.height);
            
            // draw the original object into a render texture
            renderBaseTexture(object, parentAlpha, sBounds.x, sBounds.y);
            
            // now prepare filter passes
            support.finishQuadBatch();
            support.raiseDrawCount(mNumPasses+1);
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
                    context.setRenderToTexture(getPassTexture(i+1).base);
                    RenderSupport.clear();
                }
                else // final pass -- draw into back buffer, at original position
                {
                    context.setRenderToBackBuffer();
                    support.projectionMatrix.copyFrom(sMatrix); // restore projection matrix
                    support.translateMatrix(sBounds.x + mOffsetX, sBounds.y + mOffsetY);
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
        
        private function renderBaseTexture(object:DisplayObject, parentAlpha:Number, 
                                           offsetX:Number, offsetY:Number):void
        {
            // move object to top left
            object.getTransformationMatrix(object.stage, sMatrix);
            sMatrix.translate(-offsetX, -offsetY);
            sMatrix.scale(mResolution, mResolution);
            
            var basePassTexture:RenderTexture = mPassTextures[0] as RenderTexture;
            basePassTexture.draw(object, sMatrix, parentAlpha);
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
                
                var scale:Number = Starling.contentScaleFactor; 
                mPassTextures[0] = new RenderTexture(width, height, false, scale);
                
                for (var i:int=1; i<numPassTextures; ++i)
                    mPassTextures[i] = Texture.empty(width, height, PMA, true, scale);
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