// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.errors.IllegalOperationError;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.getQualifiedClassName;

    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.MeshBatch;
    import starling.display.Stage;
    import starling.errors.AbstractClassError;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.rendering.IndexData;
    import starling.rendering.Painter;
    import starling.rendering.RenderState;
    import starling.rendering.VertexData;
    import starling.textures.Texture;
    import starling.utils.MathUtil;
    import starling.utils.MatrixUtil;
    import starling.utils.RectangleUtil;
    import starling.utils.SystemUtil;

    /** The FragmentFilter class is the base class for all filter effects in Starling.
     *  All other filters of this package extend this class. You can attach them to any display
     *  object through the 'filter' property.
     * 
     *  <p>A fragment filter works in the following way:</p>
     *  <ol>
     *    <li>The object that is filtered is rendered into a texture (in stage coordinates).</li>
     *    <li>That texture is passed to the first filter pass.</li>
     *    <li>Each pass processes the texture using a fragment shader (and optionally a vertex 
     *        shader) to achieve a certain effect.</li>
     *    <li>The output of each pass is used as the input for the next pass; if it's the 
     *        final pass, it will be rendered directly to the back buffer.</li>  
     *  </ol>
     * 
     *  <p>All of this is set up by the abstract FragmentFilter class. Concrete subclasses
     *  just need to override the protected methods 'createPrograms', 'activate' and 
     *  (optionally) 'deactivate' to create and execute its custom shader code. Each filter
     *  can be configured to either replace the original object, or be drawn below or above it.
     *  This can be done through the 'mode' property, which accepts one of the Strings defined
     *  in the 'FragmentFilterMode' class.</p>
     * 
     *  <p>Beware that each filter should be used only on one object at a time. Otherwise, it
     *  will get slower and require more resources; and caching will lead to undefined
     *  results.</p>
     */ 
    public class FragmentFilter
    {
        /** The minimum size of a filter texture. */
        private const MIN_TEXTURE_SIZE:int = 64;
        
        /** All filter processing is expected to be done with premultiplied alpha. */
        protected const PMA:Boolean = true;
        
        /** The standard vertex shader code. It will be used automatically if you don't create
         *  a custom vertex shader yourself. */
        protected const STD_VERTEX_SHADER:String = 
            "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
            "mov v0, va1      \n";  // pass texture coordinates to fragment program
        
        /** The standard fragment shader code. It just forwards the texture color to the output. */
        protected const STD_FRAGMENT_SHADER:String =
            "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
        
        private var _vertexPosAtID:int = 0;
        private var _texCoordsAtID:int = 1;
        private var _baseTextureID:int = 0;
        private var _mvpConstantID:int = 0;
        
        private var _numPasses:int;
        private var _passTextures:Vector.<Texture>;

        private var _mode:String;
        private var _resolution:Number;
        private var _marginX:Number;
        private var _marginY:Number;
        private var _offsetX:Number;
        private var _offsetY:Number;
        
        private var _vertexData:VertexData;
        private var _vertexBuffer:VertexBuffer3D;
        private var _indexData:IndexData;
        private var _indexBuffer:IndexBuffer3D;
        
        private var _cacheRequested:Boolean;
        private var _cache:MeshBatch;
        
        /** Helper objects. */
        private static var sStageBounds:Rectangle = new Rectangle();
        private static var sTransformationMatrix:Matrix = new Matrix();
        
        /** Helper objects that may be used recursively (thus not static). */
        private var _helperMatrix:Matrix     = new Matrix();
        private var _helperRect:Rectangle    = new Rectangle();
        private var _helperRect2:Rectangle   = new Rectangle();

        /** Creates a new Fragment filter with the specified number of passes and resolution.
         *  This constructor may only be called by the constructor of a subclass. */
        public function FragmentFilter(numPasses:int=1, resolution:Number=1.0)
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.filters::FragmentFilter")
            {
                throw new AbstractClassError();
            }
            
            if (numPasses < 1) throw new ArgumentError("At least one pass is required.");
            
            _numPasses = numPasses;
            _marginX = _marginY = 0.0;
            _offsetX = _offsetY = 0;
            _resolution = resolution;
            _passTextures = new <Texture>[];
            _mode = FragmentFilterMode.REPLACE;

            _vertexData = new VertexData("position(float2), texCoords(float2)", 4);
            _vertexData.setPoint(0, "texCoords", 0, 0);
            _vertexData.setPoint(1, "texCoords", 1, 0);
            _vertexData.setPoint(2, "texCoords", 0, 1);
            _vertexData.setPoint(3, "texCoords", 1, 1);
            
            _indexData = new IndexData(6);
            _indexData.appendQuad(0, 1, 2, 3);

            if (Starling.current.contextValid)
                createPrograms();
            
            // Handle lost context. By using the conventional event, we can make it weak; this  
            // avoids memory leaks when people forget to call "dispose" on the filter.
            Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
                onContextCreated, false, 0, true);
        }
        
        /** Disposes the filter (programs, buffers, textures). */
        public function dispose():void
        {
            Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            if (_vertexBuffer) _vertexBuffer.dispose();
            if (_indexBuffer)  _indexBuffer.dispose();
            disposePassTextures();
            disposeCache();
        }
        
        private function onContextCreated(event:Object):void
        {
            _vertexBuffer = null;
            _indexBuffer  = null;

            disposePassTextures();
            createPrograms();
            if (_cache) cache();
        }
        
        /** Applies the filter on a certain display object, rendering the output into the current 
         *  render target. This method is called automatically by Starling's rendering system 
         *  for the object the filter is attached to. */
        public function render(object:DisplayObject, painter:Painter):void
        {
            // bottom layer
            
            if (mode == FragmentFilterMode.ABOVE)
                object.render(painter);
            
            // center layer
            
            if (_cacheRequested)
            {
                _cacheRequested = false;
                _cache = renderPasses(object, painter, true);
                disposePassTextures();
            }
            
            if (_cache)
                _cache.render(painter);
            else
                renderPasses(object, painter, false);
            
            // top layer
            
            if (mode == FragmentFilterMode.BELOW)
                object.render(painter);
        }
        
        private function renderPasses(object:DisplayObject, painter:Painter,
                                      intoCache:Boolean=false):MeshBatch
        {
            var passTexture:Texture;
            var cacheTexture:Texture = null;
            var context:Context3D = Starling.context;
            var targetSpace:DisplayObject = object.stage;
            var stage:Stage  = Starling.current.stage;
            var scale:Number = Starling.current.contentScaleFactor;
            var bounds:Rectangle      = _helperRect;
            var boundsPot:Rectangle   = _helperRect2;
            var intersectWithStage:Boolean;
            var state:RenderState = painter.state;

            if (context == null) throw new MissingContextError();
            
            // the bounds of the object in stage coordinates
            // (or, if the object is not connected to the stage, in its base object's coordinates)
            intersectWithStage = !intoCache && _offsetX == 0 && _offsetY == 0;
            calculateBounds(object, targetSpace, _resolution * scale, intersectWithStage, bounds, boundsPot);
            
            if (bounds.isEmpty())
            {
                disposePassTextures();
                return intoCache ? new MeshBatch() : null;
            }
            
            updateBuffers(context, boundsPot);
            updatePassTextures(boundsPot.width, boundsPot.height, _resolution * scale);
            
            painter.finishMeshBatch();
            painter.drawCount += _numPasses;
            painter.pushState();
            state.clipRect = boundsPot;

            if (state.renderTarget && !SystemUtil.supportsRelaxedTargetClearRequirement)
                throw new IllegalOperationError(
                    "To nest filters, you need at least Flash Player / AIR version 15.");
            
            if (intoCache)
                cacheTexture = Texture.empty(boundsPot.width, boundsPot.height, PMA, false, true,
                                             _resolution * scale);

            // draw the original object into a texture
            state.renderTarget = _passTextures[0];
            state.blendMode = BlendMode.NORMAL;
            state.setProjectionMatrix(
                bounds.x, bounds.y, boundsPot.width, boundsPot.height,
                stage.stageWidth, stage.stageHeight, stage.cameraPosition);

            painter.prepareToDraw();
            painter.clear();
            object.render(painter);
            painter.finishMeshBatch();
            
            // prepare drawing of actual filter passes
            BlendMode.get(BlendMode.NORMAL).activate();
            state.setModelviewMatricesToIdentity();  // now we'll draw in stage coordinates!

            _vertexData.setVertexBufferAttribute(_vertexBuffer, _vertexPosAtID, "position");
            _vertexData.setVertexBufferAttribute(_vertexBuffer, _texCoordsAtID, "texCoords");

            // draw all passes
            for (var i:int=0; i<_numPasses; ++i)
            {
                if (i < _numPasses - 1) // intermediate pass
                {
                    // draw into pass texture
                    state.renderTarget = getPassTexture(i+1);
                    painter.clear();
                }
                else // final pass
                {
                    if (intoCache)
                    {
                        // draw into cache texture
                        state.renderTarget = cacheTexture;
                        painter.clear();
                    }
                    else
                    {
                        _helperMatrix.identity();
                        _helperMatrix.translate(_offsetX, _offsetY);

                        // draw into back buffer, at original (stage) coordinates
                        painter.popState();
                        painter.pushState();

                        state.setModelviewMatricesToIdentity();
                        state.transformModelviewMatrix(_helperMatrix);
                        state.blendMode = object.blendMode;
                        painter.prepareToDraw();
                    }
                }
                
                passTexture = getPassTexture(i);
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _mvpConstantID,
                                                      state.mvpMatrix3D, true);
                context.setTextureAt(_baseTextureID, passTexture.base);
                
                activate(i, context, passTexture);
                context.drawTriangles(_indexBuffer, 0, 2);
                deactivate(i, context, passTexture);
            }
            
            // reset shader attributes
            context.setVertexBufferAt(_vertexPosAtID, null);
            context.setVertexBufferAt(_texCoordsAtID, null);
            context.setTextureAt(_baseTextureID, null);

            painter.popState();

            if (intoCache)
            {
                // Create an image containing the cache. To have a display object that contains
                // the filter output in object coordinates, we wrap it in a QuadBatch: that way,
                // we can modify it with a transformation matrix.
                
                var meshBatch:MeshBatch = new MeshBatch();
                var image:Image = new Image(cacheTexture);
                
                // targetSpace could be null, so we calculate the matrix from the other side
                // and invert.

                object.getTransformationMatrix(targetSpace, sTransformationMatrix).invert();
                MatrixUtil.prependTranslation(sTransformationMatrix,
                    bounds.x + _offsetX, bounds.y + _offsetY);
                meshBatch.addMesh(image, sTransformationMatrix);
                // meshBatch.ownsTexture = true; // TODO check and re-implement

                return meshBatch;
            }
            else return null;
        }
        
        // helper methods
        
        private function updateBuffers(context:Context3D, bounds:Rectangle):void
        {
            _vertexData.setPoint(0, "position", bounds.x, bounds.y);
            _vertexData.setPoint(1, "position", bounds.right, bounds.y);
            _vertexData.setPoint(2, "position", bounds.x, bounds.bottom);
            _vertexData.setPoint(3, "position", bounds.right, bounds.bottom);
            
            if (_vertexBuffer == null)
            {
                _vertexBuffer = _vertexData.createVertexBuffer();
                _indexBuffer  = _indexData.createIndexBuffer(true);
            }

            _vertexData.uploadToVertexBuffer(_vertexBuffer);
        }
        
        private function updatePassTextures(width:Number, height:Number, scale:Number):void
        {
            var numPassTextures:int = _numPasses > 1 ? 2 : 1;
            var needsUpdate:Boolean =
                _passTextures.length != numPassTextures ||
                Math.abs(_passTextures[0].nativeWidth  - width  * scale) > 0.1 ||
                Math.abs(_passTextures[0].nativeHeight - height * scale) > 0.1;
            
            if (needsUpdate)
            {
                disposePassTextures();

                for (var i:int=0; i<numPassTextures; ++i)
                    _passTextures[i] = Texture.empty(width, height, PMA, false, true, scale);
            }
        }
        
        private function getPassTexture(pass:int):Texture
        {
            return _passTextures[pass % 2];
        }
        
        /** Calculates the bounds of the filter in stage coordinates. The method calculates two
         *  rectangles: one with the exact filter bounds, the other with an extended rectangle that
         *  will yield to a POT size when multiplied with the current scale factor / resolution.
         */
        private function calculateBounds(object:DisplayObject, targetSpace:DisplayObject,
                                         scale:Number, intersectWithStage:Boolean,
                                         resultRect:Rectangle,
                                         resultPotRect:Rectangle):void
        {
            var stage:Stage;
            var marginX:Number = _marginX;
            var marginY:Number = _marginY;
            
            if (targetSpace is Stage)
            {
                stage = targetSpace as Stage;

                if (object == stage || object == object.root)
                {
                    // optimize for full-screen effects
                    marginX = marginY = 0;
                    resultRect.setTo(0, 0, stage.stageWidth, stage.stageHeight);
                }
                else
                {
                    object.getBounds(stage, resultRect);
                }

                if (intersectWithStage)
                {
                    sStageBounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
                    RectangleUtil.intersect(resultRect, sStageBounds, resultRect);
                }
            }
            else
            {
                object.getBounds(targetSpace, resultRect);
            }

            if (!resultRect.isEmpty())
            {    
                // the bounds are a rectangle around the object, in stage coordinates,
                // and with an optional margin. 
                resultRect.inflate(marginX, marginY);
                
                // To fit into a POT-texture, we extend it towards the right and bottom.
                var minSize:int = MIN_TEXTURE_SIZE / scale;
                var minWidth:Number  = resultRect.width  > minSize ? resultRect.width  : minSize;
                var minHeight:Number = resultRect.height > minSize ? resultRect.height : minSize;
                resultPotRect.setTo(
                    resultRect.x, resultRect.y,
                    MathUtil.getNextPowerOfTwo(minWidth  * scale) / scale,
                    MathUtil.getNextPowerOfTwo(minHeight * scale) / scale);
            }
        }
        
        private function disposePassTextures():void
        {
            for each (var texture:Texture in _passTextures)
                texture.dispose();
            
            _passTextures.length = 0;
        }
        
        private function disposeCache():void
        {
            if (_cache)
            {
                _cache.dispose();
                _cache = null;
            }
        }
        
        // protected methods

        /** Subclasses must override this method and use it to create their 
         *  fragment- and vertex-programs. */
        protected function createPrograms():void
        {
            throw new Error("Method has to be implemented in subclass!");
        }

        /** Subclasses must override this method and use it to activate their fragment- and
         *  vertex-programs.
         *
         *  <p>The 'activate' call directly precedes the call to 'context.drawTriangles'. Set up
         *  the context the way your filter needs it. The following constants and attributes 
         *  are set automatically:</p>
         *  
         *  <ul><li>vertex constants 0-3: mvpMatrix (3D)</li>
         *      <li>vertex attribute 0: vertex position (FLOAT_2)</li>
         *      <li>vertex attribute 1: texture coordinates (FLOAT_2)</li>
         *      <li>texture 0: input texture</li>
         *  </ul>
         *  
         *  @param pass    the current render pass, starting with '0'. Multipass filters can
         *                 provide different logic for each pass.
         *  @param context the current context3D (the same as in Starling.context, passed
         *                 just for convenience)
         *  @param texture the input texture, which is already bound to sampler 0.
         *  */
        protected function activate(pass:int, context:Context3D, texture:Texture):void
        {
            throw new Error("Method has to be implemented in subclass!");
        }
        
        /** This method is called directly after 'context.drawTriangles'. 
         *  If you need to clean up any resources, you can do so in this method. */
        protected function deactivate(pass:int, context:Context3D, texture:Texture):void
        {
            // clean up resources
        }
        
        // cache
        
        /** Caches the filter output into a texture. An uncached filter is rendered in every frame;
         *  a cached filter only once. However, if the filtered object or the filter settings
         *  change, it has to be updated manually; to do that, call "cache" again. */
        public function cache():void
        {
            _cacheRequested = true;
            disposeCache();
        }
        
        /** Clears the cached output of the filter. After calling this method, the filter will
         *  be executed once per frame again. */ 
        public function clearCache():void
        {
            _cacheRequested = false;
            disposeCache();
        }
        
        // properties
        
        /** Indicates if the filter is cached (via the "cache" method). */
        public function get isCached():Boolean { return (_cache != null) || _cacheRequested; }
        
        /** The resolution of the filter texture. "1" means stage resolution, "0.5" half the
         *  stage resolution. A lower resolution saves memory and execution time (depending on 
         *  the GPU), but results in a lower output quality. Values greater than 1 are allowed;
         *  such values might make sense for a cached filter when it is scaled up. @default 1 */
        public function get resolution():Number { return _resolution; }
        public function set resolution(value:Number):void 
        {
            if (value <= 0) throw new ArgumentError("Resolution must be > 0");
            else _resolution = value;
        }
        
        /** The filter mode, which is one of the constants defined in the "FragmentFilterMode" 
         *  class. @default "replace" */
        public function get mode():String { return _mode; }
        public function set mode(value:String):void { _mode = value; }
        
        /** Use the x-offset to move the filter output to the right or left. */
        public function get offsetX():Number { return _offsetX; }
        public function set offsetX(value:Number):void { _offsetX = value; }
        
        /** Use the y-offset to move the filter output to the top or bottom. */
        public function get offsetY():Number { return _offsetY; }
        public function set offsetY(value:Number):void { _offsetY = value; }
        
        /** The x-margin will extend the size of the filter texture along the x-axis.
         *  Useful when the filter will "grow" the rendered object. */
        protected function get marginX():Number { return _marginX; }
        protected function set marginX(value:Number):void { _marginX = value; }
        
        /** The y-margin will extend the size of the filter texture along the y-axis.
         *  Useful when the filter will "grow" the rendered object. */
        protected function get marginY():Number { return _marginY; }
        protected function set marginY(value:Number):void { _marginY = value; }
        
        /** The number of passes the filter is applied. The "activate" and "deactivate" methods
         *  will be called that often. */
        protected function set numPasses(value:int):void { _numPasses = value; }
        protected function get numPasses():int { return _numPasses; }
        
        /** The ID of the vertex buffer attribute that stores the vertex position. */ 
        protected final function get vertexPosAtID():int { return _vertexPosAtID; }
        protected final function set vertexPosAtID(value:int):void { _vertexPosAtID = value; }
        
        /** The ID of the vertex buffer attribute that stores the texture coordinates. */
        protected final function get texCoordsAtID():int { return _texCoordsAtID; }
        protected final function set texCoordsAtID(value:int):void { _texCoordsAtID = value; }

        /** The ID (sampler) of the input texture (containing the output of the previous pass). */
        protected final function get baseTextureID():int { return _baseTextureID; }
        protected final function set baseTextureID(value:int):void { _baseTextureID = value; }
        
        /** The ID of the first register of the modelview-projection constant (a 4x4 matrix). */
        protected final function get mvpConstantID():int { return _mvpConstantID; }
        protected final function set mvpConstantID(value:int):void { _mvpConstantID = value; }
    }
}