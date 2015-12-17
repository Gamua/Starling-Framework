// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.rendering
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.events.Event;
    import flash.geom.Matrix3D;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;

    import starling.core.Starling;
    import starling.errors.MissingContextError;
    import starling.utils.execute;

    /** An effect encapsulates all steps of a Stage3D draw operation. It configures the
     *  render context and sets up shader programs as well as index- and vertex-buffers.
     *  Extend this class when you need custom rendering code for your display objects.
     *
     *  <p><strong>Extending the Effect class</strong></p>
     *
     *  <p>This class provides the basic mechanisms of low-level rendering. The implementation
     *  of the base class can only render white triangles with a constant alpha value; most of the
     *  time, you'll want to use an existing subclass, or create your own. For the latter, it is
     *  recommended to override the following methods:</p>
     *
     *  <ul>
     *    <li><code>createProgram():Program</code> — must create the actual program containing 
     *        vertex- and fragment-shaders. A program will be created only once for each render
     *        context; this is taken care of by the base class.</li>
     *    <li><code>get programVariantName():uint</code> (optional) — implement this if your
     *        effect requires different programs, depending on its settings. The recommended
     *        way to do this is via a bit-mask that uniquely encodes the current settings.</li>
     *    <li><code>get vertexFormat():String</code> — must return the <code>VertexData</code>
     *        format that this effect requires for its vertices.</li>
     *    <li><code>beforeDraw(context:Context3D):void</code> — Set up your context by
     *        configuring program constants and buffer attributes.</li>
     *    <li><code>afterDraw(context:Context3D):void</code> — Will be called directly after
     *        <code>context.drawTriangles()</code>. Clean up any context configuration here.</li>
     *  </ul>
     *
     *  <p>Furthermore, you should add properties that manage the data you need during rendering,
     *  e.g. the texture(s) that should be used, program constants, etc. I recommend to look
     *  at the implementation of Starling's <code>MeshEffect</code> for a simple blueprint
     *  of a custom effect.</p>
     *
     *  <strong>Using the Effect class</strong>
     *
     *  <p>Using an effect always follows steps similar to those shown in the following example:</p>
     *
     *  <listing>
     *  // create effect
     *  var effect:MeshEffect = new MeshEffect();
     *  
     *  // configure effect
     *  effect.mvpMatrix = painter.mvpMatrix;
     *  effect.texture = getHeroTexture();
     *  effect.color = 0xf0f0f0;
     *  
     *  // upload vertex data
     *  effect.uploadIndexData(indexData);
     *  effect.uploadVertexData(vertexData);
     *  
     *  // draw!
     *  effect.render(0, numTriangles);</listing>
     *
     *  <p>Note that the <code>VertexData</code> being uploaded has to be created with the same
     *  format as the one returned by the effect's <code>vertexFormat</code> property.</p>
     *
     *  @see MeshEffect
     *  @see starling.rendering.MeshStyle
     *  @see starling.utils.RenderUtil
     */
    public class Effect
    {
        /** The vertex format expected by <code>uploadVertexData</code>:
         *  <code>"position(float2)"</code> */
        public static const VERTEX_FORMAT:VertexDataFormat =
            VertexDataFormat.fromString("position(float2)");

        private var _indexBuffer:IndexBuffer3D;
        private var _indexBufferSize:int;  // in number of indices
        private var _vertexBuffer:VertexBuffer3D;
        private var _vertexBufferSize:int; // in blocks of 32 bits

        private var _alpha:Number;
        private var _mvpMatrix:Matrix3D;
        private var _onRestore:Function;
        private var _programBaseName:String;

        // helper objects
        private static var sRenderAlpha:Vector.<Number> = new Vector.<Number>(4, true);
        private static var sProgramNameCache:Dictionary = new Dictionary();

        /** Creates a new effect. */
        public function Effect()
        {
            _alpha = 1.0;
            _mvpMatrix = new Matrix3D();
            _programBaseName = getQualifiedClassName(this).split("::").pop();

            // Handle lost context (using conventional Flash event for weak listener support)
            Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
                onContextCreated, false, 0, true);
        }

        /** Purges the index- and vertex-buffers. */
        public function dispose():void
        {
            Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            purgeBuffers();
        }

        private function onContextCreated(event:Event):void
        {
            purgeBuffers();
            execute(_onRestore, this);
        }

        /** Purges one or both of the index- and vertex-buffers. */
        public function purgeBuffers(indexBuffer:Boolean=true, vertexBuffer:Boolean=true):void
        {
            if (_indexBuffer && indexBuffer)
            {
                _indexBuffer.dispose();
                _indexBuffer = null;
            }

            if (_vertexBuffer && vertexBuffer)
            {
                _vertexBuffer.dispose();
                _vertexBuffer = null;
            }
        }

        /** Uploads the given index data to the internal index buffer. If the buffer is too
         *  small, a new one is created automatically. */
        public function uploadIndexData(indexData:IndexData):void
        {
            if (_indexBuffer)
            {
                if (indexData.numIndices <= _indexBufferSize)
                    indexData.uploadToIndexBuffer(_indexBuffer);
                else
                    purgeBuffers(true, false);
            }
            if (_indexBuffer == null)
            {
                _indexBuffer = indexData.createIndexBuffer(true);
                _indexBufferSize = indexData.numIndices;
            }
        }

        /** Uploads the given vertex data to the internal vertex buffer. If the buffer is too
         *  small, a new one is created automatically. */
        public function uploadVertexData(vertexData:VertexData):void
        {
            if (_vertexBuffer)
            {
                if (vertexData.sizeIn32Bits <= _vertexBufferSize)
                    vertexData.uploadToVertexBuffer(_vertexBuffer);
                else
                    purgeBuffers(false, true);
            }
            if (_vertexBuffer == null)
            {
                _vertexBuffer = vertexData.createVertexBuffer(true);
                _vertexBufferSize = vertexData.sizeIn32Bits;
            }
        }

        // rendering

        /** Draws the triangles described by the index- and vertex-buffers, or a range of them.
         *  This calls <code>beforeDraw</code>, <code>context.drawTriangles</code>, and
         *  <code>afterDraw</code>, in this order. */
        public function render(firstIndex:int=0, numTriangles:int=-1):void
        {
            if (numTriangles < 0) numTriangles = indexBufferSize / 3;
            if (numTriangles == 0) return;

            var context:Context3D = Starling.context;
            if (context == null) throw new MissingContextError();

            beforeDraw(context);
            context.drawTriangles(indexBuffer, firstIndex, numTriangles);
            afterDraw(context);
        }

        /** This method is called by <code>render</code>, directly before
         *  <code>context.drawTriangles</code>. It activates the program and sets up
         *  the context with the following constants and attributes:
         *
         *  <ul>
         *    <li><code>vc0-vc3</code> — MVP matrix</li>
         *    <li><code>vc4</code> — alpha value (same value for all components)</li>
         *    <li><code>va0</code> — vertex position (xy)</li>
         *  </ul>
         */
        protected function beforeDraw(context:Context3D):void
        {
            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = sRenderAlpha[3] = _alpha;

            program.activate(context);
            vertexFormat.setVertexBufferAttribute(vertexBuffer, 0, "position");
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvpMatrix, true);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, sRenderAlpha, 1);
        }

        /** This method is called by <code>render</code>, directly after
         *  <code>context.drawTriangles</code>. Resets vertex buffer attributes.
         */
        protected function afterDraw(context:Context3D):void
        {
            context.setVertexBufferAt(0, null);
        }

        // program management

        /** Creates the program (a combination of vertex- and fragment-shader) used to render
         *  the effect with the current settings. Override this method in a subclass to create
         *  your shaders. This method will only be called once; the program is automatically stored
         *  in the <code>Painter</code> and re-used by all instances of this effect.
         */
        protected function createProgram():Program
        {
            var vertexShader:String =
                "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clipspace
                "mov v0, vc4      \n";  // pass alpha to fragment program

            var fragmentShader:String =
                "mov oc, v0       \n";  // output color

            return Program.fromSource(vertexShader, fragmentShader);
        }

        /** Override this method if the effect requires a different program depending on the
         *  current settings. Ideally, you do this by creating a bit mask encoding all the options.
         *  This method is called often, so do not allocate any temporary objects when overriding.
         *
         *  @default 0
         */
        protected function get programVariantName():uint
        {
            return 0;
        }

        /** Returns the base name for the program.
         *  @default the class name
         */
        protected function get programBaseName():String { return _programBaseName; }
        protected function set programBaseName(value:String):void { _programBaseName = value; }

        /** Returns the full name of the program, which is used to register it at the current
         *  <code>Painter</code>.
         *
         *  <p>The default implementation efficiently combines the program's base and variant
         *  names (e.g. <code>LightEffect#42</code>). It shouldn't be necessary to override
         *  this method.</p>
         */
        protected function get programName():String
        {
            var baseName:String  = this.programBaseName;
            var variantName:uint = this.programVariantName;
            var nameCache:Dictionary = sProgramNameCache[baseName];

            if (nameCache == null)
            {
                nameCache = new Dictionary();
                sProgramNameCache[baseName] = nameCache;
            }

            var name:String = nameCache[variantName];

            if (name == null)
            {
                if (variantName) name = baseName + "#" + variantName.toString(16);
                else             name = baseName;

                nameCache[variantName] = name;
            }

            return name;
        }

        /** Returns the current program, either by creating a new one (via
         *  <code>createProgram</code>) or by getting it from the <code>Painter</code>. */
        protected function get program():Program
        {
            var name:String = this.programName;
            var painter:Painter = Starling.painter;
            var program:Program = painter.getProgram(name);

            if (program == null)
            {
                program = createProgram();
                painter.registerProgram(name, program);
            }

            return program;
        }

        // properties

        /** The function that you provide here will be called after a context loss.
         *  Call both "upload..." methods from within the callback to restore any vertex or
         *  index buffers. The callback will be executed with the effect as its sole parameter. */
        public function get onRestore():Function { return _onRestore; }
        public function set onRestore(value:Function):void { _onRestore = value; }

        /** The data format that this effect requires from the VertexData that it renders:
         *  <code>"position(float2)"</code> */
        public function get vertexFormat():VertexDataFormat { return VERTEX_FORMAT; }

        /** The alpha value of the object rendered by the effect. Must be taken into account
         *  by all subclasses. */
        public function get alpha():Number { return _alpha; }
        public function set alpha(value:Number):void { _alpha = value; }

        /** The MVP (modelview-projection) matrix transforms vertices into clipspace. */
        public function get mvpMatrix():Matrix3D { return _mvpMatrix; }
        public function set mvpMatrix(value:Matrix3D):void { _mvpMatrix.copyFrom(value); }

        /** The internally used index buffer used on rendering. */
        protected function get indexBuffer():IndexBuffer3D { return _indexBuffer; }
        
        /** The current size of the index buffer (in number of indices). */
        protected function get indexBufferSize():int { return _indexBufferSize; }

        /** The internally used vertex buffer used on rendering. */
        protected function get vertexBuffer():VertexBuffer3D { return _vertexBuffer; }
        
        /** The current size of the vertex buffer (in blocks of 32 bits). */
        protected function get vertexBufferSize():int { return _vertexBufferSize; }
    }
}
