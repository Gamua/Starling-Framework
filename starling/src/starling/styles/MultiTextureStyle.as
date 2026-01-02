// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.styles
{
    import flash.geom.Matrix;

    import starling.display.Mesh;
    import starling.rendering.MeshEffect;
    import starling.rendering.RenderState;
    import starling.rendering.VertexData;
    import starling.rendering.VertexDataFormat;
    import starling.textures.Texture;

    /** Provides a way to batch up to 4 different textures in one draw call, at the cost of more complex custom Fragment Shaders
     *  To use this, set Mesh.defaultStyle to MultiTextureStyle (ideally before Starling is initialised!)
     **/
    public class MultiTextureStyle extends MeshStyle
    {
        /** The vertex format expected by this style. */
        public static const VERTEX_FORMAT:VertexDataFormat =
            MeshStyle.VERTEX_FORMAT.extend("texture:float1");

        /** Maximum number of textures that can be batched. */
        public static const MAX_NUM_TEXTURES:int = 5;

        private var _dirty:Boolean = true;
        private const _textures:Vector.<Texture> = new Vector.<Texture>();

        private static var sMaxTextures:int = 2;
        private static const sTextureIndexMap:Vector.<int> = new Vector.<int>();

        /** Maximum number of textures to be batched, default 2. */
        public static function get maxTextures():int { return sMaxTextures; }
        public static function set maxTextures(value:int):void
        {
            value = value < 1 ? 1 : value;
            sMaxTextures = value > MAX_NUM_TEXTURES ? MAX_NUM_TEXTURES : value;
        }

        public function MultiTextureStyle() {}

        /** @private */
        override public function copyFrom(meshStyle:MeshStyle):void
        {
            const otherStyle:MultiTextureStyle = meshStyle as MultiTextureStyle;

            if (otherStyle)
            {
                const length:uint = otherStyle._textures.length;

                for (var i:uint = 0; i < length; i++)
                    _textures[i] = otherStyle._textures[i];
                _textures.length = length;
            }

            super.copyFrom(meshStyle);
        }

        /** @private */
        override public function createEffect():MeshEffect
        {
            return new MultiTextureEffect();
        }

        /** @private */
        override public function updateEffect(effect:MeshEffect, state:RenderState):void
        {
            (effect as MultiTextureEffect).textures = _textures;

            super.updateEffect(effect, state);
        }

        /** @private */
        override public function canBatchWith(meshStyle:MeshStyle):Boolean
        {
            const mtStyle:MultiTextureStyle = meshStyle as MultiTextureStyle;

            if (mtStyle)
            {
                const numTexturesToAdd:int = numTextures;
                const numTexturesHere:int = mtStyle.numTextures;

                if (numTexturesToAdd > 0 && numTexturesHere > 0)
                {
                    if (textureSmoothing == mtStyle.textureSmoothing &&
                        textureRepeat == mtStyle.textureRepeat)
                    {
                        if (numTexturesHere + numTexturesToAdd > sMaxTextures)
                        {
                            var numSharedTextures:int = 0;

                            for (var i:int = 0; i < numTexturesToAdd; i++)
                                if (mtStyle.getTextureIndex(getTexture(i)) != -1)
                                    numSharedTextures++;
                            return numTexturesHere + numTexturesToAdd -
                                numSharedTextures <= sMaxTextures;
                        }
                        return true;
                    }
                }
                else
                {
                    return 0 == numTexturesToAdd && 0 == numTexturesHere;
                }
            }
            return false;
        }

        /** @private */
        override public function batchVertexData(targetStyle:MeshStyle, targetVertexID:int = 0,
                                                 matrix:Matrix = null, vertexID:int = 0,
                                                 numVertices:int = -1):void
        {
            var i:int;

            if (matrix && _dirty)
            {
                for (i = 0; i < vertexData.numVertices; i++)
                    vertexData.setFloat(i, "texture", 0);
                _dirty = false;
            }

            super.batchVertexData(targetStyle, targetVertexID, matrix, vertexID, numVertices);

            const mtTarget:MultiTextureStyle = targetStyle as MultiTextureStyle;

            if (mtTarget)
            {
                var dirty:Boolean = false;

                for (i = 0; i < numTextures; i++)
                {
                    const texture:Texture = getTexture(i);
                    var textureIndexOnTarget:int = mtTarget.getTextureIndex(texture);

                    if (-1 == textureIndexOnTarget)
                    {
                        textureIndexOnTarget = mtTarget.numTextures;
                        if (0 == textureIndexOnTarget)
                            mtTarget.texture = texture;
                        else
                            mtTarget._textures[mtTarget._textures.length] = texture;
                    }
                    sTextureIndexMap[i] = textureIndexOnTarget;
                    dirty ||= i != textureIndexOnTarget;
                }
                if (dirty)
                {
                    const targetVertexData:VertexData = mtTarget.vertexData;

                    if (numVertices < 0)
                        numVertices = targetVertexData.numVertices - targetVertexID;
                    for (i = 0; i < numVertices; i++)
                    {
                        const sourceTexID:int = Math.round(targetVertexData.getFloat(targetVertexID + i,
                            "texture") * 4);
                        const targetTexID:int = sTextureIndexMap[sourceTexID];

                        if (sourceTexID != targetTexID)
                            targetVertexData.setFloat(targetVertexID + i, "texture",
                                targetTexID / 4);
                    }
                }
            }
        }

        /** @private */
        override protected function onTargetAssigned(target:Mesh):void
        {
            _dirty = true;
        }

        /** @private */
        override public function get vertexFormat():VertexDataFormat
        {
            return VERTEX_FORMAT;
        }

        // Returns the texture's index in the shared texture list, or -1 if not
        // in the list.
        private function getTextureIndex(texture:Texture):int
        {
            for (var i:int = 0; i < numTextures; i++)
                if (getTexture(i).root == texture.root) return i;
            return -1;
        }

        // Returns an element of the shared texture list.
        [Inline]
        private function getTexture(index:int):Texture
        {
            return index > 0 ? _textures[index - 1] : texture;
        }

        // Returns the length of the shared texture list.
        private function get numTextures():int
        {
            return _textures.length + int(texture != null);
        }
    }
}

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

