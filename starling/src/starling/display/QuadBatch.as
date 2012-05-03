// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Matrix3D;
    import flash.geom.Rectangle;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.core.starling_internal;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.VertexData;
    
    use namespace starling_internal;
    
    /** Optimizes rendering of a number of quads with an identical state.
     * 
     *  <p>The majority of all rendered objects in Starling are quads. In fact, all the default
     *  leaf nodes of Starling are quads (the Image and Quad classes). The rendering of those 
     *  quads can be accelerated by a big factor if all quads with an identical state are sent 
     *  to the GPU in just one call. That's what the QuadBatch class can do.</p>
     *  
     *  <p>The 'flatten' method of the Sprite class uses this class internally to optimize its 
     *  rendering performance. In most situations, it is recommended to stick with flattened
     *  sprites, because they are easier to use. Sometimes, however, it makes sense
     *  to use the QuadBatch class directly: e.g. you can add one quad multiple times to 
     *  a quad batch, whereas you can only add it once to a sprite. Furthermore, this class
     *  does not dispatch <code>ADDED</code> or <code>ADDED_TO_STAGE</code> events when a quad
     *  is added, which makes it more lightweight.</p>
     *  
     *  <p>One QuadBatch object is bound to a specific render state. The first object you add to a 
     *  batch will decide on the QuadBatch's state, that is: its texture, its settings for 
     *  smoothing and blending, and if it's tinted (colored vertices and/or transparency). 
     *  When you reset the batch, it will accept a new state on the next added quad.</p> 
     *  
     *  <p>The class extends DisplayObject, but you can use it even without adding it to the
     *  display tree. Just call the 'renderCustom' method from within another render method,
     *  and pass appropriate values for transformation matrix, alpha and blend mode.</p>
     *
     *  @see Sprite  
     */ 
    public class QuadBatch extends DisplayObject
    {
        private static const QUAD_PROGRAM_NAME:String = "QB_q";
        
        private var mNumQuads:int;
        private var mSyncRequired:Boolean;

        private var mTinted:Boolean;
        private var mTexture:Texture;
        private var mSmoothing:String;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;

        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperMatrix3D:Matrix3D = new Matrix3D();
        private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
        
        /** Creates a new QuadBatch instance with empty batch data. */
        public function QuadBatch()
        {
            mVertexData = new VertexData(0, true);
            mIndexData = new <uint>[];
            mNumQuads = 0;
            mTinted = false;
            mSyncRequired = false;
            
            // handle lost context
            Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
        }
        
        /** Disposes vertex- and index-buffer. */
        public override function dispose():void
        {
            Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            super.dispose();
        }
        
        private function onContextCreated(event:Event):void
        {
            createBuffers();
            registerPrograms();
        }
        
        /** Creates a duplicate of the QuadBatch object. */
        public function clone():QuadBatch
        {
            var clone:QuadBatch = new QuadBatch();
            clone.mVertexData = mVertexData.clone(0, mNumQuads * 4);
            clone.mIndexData = mIndexData.slice(0, mNumQuads * 6);
            clone.mNumQuads = mNumQuads;
            clone.mTinted = mTinted;
            clone.mTexture = mTexture;
            clone.mSmoothing = mSmoothing;
            clone.mSyncRequired = true;
            clone.blendMode = this.blendMode;
            return clone;
        }
        
        private function expand():void
        {
            var oldCapacity:int = mVertexData.numVertices / 4;
            var newCapacity:int = oldCapacity == 0 ? 16 : oldCapacity * 2;
            mVertexData.numVertices = newCapacity * 4;
            
            for (var i:int=oldCapacity; i<newCapacity; ++i)
            {
                mIndexData[int(i*6  )] = i*4;
                mIndexData[int(i*6+1)] = i*4 + 1;
                mIndexData[int(i*6+2)] = i*4 + 2;
                mIndexData[int(i*6+3)] = i*4 + 1;
                mIndexData[int(i*6+4)] = i*4 + 3;
                mIndexData[int(i*6+5)] = i*4 + 2;
            }
            
            createBuffers();
            registerPrograms();
        }
        
        private function createBuffers():void
        {
            var numVertices:int = mVertexData.numVertices;
            var numIndices:int = mIndexData.length;
            var context:Context3D = Starling.context;

            if (mVertexBuffer)    mVertexBuffer.dispose();
            if (mIndexBuffer)     mIndexBuffer.dispose();
            if (mNumQuads == 0)   return;
            if (context == null)  throw new MissingContextError();
            
            mVertexBuffer = context.createVertexBuffer(numVertices, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, numVertices);
            
            mIndexBuffer = context.createIndexBuffer(numIndices);
            mIndexBuffer.uploadFromVector(mIndexData, 0, numIndices);
            
            mSyncRequired = false;
        }
        
        /** Uploads the raw data of all batched quads to the vertex buffer. */
        private function syncBuffers():void
        {
            if (mVertexBuffer == null)
                createBuffers();
            else
            {
                // as 3rd parameter, we could also use 'mNumQuads * 4', but on some GPU hardware (iOS!),
                // this is slower than updating the complete buffer.
                
                mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);
                mSyncRequired = false;
            }
        }
        
        /** Renders the current batch with custom settings for model-view-projection matrix, alpha 
         *  and blend mode. This makes it possible to render batches that are not part of the 
         *  display list. */ 
        public function renderCustom(mvpMatrix:Matrix3D, parentAlpha:Number=1.0,
                                     blendMode:String=null):void
        {
            if (mNumQuads == 0) return;
            if (mSyncRequired) syncBuffers();
            
            var pma:Boolean = mVertexData.premultipliedAlpha;
            var context:Context3D = Starling.context;
            var tinted:Boolean = mTinted || (parentAlpha != 1.0);
            var programName:String = mTexture ? 
                getImageProgramName(tinted, mTexture.mipMapping, mTexture.repeat, mSmoothing) : 
                QUAD_PROGRAM_NAME;
            
            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = pma ? parentAlpha : 1.0;
            sRenderAlpha[3] = parentAlpha;
            
            RenderSupport.setBlendFactors(pma, blendMode ? blendMode : this.blendMode);
            
            context.setProgram(Starling.current.getProgram(programName));
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, sRenderAlpha, 1);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, mvpMatrix, true);
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, 
                                      Context3DVertexBufferFormat.FLOAT_3); 
            
            if (mTexture == null || tinted)
                context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, 
                                          Context3DVertexBufferFormat.FLOAT_4);
            
            if (mTexture)
            {
                context.setTextureAt(0, mTexture.base);
                context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, 
                                          Context3DVertexBufferFormat.FLOAT_2);
            }
            
            context.drawTriangles(mIndexBuffer, 0, mNumQuads * 2);
            
            if (mTexture)
            {
                context.setTextureAt(0, null);
                context.setVertexBufferAt(2, null);
            }
            
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(0, null);
        }
        
        /** Resets the batch. The vertex- and index-buffers remain their size, so that they
         *  can be reused quickly. */  
        public function reset():void
        {
            mNumQuads = 0;
            mTexture = null;
            mSmoothing = null;
            mSyncRequired = true;
        }
        
        /** Adds an image to the batch. This method internally calls 'addQuad' with the correct
         *  parameters for 'texture' and 'smoothing'. */ 
        public function addImage(image:Image, parentAlpha:Number=1.0, modelViewMatrix:Matrix3D=null,
                                 blendMode:String=null):void
        {
            addQuad(image, parentAlpha, image.texture, image.smoothing, modelViewMatrix, blendMode);
        }
        
        /** Adds a quad to the batch. The first quad determines the state of the batch,
         *  i.e. the values for texture, smoothing and blendmode. When you add additional quads,  
         *  make sure they share that state (e.g. with the 'isStageChange' method), or reset
         *  the batch. */ 
        public function addQuad(quad:Quad, parentAlpha:Number=1.0, texture:Texture=null, 
                                smoothing:String=null, modelViewMatrix:Matrix3D=null, 
                                blendMode:String=null):void
        {
            if (modelViewMatrix == null)
            {
                modelViewMatrix = sHelperMatrix3D;
                modelViewMatrix.identity();
                RenderSupport.transformMatrixForObject(modelViewMatrix, quad);
            }
            
            var tinted:Boolean = texture ? (quad.tinted || parentAlpha != 1.0) : false;
            var alpha:Number = parentAlpha * quad.alpha;
            var vertexID:int = mNumQuads * 4;
            
            if (mNumQuads + 1 > mVertexData.numVertices / 4) expand();
            if (mNumQuads == 0) 
            {
                this.blendMode = blendMode ? blendMode : quad.blendMode;
                mTexture = texture;
                mTinted = tinted;
                mSmoothing = smoothing;
                mVertexData.setPremultipliedAlpha(
                    texture ? texture.premultipliedAlpha : true, false); 
            }
            
            quad.copyVertexDataTo(mVertexData, vertexID);
            
            if (alpha != 1.0)
                mVertexData.scaleAlpha(vertexID, alpha, 4);
            
            mVertexData.transformVertex(vertexID, modelViewMatrix, 4);

            mSyncRequired = true;
            mNumQuads++;
        }
        
        /** Indicates if a quad can be added to the batch without causing a state change. 
         *  A state change occurs if the quad uses a different base texture or has a different 
         *  'smoothing', 'repeat' or 'blendMode' setting. */
        public function isStateChange(quad:Quad, parentAlpha:Number, texture:Texture, 
                                      smoothing:String, blendMode:String):Boolean
        {
            if (mNumQuads == 0) return false;
            else if (mNumQuads == 8192) return true; // maximum buffer size
            else if (mTexture == null && texture == null) return false;
            else if (mTexture != null && texture != null)
                return mTexture.base != texture.base ||
                       mTexture.repeat != texture.repeat ||
                       mSmoothing != smoothing ||
                       mTinted != (quad.tinted || parentAlpha != 1.0) ||
                       this.blendMode != blendMode;
            else return true;
        }
        
        // display object methods
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var transformationMatrix:Matrix = targetSpace == this ?
                null : getTransformationMatrix(targetSpace, sHelperMatrix);
            
            return mVertexData.getBounds(transformationMatrix, 0, mNumQuads*4, resultRect);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.finishQuadBatch();
            renderCustom(support.mvpMatrix, alpha * parentAlpha, support.blendMode);
        }
        
        // compilation (for flattened sprites)
        
        /** Analyses a container object that is made up exclusively of quads (or other containers)
         *  and creates a vector of QuadBatch objects representing the container. This can be
         *  used to render the container very efficiently. The 'flatten'-method of the Sprite 
         *  class uses this method internally. */
        public static function compile(container:DisplayObjectContainer, 
                                       quadBatches:Vector.<QuadBatch>):void
        {
            compileObject(container, quadBatches, -1, new Matrix3D());
        }
        
        private static function compileObject(object:DisplayObject, 
                                              quadBatches:Vector.<QuadBatch>,
                                              quadBatchID:int,
                                              transformationMatrix:Matrix3D,
                                              alpha:Number=1.0,
                                              blendMode:String=null):int
        {
            var i:int;
            var quadBatch:QuadBatch;
            var isRootObject:Boolean = false;
            var objectAlpha:Number = object.alpha;
            
            if (quadBatchID == -1)
            {
                isRootObject = true;
                quadBatchID = 0;
                objectAlpha = 1.0;
                blendMode = object.blendMode;
                if (quadBatches.length == 0) quadBatches.push(new QuadBatch());
                else quadBatches[0].reset();
            }
            
            if (object is DisplayObjectContainer)
            {
                var container:DisplayObjectContainer = object as DisplayObjectContainer;
                var numChildren:int = container.numChildren;
                var childMatrix:Matrix3D = new Matrix3D();
                
                for (i=0; i<numChildren; ++i)
                {
                    var child:DisplayObject = container.getChildAt(i);
                    var childVisible:Boolean = child.alpha  != 0.0 && child.visible && 
                                               child.scaleX != 0.0 && child.scaleY != 0.0;
                    if (childVisible)
                    {
                        var childBlendMode:String = child.blendMode == BlendMode.AUTO ?
                                                    blendMode : child.blendMode;
                        childMatrix.copyFrom(transformationMatrix);
                        RenderSupport.transformMatrixForObject(childMatrix, child);
                        quadBatchID = compileObject(child, quadBatches, quadBatchID, childMatrix, 
                                                    alpha*objectAlpha, childBlendMode);
                    }
                }
            }
            else if (object is Quad)
            {
                var quad:Quad = object as Quad;
                var image:Image = quad as Image;
                var texture:Texture = image ? image.texture : null;
                var smoothing:String = image ? image.smoothing : null;
                
                quadBatch = quadBatches[quadBatchID];
                
                if (quadBatch.isStateChange(quad, alpha*objectAlpha, texture, smoothing, blendMode))
                {
                    quadBatchID++;
                    if (quadBatches.length <= quadBatchID) 
                        quadBatches.push(new QuadBatch());
                    quadBatch = quadBatches[quadBatchID];
                    quadBatch.reset();
                }
                
                quadBatch.addQuad(quad, alpha, texture, smoothing, transformationMatrix, blendMode);
            }
            else if (object is QuadBatch)
            {
                if (quadBatches[quadBatchID].mNumQuads > 0)
                    quadBatchID++;
                
                quadBatch = (object as QuadBatch).clone();
                quadBatch.blendMode = blendMode;
                quadBatch.mVertexData.transformVertex(0, transformationMatrix, -1);
                quadBatches.splice(quadBatchID, 0, quadBatch); 
            }
            else
            {
                throw new Error("Unsupported display object: " + getQualifiedClassName(object));
            }
            
            if (isRootObject)
            {
                // remove unused batches
                for (i=quadBatches.length-1; i>quadBatchID; --i)
                    quadBatches.pop().dispose();
                
                // last quadbatch could be empty
                if (quadBatches[quadBatches.length-1].mNumQuads == 0)
                    quadBatches.pop().dispose();
            }
            
            return quadBatchID;
        }
        
        // properties
        
        public function get numQuads():int { return mNumQuads; }
        
        // program management
        
        private static function registerPrograms():void
        {
            var target:Starling = Starling.current;
            if (target.hasProgram(QUAD_PROGRAM_NAME)) return; // already registered
            
            // create vertex and fragment programs from assembly
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            
            var vertexProgramCode:String;
            var fragmentProgramCode:String;
            
            // this is the input data we'll pass to the shaders:
            // 
            // va0 -> position
            // va1 -> color
            // va2 -> texCoords
            // vc0 -> alpha
            // vc1 -> mvpMatrix
            // fs0 -> texture
            
            // Quad:
            
            vertexProgramCode =
                "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                "mul v0, va1, vc0 \n";  // multiply alpha (vc0) with color (va1)
            
            fragmentProgramCode =
                "mov oc, v0       \n";  // output color
            
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode);
            
            target.registerProgram(QUAD_PROGRAM_NAME,
                vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
            
            // Image:
            // Each combination of tinted/repeat/mipmap/smoothing has its own fragment shader.
            
            for each (var tinted:Boolean in [true, false])
            {
                vertexProgramCode = tinted ?
                    "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                    "mul v0, va1, vc0 \n" + // multiply alpha (vc0) with color (va1)
                    "mov v1, va2      \n"   // pass texture coordinates to fragment program
                  :
                    "m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
                    "mov v1, va2      \n";  // pass texture coordinates to fragment program
                    
                vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
                
                fragmentProgramCode = tinted ?
                    "tex ft1,  v1, fs0 <???> \n" + // sample texture 0
                    "mul  oc, ft1,  v0       \n"   // multiply color with texel color
                  :
                    "tex  oc,  v1, fs0 <???> \n";  // sample texture 0
                
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
                            
                            target.registerProgram(
                                getImageProgramName(tinted, mipmap, repeat, smoothing),
                                vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
                        }
                    }
                }
            }
        }
        
        private static function getImageProgramName(tinted:Boolean,
                                                    mipMap:Boolean=true, repeat:Boolean=false,
                                                    smoothing:String="bilinear"):String
        {
            // this method is designed to return most quickly when called with
            // the default parameters (no-repeat, mipmap, bilinear)
            
            var name:String = tinted ? "QB_i*" : "QB_i'";
            
            if (!mipMap) name += "N";
            if (repeat)  name += "R";
            if (smoothing != TextureSmoothing.BILINEAR) name += smoothing.charAt(0);
            
            return name;
        }
    }
}