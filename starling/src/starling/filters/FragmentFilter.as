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
    import starling.core.starling_internal;
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.QuadBatch;
    import starling.display.Stage;
    import starling.errors.AbstractClassError;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;
    import starling.utils.VertexData;
    import starling.utils.getNextPowerOfTwo;

    /** The FragmentFilter class is the base class for all filter effects.
     *  
     *  <p>All other filters of this package extend this class. You can attach them to any display
     *  object through the 'filter' property.</p>
     *  
     *  <p>Create your own filters by extending this class.</p>
     */ 
    public class FragmentFilter
    {
        protected const PMA:Boolean = true;
        protected const STD_VERTEX_SHADER:String = 
            "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
            "mov v0, va1      \n";  // pass texture coordinates to fragment program
        protected const STD_FRAGMENT_SHADER:String =
            "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
        
        /** The ID of the vertex buffer attribute storing the vertex position. */ 
        protected var mVertexPosAtID:int = 0;
        
        /** The ID of the vertex buffer attribute storing the texture coordinates. */
        protected var mTexCoordsAtID:int = 1;
        
        /** The ID (sampler) of the input texture (containing the output of the previous pass). */
        protected var mBaseTextureID:int = 0;
        
        /** The ID of the first register of the MVP matrix constant (a 4x4 matrix). */ 
        protected var mMvpConstantID:int = 0;
        
        private var mNumPasses:int;
        private var mPassTextures:Vector.<Texture>;

        private var mMode:String;
        private var mResolution:Number;
        private var mMarginX:Number;
        private var mMarginY:Number;
        private var mOffsetX:Number;
        private var mOffsetY:Number;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
        private var mCacheRequested:Boolean;
        private var mCache:QuadBatch;
        
        /** helper objects. */
        private var mProjMatrix:Matrix = new Matrix();
        private static var sBounds:Rectangle  = new Rectangle();
        private static var sStageBounds:Rectangle = new Rectangle();
        private static var sTransformationMatrix:Matrix = new Matrix();
        
        public function FragmentFilter(numPasses:int=1, resolution:Number=1.0)
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.filters::FragmentFilter")
            {
                throw new AbstractClassError();
            }
            
            if (numPasses < 1) throw new ArgumentError("At least one pass is required.");
            
            mNumPasses = numPasses;
            mMarginX = mMarginY = 0.0;
            mOffsetX = mOffsetY = 0;
            mResolution = resolution;
            mMode = FragmentFilterMode.REPLACE;
            
            mVertexData = new VertexData(4);
            mVertexData.setTexCoords(0, 0, 0);
            mVertexData.setTexCoords(1, 1, 0);
            mVertexData.setTexCoords(2, 0, 1);
            mVertexData.setTexCoords(3, 1, 1);
            
            mIndexData = new <uint>[0, 1, 2, 1, 3, 2];
            mIndexData.fixed = true;
            
            createPrograms();
            
            // Handle lost context. By using the conventional event, we can make it weak; this  
            // avoids memory leaks when people forget to call "dispose" on the filter.
            Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
                onContextCreated, false, 0, true);
        }
        
        public function dispose():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            disposePassTextures();
            disposeCache();
        }
        
        private function onContextCreated(event:Object):void
        {
            mVertexBuffer = null;
            mIndexBuffer  = null;
            mPassTextures = null;
            
            createPrograms();
        }
        
        public function render(object:DisplayObject, support:RenderSupport, parentAlpha:Number):void
        {
            // bottom layer
            
            if (mode == FragmentFilterMode.ABOVE)
                object.render(support, parentAlpha);
            
            // center layer
            
            if (mCacheRequested)
            {
                mCacheRequested = false;
                mCache = renderPasses(object, support, 1.0, true);
                disposePassTextures();
            }
            
            if (mCache)
                mCache.render(support, parentAlpha);
            else
                renderPasses(object, support, parentAlpha, false);
            
            // top layer
            
            if (mode == FragmentFilterMode.BELOW)
                object.render(support, parentAlpha);
        }
        
        private function renderPasses(object:DisplayObject, support:RenderSupport, 
                                      parentAlpha:Number, intoCache:Boolean=false):QuadBatch
        {
            var cacheTexture:Texture = null;
            var stage:Stage = object.stage;
            var context:Context3D = Starling.context;
            var scale:Number = Starling.current.contentScaleFactor;
            
            if (stage   == null) throw new Error("Filtered object must be on the stage.");
            if (context == null) throw new MissingContextError();
            
            // the bounds of the object in stage coordinates 
            calculateBounds(object, stage, !intoCache, sBounds);
            
            if (sBounds.isEmpty())
            {
                disposePassTextures();
                return intoCache ? new QuadBatch() : null; 
            }
            
            updateBuffers(context, sBounds);
            updatePassTextures(sBounds.width, sBounds.height, mResolution * scale);

            support.finishQuadBatch();
            support.raiseDrawCount(mNumPasses);
            support.pushMatrix();
            
            // save original projection matrix and render target
            mProjMatrix.copyFrom(support.projectionMatrix); 
            var previousRenderTarget:Texture = support.renderTarget;
            
            if (previousRenderTarget)
                throw new IllegalOperationError(
                    "It's currently not possible to stack filters! " +
                    "This limitation will be removed in a future Stage3D version.");
            
            if (intoCache) 
                cacheTexture = Texture.empty(sBounds.width, sBounds.height, PMA, true, 
                                             mResolution * scale);
            
            // draw the original object into a texture
            support.renderTarget = mPassTextures[0];
            support.clear();
            support.blendMode = BlendMode.NORMAL;
            support.setOrthographicProjection(sBounds.x, sBounds.y, sBounds.width, sBounds.height);
            object.render(support, parentAlpha);
            support.finishQuadBatch();
            
            // prepare drawing of actual filter passes
            RenderSupport.setBlendFactors(PMA);
            support.loadIdentity();  // now we'll draw in stage coordinates!
            
            context.setVertexBufferAt(mVertexPosAtID, mVertexBuffer, VertexData.POSITION_OFFSET, 
                                      Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(mTexCoordsAtID, mVertexBuffer, VertexData.TEXCOORD_OFFSET,
                                      Context3DVertexBufferFormat.FLOAT_2);
            
            // draw all passes
            for (var i:int=0; i<mNumPasses; ++i)
            {
                if (i < mNumPasses - 1) // intermediate pass  
                {
                    // draw into pass texture
                    support.renderTarget = getPassTexture(i+1);
                    support.clear();
                }
                else // final pass
                {
                    if (intoCache)
                    {
                        // draw into cache texture
                        support.renderTarget = cacheTexture;
                        support.clear();
                    }
                    else
                    {
                        // draw into back buffer, at original (stage) coordinates
                        support.renderTarget = previousRenderTarget;
                        support.projectionMatrix.copyFrom(mProjMatrix); // restore projection matrix
                        support.translateMatrix(mOffsetX, mOffsetY);
                        support.blendMode = object.blendMode;
                        support.applyBlendMode(PMA);
                    }
                }
                
                var passTexture:Texture = getPassTexture(i);
                
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, mMvpConstantID, 
                                                      support.mvpMatrix3D, true);
                context.setTextureAt(mBaseTextureID, passTexture.base);
                
                activate(i, context, passTexture);
                context.drawTriangles(mIndexBuffer, 0, 2);
                deactivate(i, context, passTexture);
            }
            
            // reset shader attributes
            context.setVertexBufferAt(mVertexPosAtID, null);
            context.setVertexBufferAt(mTexCoordsAtID, null);
            context.setTextureAt(mBaseTextureID, null);
            
            support.popMatrix();
            
            if (intoCache)
            {
                // restore support settings
                support.renderTarget = previousRenderTarget;
                support.projectionMatrix.copyFrom(mProjMatrix);
                
                // Create an image containing the cache. To have a display object that contains
                // the filter output in object coordinates, we wrap it in a QuadBatch: that way,
                // we can modify it with a transformation matrix.
                
                var quadBatch:QuadBatch = new QuadBatch();
                var image:Image = new Image(cacheTexture);
                
                stage.getTransformationMatrix(object, sTransformationMatrix);
                MatrixUtil.prependTranslation(sTransformationMatrix, 
                                              sBounds.x + mOffsetX, sBounds.y + mOffsetY);
                quadBatch.addImage(image, 1.0, sTransformationMatrix);

                return quadBatch;
            }
            else return null;
        }
        
        // helper methods
        
        private function updateBuffers(context:Context3D, bounds:Rectangle):void
        {
            mVertexData.setPosition(0, bounds.x, bounds.y);
            mVertexData.setPosition(1, bounds.right, bounds.y);
            mVertexData.setPosition(2, bounds.x, bounds.bottom);
            mVertexData.setPosition(3, bounds.right, bounds.bottom);
            
            if (mVertexBuffer == null)
            {
                mVertexBuffer = context.createVertexBuffer(4, VertexData.ELEMENTS_PER_VERTEX);
                mIndexBuffer  = context.createIndexBuffer(6);
                mIndexBuffer.uploadFromVector(mIndexData, 0, 6);
            }
            
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, 4);
        }
        
        private function updatePassTextures(width:int, height:int, scale:Number):void
        {
            var numPassTextures:int = mNumPasses > 1 ? 2 : 1;
            
            var needsUpdate:Boolean = mPassTextures == null || 
                mPassTextures.length != numPassTextures ||
                mPassTextures[0].width != width || mPassTextures[0].height != height;  
            
            if (needsUpdate)
            {
                if (mPassTextures)
                {
                    for each (var texture:Texture in mPassTextures) 
                        texture.dispose();
                    
                    mPassTextures.length = numPassTextures;
                }
                else
                {
                    mPassTextures = new Vector.<Texture>(numPassTextures);
                }
                
                for (var i:int=0; i<numPassTextures; ++i)
                    mPassTextures[i] = Texture.empty(width, height, PMA, true, scale);
            }
        }
        
        private function getPassTexture(pass:int):Texture
        {
            return mPassTextures[pass % 2];
        }
        
        /** Calculates the bounds of the filter in stage coordinates, making sure that the 
         *  according textures will have powers of two. */
        private function calculateBounds(object:DisplayObject, stage:Stage, 
                                         intersectWithStage:Boolean, resultRect:Rectangle):void
        {
            // optimize for full-screen effects
            if (object == stage || object == Starling.current.root)
                resultRect.setTo(0, 0, stage.stageWidth, stage.stageHeight);
            else
                object.getBounds(stage, resultRect);
            
            if (intersectWithStage)
            {
                sStageBounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
                RectangleUtil.intersect(sBounds, sStageBounds, sBounds);
            }
            
            if (!resultRect.isEmpty())
            {    
                // the bounds are a rectangle around the object, in stage coordinates,
                // and with an optional margin. To fit into a POT-texture, it will grow towards
                // the right and bottom.
                var deltaMargin:Number = mResolution == 1.0 ? 0.0 : 1.0 / mResolution; // avoid hard edges
                resultRect.x -= mMarginX + deltaMargin;
                resultRect.y -= mMarginY + deltaMargin;
                resultRect.width  += 2 * (mMarginX + deltaMargin);
                resultRect.height += 2 * (mMarginY + deltaMargin);
                resultRect.width  = getNextPowerOfTwo(resultRect.width  * mResolution) / mResolution;
                resultRect.height = getNextPowerOfTwo(resultRect.height * mResolution) / mResolution;
            }
        }
        
        private function disposePassTextures():void
        {
            for each (var texture:Texture in mPassTextures)
                texture.dispose();
            
            mPassTextures = null;
        }
        
        private function disposeCache():void
        {
            if (mCache)
            {
                if (mCache.texture) mCache.texture.dispose();
                mCache.dispose();
                mCache = null;
            }
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
        
        protected function assembleAgal(fragmentShader:String=null, vertexShader:String=null):Program3D
        {
            if (fragmentShader == null) fragmentShader = STD_FRAGMENT_SHADER;
            if (vertexShader   == null) vertexShader   = STD_VERTEX_SHADER;
            
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexShader);
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader);
            
            var context:Context3D = Starling.context;
            var program:Program3D = context.createProgram();
            program.upload(vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);          
            
            return program;
        }
        
        // cache
        
        public function cache():void
        {
            mCacheRequested = true;
            disposeCache();
        }
        
        public function clearCache():void
        {
            mCacheRequested = false;
            disposeCache();
        }
        
        // flattening
        
        /** @private */
        starling_internal function compile(object:DisplayObject):QuadBatch
        {
            if (mCache) return mCache;
            else
            {
                var renderSupport:RenderSupport;
                var stage:Stage = object.stage;
                
                if (stage == null) 
                    throw new Error("Filtered object must be on the stage.");
                
                renderSupport = new RenderSupport();
                object.getTransformationMatrix(stage, renderSupport.modelViewMatrix);
                return renderPasses(object, renderSupport, 1.0, true);
            }
        }
        
        // properties
        
        public function get isCached():Boolean { return mCache || mCacheRequested; }
        
        public function get resolution():Number { return mResolution; }
        public function set resolution(value:Number):void 
        {
            if (value <= 0) throw new ArgumentError("Resolution must be > 0");
            else mResolution = value; 
        }
        
        public function get mode():String { return mMode; }
        public function set mode(value:String):void { mMode = value; }
        
        public function get offsetX():Number { return mOffsetX; }
        public function set offsetX(value:Number):void { mOffsetX = value; }
        
        public function get offsetY():Number { return mOffsetY; }
        public function set offsetY(value:Number):void { mOffsetY = value; }
        
        protected function get marginX():Number { return mMarginX; }
        protected function set marginX(value:Number):void { mMarginX = value; }
        
        protected function get marginY():Number { return mMarginY; }
        protected function set marginY(value:Number):void { mMarginY = value; }
        
        protected function set numPasses(value:int):void { mNumPasses = value; }
        protected function get numPasses():int { return mNumPasses; }
    }
}