// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix3D;
    import flash.utils.getQualifiedClassName;
    
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.errors.MissingContextError;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.VertexData;
    
    /** Optimizes rendering of a number of quads with an identical state.
     * 
     *  <p>The majority of all rendered objects in Starling are quads. In fact, all the default
     *  leaf nodes of Starling are quads. The rendering of those quads can be accelerated by 
     *  a big factor if all quads with an identical state (i.e. same texture, same smoothing and
     *  mipmapping settings) are sent to the GPU in just one call. That's what the QuadBatch
     *  class can do.</p>
     */ 
    public class QuadBatch
    {
        private var mNumQuads:int;
        private var mCurrentTexture:Texture;
        private var mCurrentSmoothing:String;
        private var mCurrentBlendMode:String;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        private var mIndexData:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;

        /** Helper object. */
        private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
        
        /** Creates a new QuadBatch instance with empty batch data. */
        public function QuadBatch()
        {
            mVertexData = new VertexData(0, true);
            mIndexData = new <uint>[];
            mNumQuads = 0;
        }
        
        /** Disposes vertex- and index-buffer. */
        public function dispose():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
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
            
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();
            
            mVertexBuffer = context.createVertexBuffer(newCapacity * 4, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, newCapacity * 4);
            
            mIndexBuffer = context.createIndexBuffer(newCapacity * 6);
            mIndexBuffer.uploadFromVector(mIndexData, 0, newCapacity * 6);
        }
        
        /** Uploads the raw data of all batched quads to the vertex buffer. */
        public function syncBuffers():void
        {
            // as 3rd parameter, we could also use 'mNumQuads * 4', but on some GPU hardware (iOS!),
            // this is slower than updating the complete buffer.
            
            if (mVertexBuffer)
                mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mVertexData.numVertices);
        }
        
        /** Renders the current batch. Don't forget to call 'syncBuffers' before rendering. */
        public function render(projectionMatrix:Matrix3D, alpha:Number=1.0):void
        {
            if (mNumQuads == 0) return;
            
            var pma:Boolean = mVertexData.premultipliedAlpha;
            var context:Context3D = Starling.context;
            var dynamicAlpha:Boolean = alpha != 1.0;
            
            var program:String = mCurrentTexture ? 
                getImageProgramName(dynamicAlpha, mCurrentTexture.mipMapping, 
                                    mCurrentTexture.repeat, mCurrentSmoothing) : 
                getQuadProgramName(dynamicAlpha);
            
            RenderSupport.setBlendFactors(pma, mCurrentBlendMode);
            registerPrograms();
            
            context.setProgram(Starling.current.getProgram(program));
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_4);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, projectionMatrix, true);            
            
            if (dynamicAlpha)
            {
                sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = pma ? alpha : 1.0;
                sRenderAlpha[3] = alpha;
                context.setProgramConstantsFromVector(
                    Context3DProgramType.FRAGMENT, 0, sRenderAlpha, 1);
            }
            
            if (mCurrentTexture)
            {
                context.setTextureAt(0, mCurrentTexture.base);
                context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            }
            
            context.drawTriangles(mIndexBuffer, 0, mNumQuads * 2);
            
            if (mCurrentTexture)
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
            mCurrentTexture = null;
            mCurrentSmoothing = null;
            mCurrentBlendMode = null;
        }
        
        /** Adds a quad to the current batch. Before adding a quad, you should check for a state
         *  change (with the 'isStateChange' method) and, in case of a change, render the batch. */
        public function addQuad(quad:Quad, alpha:Number, texture:Texture, smoothing:String,
                                modelViewMatrix:Matrix3D, blendMode:String="normal"):void
        {
            if (mNumQuads + 1 > mVertexData.numVertices / 4) expand();
            if (mNumQuads == 0) 
            {
                mCurrentTexture = texture;
                mCurrentSmoothing = smoothing;
                mCurrentBlendMode = blendMode;
                mVertexData.setPremultipliedAlpha(
                    texture ? texture.premultipliedAlpha : true, false); 
            }
            
            var vertexID:int = mNumQuads * 4;
            
            quad.copyVertexDataTo(mVertexData, vertexID);
            alpha *= quad.alpha;
            
            if (alpha != 1.0)
                mVertexData.scaleAlpha(vertexID, alpha, 4);
            
            mVertexData.transformVertex(vertexID, modelViewMatrix, 4);
            
            ++mNumQuads;
        }
        
        /** Indicates if a quad can be added to the batch without causing a state change. 
         *  A state change occurs if the quad uses a different base texture or has a different 
         *  'smoothing', 'repeat' or 'blendMode' setting. */
        public function isStateChange(quad:Quad, texture:Texture, smoothing:String,
                                      blendMode:String):Boolean
        {
            if (mNumQuads == 0) return false;
            else if (mNumQuads == 8192) return true; // maximum buffer size
            else if (mCurrentTexture == null && texture == null) return false;
            else if (mCurrentTexture != null && texture != null)
                return mCurrentTexture.base != texture.base ||
                    mCurrentTexture.repeat != texture.repeat ||
                    mCurrentSmoothing != smoothing ||
                    mCurrentBlendMode != blendMode;
            else return true;
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
            var isRootObject:Boolean = false;
            
            if (quadBatchID == -1)
            {
                isRootObject = true;
                quadBatchID = 0;
                blendMode = object.blendMode == BlendMode.AUTO ? BlendMode.NORMAL : object.blendMode;
                if (quadBatches.length == 0) quadBatches.push(new QuadBatch());
                else quadBatches[0].reset();
            }
            else if (object.alpha == 0.0 || !object.visible)
            {
                return quadBatchID; // ignore transparent objects, except root
            }
            
            if (object is DisplayObjectContainer)
            {
                var container:DisplayObjectContainer = object as DisplayObjectContainer;
                var numChildren:int = container.numChildren;
                var childMatrix:Matrix3D = new Matrix3D();
                
                for (i=0; i<numChildren; ++i)
                {
                    var child:DisplayObject = container.getChildAt(i);
                    var childBlendMode:String = child.blendMode == BlendMode.AUTO ?
                                                blendMode : child.blendMode;
                    childMatrix.copyFrom(transformationMatrix);
                    RenderSupport.transformMatrixForObject(childMatrix, child);
                    quadBatchID = compileObject(child, quadBatches, quadBatchID, childMatrix, 
                                                alpha * child.alpha, childBlendMode);
                }
            }
            else if (object is Quad)
            {
                var quad:Quad = object as Quad;
                var image:Image = quad as Image;
                var texture:Texture = image ? image.texture : null;
                var smoothing:String = image ? image.smoothing : null;
                var quadBatch:QuadBatch = quadBatches[quadBatchID];
                
                if (quadBatch.isStateChange(quad, texture, smoothing, blendMode))
                {
                    quadBatch.syncBuffers();
                    quadBatchID++;
                    if (quadBatches.length <= quadBatchID) 
                        quadBatches.push(new QuadBatch());
                    quadBatch = quadBatches[quadBatchID];
                    quadBatch.reset();
                }
                
                quadBatch.addQuad(quad, alpha, texture, smoothing, transformationMatrix, blendMode);
            }
            else
            {
                throw new Error("Unsupported display object: " + getQualifiedClassName(object));
            }
            
            if (isRootObject)
            {
                quadBatches[quadBatchID].syncBuffers();
                
                for (i=quadBatches.length-1; i>quadBatchID; --i)
                {
                    quadBatches[i].dispose();
                    delete quadBatches[i];
                }
            }
            
            return quadBatchID;
        }
        
        // program management
        
        private static function registerPrograms():void
        {
            var target:Starling = Starling.current;
            if (target.hasProgram(getQuadProgramName(true))) return; // already registered
            
            // create vertex and fragment programs from assembly
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler(); 
            
            var vertexProgramCode:String;
            var fragmentProgramCode:String;
            
            // Each combination of alpha/repeat/mipmap/smoothing has its own fragment shader.
            for each (var dynamicAlpha:Boolean in [true, false])
            {            
                // Quad:
                
                vertexProgramCode = 
                    "m44 op, va0, vc0  \n" +        // 4x4 matrix transform to output clipspace
                    "mov v0, va1       \n";         // pass color to fragment program 
                
                fragmentProgramCode = dynamicAlpha ? 
                    "mul ft0, v0, fc0  \n" +        // multiply alpha (fc0) by color (v0)
                    "mov oc, ft0       \n"          // output color
                  : 
                    "mov oc, v0        \n";         // output color
                                    
                vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode); 
                fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode);
                
                target.registerProgram(getQuadProgramName(dynamicAlpha), 
                    vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
                
                // Image:                
                
                vertexProgramAssembler.assemble(Context3DProgramType.VERTEX,
                    "m44 op, va0, vc0  \n" +        // 4x4 matrix transform to output clipspace
                    "mov v0, va1       \n" +        // pass color to fragment program
                    "mov v1, va2       \n");        // pass texture coordinates to fragment program
                    
                fragmentProgramCode = dynamicAlpha ?
                    "tex ft1, v1, fs0 <???>  \n" +  // sample texture 0
                    "mul ft2, ft1, v0        \n" +  // multiply color with texel color
                    "mul oc, ft2, fc0        \n"    // multiply color with alpha
                  :
                    "tex ft1, v1, fs0 <???>  \n" +  // sample texture 0
                    "mul oc, ft1, v0         \n";   // multiply color with texel color
                
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
                                getImageProgramName(dynamicAlpha, mipmap, repeat, smoothing),
                                vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
                        }
                    }
                }
            }
        }
        
        private static function getQuadProgramName(dynamicAlpha:Boolean):String
        {
            return dynamicAlpha ? "QB_q*" : "QB_q'";
        }
        
        private static function getImageProgramName(dynamicAlpha:Boolean,
                                                    mipMap:Boolean=true, repeat:Boolean=false, 
                                                    smoothing:String="bilinear"):String
        {
            // this method is designed to return most quickly when called with 
            // the default parameters (no-repeat, mipmap, bilinear)
            
            var name:String = dynamicAlpha ? "QB_i*" : "QB_i'";
            
            if (!mipMap) name += "N";
            if (repeat)  name += "R";
            if (smoothing != TextureSmoothing.BILINEAR) name += smoothing.charAt(0);
            
            return name;
        }
    }
}