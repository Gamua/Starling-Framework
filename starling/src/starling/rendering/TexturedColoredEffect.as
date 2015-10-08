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
    import flash.display3D.Context3DTextureFormat;

    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.RenderUtil;

    /** A concrete effect drawing a mesh of colored, textured vertices. */
    public class TexturedColoredEffect extends ColoredEffect
    {
        private static const FORMAT:VertexDataFormat =
                VertexDataFormat.fromString("position(float2), color(bytes4), texCoords(float2)");

        private var _texture:Texture;

        /** Creates a new TexturedColoredEffect instance. */
        public function TexturedColoredEffect()
        { }

        /** @private */
        override protected function get programVariantName():uint
        {
            if (_texture == null) return 0xfff;

            var bitField:uint = 0;
            var formatBits:int = 0;

            switch (_texture.format)
            {
                case Context3DTextureFormat.COMPRESSED_ALPHA:
                    formatBits = 1; break;
                case Context3DTextureFormat.COMPRESSED:
                    formatBits = 2; break;
            }

            bitField |= formatBits;

            if (!_texture.premultipliedAlpha)
                bitField |= 1 << 2;

            return bitField;
        }

        /** @private */
        override protected function createProgram():Program
        {
            if (_texture == null) return super.createProgram();

            var vertexShader:String =
                "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clip-space
                "mul v0, va1, vc4 \n" + // multiply alpha (vc4) with color (va1), pass to fp
                "mov v1, va2      \n";  // pass texture coordinates to fragment program

            var fragmentShader:String =
                RenderUtil.createAGALTexOperation("ft1", "v1", 0, _texture) +
                "mul oc, ft1, v0";  // multiply color with texel color

            return Program.fromSource(vertexShader, fragmentShader);
        }

        /** Does the same as the base class' method, plus activates the current texture with the
         *  required sampler state (<code>fs0</code>) and sets up texture coordinates in
         *  <code>va2</code>. */
        override protected function beforeDraw(context:Context3D):void
        {
            super.beforeDraw(context);

            if (_texture)
            {
                RenderUtil.setSamplerStateAt(0, _texture.mipMapping, TextureSmoothing.BILINEAR);
                context.setTextureAt(0, _texture.base);
                vertexFormat.setVertexBufferAttribute(vertexBuffer, 2, "texCoords");
            }
        }

        /** Resets texture and vertex buffer attributes. */
        override protected function afterDraw(context:Context3D):void
        {
            if (_texture)
            {
                context.setTextureAt(0, null);
                context.setVertexBufferAt(2, null);
            }

            super.afterDraw(context);
        }

        /** Returns the data format that this effect requires from the VertexData
         *  that it renders.
         *
         *  @return "position(float2), color(bytes4), texCoords(float2)" */
        override public function get vertexFormat():VertexDataFormat { return FORMAT; }

        /** The texture to be mapped onto the vertices. */
        public function get texture():Texture { return _texture; }
        public function set texture(value:Texture):void { _texture = value; }
    }
}
