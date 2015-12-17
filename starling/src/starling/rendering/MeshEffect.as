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

    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.RenderUtil;

    /** An effect drawing a mesh of colored, textured vertices.
     *  This is the standard effect that will be used per default for all Starling meshes;
     *  if you want to create your own rendering code, you will have to extend this class.
     *
     *  <p>For more information about the usage and creation of effects, please have a look at
     *  the documentation of the parent class, "Effect".</p>
     *
     *  @see Effect
     *  @see starling.rendering.MeshStyle
     *
     */
    public class MeshEffect extends Effect
    {
        /** The vertex format expected by <code>uploadVertexData</code>:
         *  <code>"position(float2), color(bytes4), texCoords(float2)"</code> */
        public static const VERTEX_FORMAT:VertexDataFormat =
                VertexDataFormat.fromString("position(float2), color(bytes4), texCoords(float2)");

        private var _texture:Texture;
        private var _textureSmoothing:String;

        /** Creates a new MeshEffect instance. */
        public function MeshEffect()
        {
            _textureSmoothing = TextureSmoothing.BILINEAR;
        }

        /** Override this method if the effect requires a different program depending on the
         *  current settings. Ideally, you do this by creating a bit mask encoding all the options.
         *  This method is called often, so do not allocate any temporary objects when overriding.
         *
         *  <p>Reserve 8 bits for the variant name of the base class.</p>
         */
        override protected function get programVariantName():uint
        {
            return RenderUtil.getTextureVariantBits(_texture);
        }

        /** @private */
        override protected function createProgram():Program
        {
            var vertexShader:String, fragmentShader:String;

            if (_texture)
            {
                vertexShader =
                    "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clip-space
                    "mul v0, va1, vc4 \n" + // multiply alpha (vc4) with color (va1), pass to fp
                    "mov v1, va2      \n";  // pass texture coordinates to fragment program

                fragmentShader =
                    RenderUtil.createAGALTexOperation("ft1", "v1", 0, _texture) +
                    "mul oc, ft1, v0  \n";  // multiply color with texel color
            }
            else
            {
                vertexShader =
                    "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clipspace
                    "mul v0, va1, vc4 \n";  // multiply alpha (vc4) with color (va1)

                fragmentShader =
                    "mov oc, v0       \n";  // output color
            }

            return Program.fromSource(vertexShader, fragmentShader);
        }

        /** This method is called by <code>render</code>, directly before
         *  <code>context.drawTriangles</code>. It activates the program and sets up
         *  the context with the following constants and attributes:
         *
         *  <ul>
         *    <li><code>vc0-vc3</code> — MVP matrix</li>
         *    <li><code>vc4</code> — alpha value (same value for all components)</li>
         *    <li><code>va0</code> — vertex position (xy)</li>
         *    <li><code>va1</code> — vertex color (rgba), using premultiplied alpha</li>
         *    <li><code>va2</code> — texture coordinates, if there is a texture</li>
         *    <li><code>fs0</code> — texture, if there is one</li>
         *  </ul>
         */
        override protected function beforeDraw(context:Context3D):void
        {
            super.beforeDraw(context);

            vertexFormat.setVertexBufferAttribute(vertexBuffer, 1, "color");

            if (_texture)
            {
                RenderUtil.setSamplerStateAt(0, _texture.mipMapping, _textureSmoothing);
                context.setTextureAt(0, _texture.base);
                vertexFormat.setVertexBufferAttribute(vertexBuffer, 2, "texCoords");
            }
        }

        /** This method is called by <code>render</code>, directly after
         *  <code>context.drawTriangles</code>. Resets texture and vertex buffer attributes. */
        override protected function afterDraw(context:Context3D):void
        {
            context.setVertexBufferAt(1, null);

            if (_texture)
            {
                context.setTextureAt(0, null);
                context.setVertexBufferAt(2, null);
            }

            super.afterDraw(context);
        }

        /** The data format that this effect requires from the VertexData that it renders:
         *  <code>"position(float2), color(bytes4), texCoords(float2)"</code> */
        override public function get vertexFormat():VertexDataFormat { return VERTEX_FORMAT; }

        /** The texture to be mapped onto the vertices. */
        public function get texture():Texture { return _texture; }
        public function set texture(value:Texture):void { _texture = value; }

        /** The smoothing filter that is used for the texture. @default bilinear */
        public function get textureSmoothing():String { return _textureSmoothing; }
        public function set textureSmoothing(value:String):void { _textureSmoothing = value; }
    }
}