import starling.core.Starling;
import starling.rendering.MeshEffect;
import starling.rendering.Program;
import starling.rendering.VertexDataFormat;
import starling.styles.MultiTextureStyle;
import starling.textures.Texture;
import starling.utils.RenderUtil;

class MultiTextureEffect extends MeshEffect
{
    public static const VERTEX_FORMAT:VertexDataFormat = MultiTextureStyle.VERTEX_FORMAT;

    public var textures:Vector.<Texture>;

    private var _isBaseline:Boolean;

    private static const kTextureIndices:Vector.<Number> = new <Number>[
        0.125, 0.375, 0.625, 0.875,
        1, 0, 0, 0
    ];

    public function MultiTextureEffect()
    {
        _isBaseline = Starling.current.profile.indexOf("baseline") != -1;
    }

    override protected function get programVariantName():uint
    {
        var bits:uint = super.programVariantName;

        for (var i:int = 0; i < textures.length; i++)
            bits |= RenderUtil.getTextureVariantBits(textures[i]) << (4 * i + 4);
        return bits;
    }

    override protected function createProgram():Program
    {
        const length:uint = textures.length;

        if (length > 0)
        {
            const fragmentShader:Vector.<String> = new Vector.<String>();
            const vertexShader:String = [
                "m44 op, va0, vc0", // 4x4 matrix transform to output clip-space
                "mov v0, va1",      // pass texture coordinates to fragment program
                "mul v1, va2, vc4", // multiply alpha (vc4) with color (va2), pass to fp
                "mov v2, va3"       // pass texture sampler index to fp
            ].join("\n");

            if (_isBaseline)
            {
                fragmentShader.push(
                    "slt ft4, v2.xxxx, fc0",
                    tex("ft0", "v0", 0, texture),
                    "min ft5, ft4.xxxx, ft0",
                    "sub ft6, fc1.xxxx, ft4",
                    tex("ft1", "v0", 1, textures[0])
                );
                if (length > 1)
                {
                    fragmentShader.push(
                        "min ft6.xyz, ft6.xyz, ft4.yzw",
                        "min ft0, ft6.xxxx, ft1",
                        "add ft5, ft5, ft0",
                        tex("ft2", "v0", 2, textures[1]),
                        "min ft0, ft6.yyyy, ft2"
                    );
                    if (length > 2)
                    {
                        fragmentShader.push(
                            "add ft5, ft5, ft0",
                            tex("ft3", "v0", 3, textures[2]),
                            "min ft0, ft6.zzzz, ft3"
                        );
                        if (length > 3)
                        {
                            fragmentShader.push(
                                "add ft5, ft5, ft0",
                                tex("ft4", "v0", 4, textures[3]),
                                "min ft0, ft6.wwww, ft4"
                            );
                        }
                    }
                }
                else {
                    fragmentShader.push(
                        "min ft0, ft6.xxxx, ft1"
                    );
                }
                fragmentShader.push(
                    "add ft5, ft5, ft0",
                    "mul oc, ft5, v1"       // multiply color with texel color
                );
            }
            else
            {
                if (length > 1)
                {
                    fragmentShader.push(
                        "slt ft4, v2.xxxx, fc0",
                        "sub ft6, fc1.xxxx, ft4",
                        "min ft6.xyz, ft6.xyz, ft4.yzw",
                        "ifg ft4.x, fc0.z",
                        tex("ft5", "v0", 0, texture),
                        "eif",
                        "ifg ft6.x, fc0.z",
                        tex("ft5", "v0", 1, textures[0]),
                        "eif",
                        "ifg ft6.y, fc0.z",
                        tex("ft5", "v0", 2, textures[1]),
                        "eif"
                    );
                    if (length > 2)
                    {
                        fragmentShader.push(
                            "ifg ft6.z, fc0.z",
                            tex("ft5", "v0", 3, textures[2]),
                            "eif"
                        );
                        if (length > 3)
                        {
                            fragmentShader.push(
                                "ifg ft6.w, fc0.z",
                                tex("ft5", "v0", 4, textures[3]),
                                "eif"
                            );
                        }
                    }
                }
                else
                {
                    fragmentShader.push(
                        "ifl v2.x, fc0.x",
                        tex("ft5", "v0", 0, texture),
                        "els",
                        tex("ft5", "v0", 1, textures[0]),
                        "eif"
                    );
                }
                fragmentShader.push(
                    "mul oc, ft5, v1"       // multiply color with texel color
                );
            }
            return Program.fromSource(vertexShader, fragmentShader.join("\n"),
                _isBaseline ? 1 : 2);
        }

        return super.createProgram();
    }

    override protected function beforeDraw(context:Context3D):void
    {
        super.beforeDraw(context);

        const length:uint = textures.length;

        if (length > 0)
        {
            for (var i:int = 0; i < length; i++)
            {
                const texture:Texture = textures[i];

                RenderUtil.setSamplerStateAt(i + 1, texture.mipMapping,
                    textureSmoothing, textureRepeat);
                context.setTextureAt(i + 1, texture.base);
            }
            vertexFormat.setVertexBufferAt(3, vertexBuffer, "texture");
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,
                0, kTextureIndices, length > 1 || _isBaseline ? -1 : 1);
        }
    }

    override protected function afterDraw(context:Context3D):void
    {
        const length:uint = textures.length;

        if (length > 0)
        {
            for (var i:int = 0; i < length; i++) context.setTextureAt(i + 1, null);
            context.setVertexBufferAt(3, null);
        }

        super.afterDraw(context);
    }

    override public function get vertexFormat():VertexDataFormat
    {
        return VERTEX_FORMAT;
    }
}
