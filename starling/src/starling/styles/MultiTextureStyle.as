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

    import starling.core.Starling;
    import starling.display.Mesh;
    import starling.rendering.MeshEffect;
    import starling.rendering.RenderState;
    import starling.rendering.VertexData;
    import starling.rendering.VertexDataFormat;
    import starling.textures.Texture;

    /** Batches meshes that use different textures into a single draw call.
     *
     *  <p>Normally, Starling can only batch meshes that share the same texture. This style adds a
     *  per-vertex texture index to the vertex data and generates a fragment shader that picks the
     *  matching texture for each fragment, so up to <code>maxTextures</code> different textures
     *  can be drawn in one call.</p>
     *
     *  <p>To use it, assign the style as the default for all meshes, ideally before Starling is
     *  started:</p>
     *
     *  <listing>Mesh.defaultStyle = MultiTextureStyle;</listing>
     */
    public class MultiTextureStyle extends MeshStyle
    {
        /** The vertex format expected by this style. */
        public static const VERTEX_FORMAT:VertexDataFormat =
            MeshStyle.VERTEX_FORMAT.extend("texture:float1");

        /** The upper limit for <code>maxTextures</code>. AGAL 1 provides eight texture samplers
         *  (<code>fs0 – fs7</code>), which is also the minimum that OpenGL ES 2 guarantees.
         *  The "baselineConstrained" profile supports only four. */
        public static const MAX_NUM_TEXTURES:int = 8;

        // "baselineConstrained" rejects shaders with more than three indirect texture reads,
        // and each texture after the first one counts as such a read.
        private static const MAX_NUM_TEXTURES_CONSTRAINED:int = 4;

        private var _textures:Vector.<Texture>;
        private var _maxNumTextures:int;

        private static var sMaxTextures:int = 4;
        private static var sTextureIndexMap:Array = [];

        /** The maximum number of textures that are batched into one draw call; values are clamped
         *  to the range <code>1 – MAX_NUM_TEXTURES</code>. In baseline profiles, each fragment
         *  samples all textures of its batch, so higher values cost more fill rate there.
         *  @default 4 */
        public static function get maxTextures():int { return sMaxTextures; }
        public static function set maxTextures(value:int):void
        {
            sMaxTextures = value < 1 ? 1 : (value > MAX_NUM_TEXTURES ? MAX_NUM_TEXTURES : value);
        }

        public function MultiTextureStyle()
        {
            var starling:Starling = Starling.current;
            var constrained:Boolean = starling && starling.profile == "baselineConstrained";

            _textures = new <Texture>[];
            _maxNumTextures = constrained ? MAX_NUM_TEXTURES_CONSTRAINED : MAX_NUM_TEXTURES;
        }

        /** @private */
        override public function createEffect():MeshEffect
        {
            return new MultiTextureEffect();
        }

        /** @private */
        override public function updateEffect(effect:MeshEffect, state:RenderState):void
        {
            var targetEffect:MultiTextureEffect = effect as MultiTextureEffect;
            var numTextures:int = _textures.length;

            targetEffect.clearTextures();

            super.updateEffect(effect, state);

            for (var i:int = 0; i < numTextures; ++i)
                targetEffect.setTextureAt(i, _textures[i]);
        }

        /** @private */
        override public function canBatchWith(meshStyle:MeshStyle):Boolean
        {
            var mtStyle:MultiTextureStyle = meshStyle as MultiTextureStyle;
            if (mtStyle)
            {
                // meshes with different sampler settings can't share a draw call
                if (textureSmoothing != mtStyle.textureSmoothing ||
                    textureRepeat != mtStyle.textureRepeat)
                {
                    return false;
                }

                var i:int;
                var numTexturesToAdd:int = _textures.length;
                var maxTextures:int = sMaxTextures < _maxNumTextures ? sMaxTextures : _maxNumTextures;

                if (mtStyle.numTextures + numTexturesToAdd > maxTextures)
                {
                    var numSharedTextures:int = 0;

                    for (i = 0; i < numTexturesToAdd; ++i)
                        if (mtStyle.getTextureIndex(_textures[i]) != -1)
                            numSharedTextures++;

                    return mtStyle.numTextures + numTexturesToAdd - numSharedTextures
                        <= maxTextures;
                }
                else return true;
            }

            return false;
        }

        /** @private */
        override public function batchVertexData(target:MeshStyle, targetVertexID:int = 0,
                                                 matrix:Matrix = null, vertexID:int = 0,
                                                 numVertices:int = -1):void
        {
            super.batchVertexData(target, targetVertexID, matrix, vertexID, numVertices);

            var mtTarget:MultiTextureStyle = target as MultiTextureStyle;
            if (mtTarget)
            {
                var targetVertexData:VertexData = mtTarget.vertexData;
                var sourceVertexData:VertexData = this.vertexData;
                var numTextures:int = _textures.length;
                var sourceTexID:int, targetTexID:int;
                var i:int;

                if (numVertices < 0)
                    numVertices = vertexData.numVertices - vertexID;

                if (targetVertexID == 0)
                    mtTarget._textures.length = 0;

                for (i = 0; i < numTextures; ++i)
                {
                    var texture:Texture = _textures[i];
                    var textureIndexOnTarget:int = mtTarget.getTextureIndex(texture);

                    if (textureIndexOnTarget == -1)
                    {
                        textureIndexOnTarget = mtTarget.numTextures;
                        mtTarget.setTextureAt(texture, textureIndexOnTarget);
                    }

                    sTextureIndexMap[i] = textureIndexOnTarget;
                }

                for (i = 0; i < numVertices; ++i)
                {
                    // TODO: this runs per vertex every frame. For the common case of a mesh using
                    // a single texture, the source index is uniform - we could determine it once
                    // and skip the per-vertex reads (or skip entirely when the remap is identity),
                    // instead of tracking per-texture vertex regions.

                    if (numTextures == 0) sourceTexID = -1;
                    else sourceTexID = sourceVertexData.getFloat(vertexID + i, "texture");

                    if (sourceTexID == -1) targetTexID = -1;
                    else targetTexID = sTextureIndexMap[sourceTexID];

                    if (sourceTexID == -1 || sourceTexID != targetTexID)
                        targetVertexData.setFloat(targetVertexID + i, "texture", targetTexID);
                }

                sTextureIndexMap.length = 0;
            }
        }

        /** @private */
        override protected function onTargetAssigned(target:Mesh):void
        {
            _textures.length = 0;
            if (target.texture) _textures[0] = target.texture;
        }

        /** @private */
        override public function get vertexFormat():VertexDataFormat
        {
            return VERTEX_FORMAT;
        }

        /** @private */
        override public function set texture(value:Texture):void
        {
            if (value) _textures[0] = value;
            else _textures.length = 0;
            super.texture = value;
        }

        private function setTextureAt(texture:Texture, index:int):void
        {
            _textures[index] = texture;
        }

        private function getTextureIndex(texture:Texture):int
        {
            var numTextures:int = _textures.length;

            for (var i:int = 0; i < numTextures; ++i)
                if (_textures[i].root == texture.root) return i;

            return -1;
        }

        private function get numTextures():int { return _textures.length; }
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
    private var _textures:Vector.<Texture>;

    // How many constant registers the per-texture bounds occupy (one register holds four bounds).
    private static const sRegsPerBound:int = Math.ceil(MultiTextureStyle.MAX_NUM_TEXTURES / 4);

    // Fragment constant register layout: lower bounds, then upper bounds, then a "ones" vector.
    private static const sLowerBoundsReg:int = 0;
    private static const sUpperBoundsReg:int = sRegsPerBound;
    private static const sOnesReg:int        = 2 * sRegsPerBound;

    // The active texture for a vertex is the one whose index 'k' is closest to the interpolated
    // value in 'v2.x'. We select it via the half-open range [k - 0.5, k + 0.5) instead of a strict
    // equality check: the rasterizer interpolates 'v2.x' with limited precision, so an exact
    // comparison would fail on some GPUs and leave fragments untextured (flickering / artifacts).
    private static const sLowerBounds:Vector.<Number> = createBounds(-0.5);
    private static const sUpperBounds:Vector.<Number> = createBounds( 0.5);
    private static const sOnes:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];

    private static function createBounds(offset:Number):Vector.<Number>
    {
        var count:int = sRegsPerBound * 4;
        var result:Vector.<Number> = new Vector.<Number>(count, true);

        for (var i:int = 0; i < count; ++i)
            result[i] = i + offset;

        return result;
    }

    public function MultiTextureEffect()
    {
        _textures = new <Texture>[];
    }

    override protected function createProgram():Program
    {
        var vertexShader:Array = [
            "m44 op, va0, vc0", // 4x4 matrix transform to output clip-space
            "mov v0, va1     ", // pass texture coordinates to fragment program
            "mul v1, va2, vc4", // multiply alpha (vc4) with color (va2), pass to fp
            "mov v2, va3     "  // pass texture sampler index to fp
        ];

        var isBaseline:Boolean = Starling.current.profile.indexOf("baseline") != -1;
        var agalVersion:uint = isBaseline ? 1 : 2;
        var fragmentShader:Array = isBaseline ?
            createFragmentShaderForBaselineProfile(numTextures) :
            createFragmentShaderForStandardProfile(numTextures);

        return Program.fromSource(vertexShader.join("\n"), fragmentShader.join("\n"), agalVersion);
    }

    private function createFragmentShaderForBaselineProfile(numTextures:int):Array
    {
        // In baseline profile, if-statements are not available. Instead, we sample all textures
        // and mask all but the active one to zero, using range checks (see 'sLowerBounds').

        var fragmentShader:Array = [];

        if (numTextures == 0)
        {
            fragmentShader.push("mov ft4, fc" + sOnesReg); // no texture => white
        }
        else
        {
            for (var i:int = 0; i < numTextures; ++i)
            {
                fragmentShader.push(
                    tex("ft0", "v0", i, _textures[i]),
                    "sge ft1, v2.x, " + boundReg(sLowerBoundsReg, i), // v2.x >= i - 0.5 ?
                    "slt ft2, v2.x, " + boundReg(sUpperBoundsReg, i), // v2.x <  i + 0.5 ?
                    "mul ft1, ft1, ft2",  // combine to a 0/1 mask for this texture
                    "mul ft0, ft0, ft1"   // keep the texel only inside the range
                );
                fragmentShader.push(i == 0 ? "mov ft4, ft0" : "add ft4, ft4, ft0");
            }

            // vertices without a texture carry index -1, i.e. below the first range => white
            fragmentShader.push(
                "slt ft0, v2.x, " + boundReg(sLowerBoundsReg, 0),
                "add ft4, ft4, ft0"
            );
        }

        fragmentShader.push("mul oc, ft4, v1"); // multiply color with texel color
        return fragmentShader;
    }

    private function createFragmentShaderForStandardProfile(numTextures:int):Array
    {
        // In standard profile, we can pick the correct texture via if-operations, which is more
        // efficient (fewer texture look-ups). 'ft0' starts white so untextured vertices (index -1,
        // matching no range) are rendered as pure vertex color.

        var fragmentShader:Array = ["mov ft0, fc" + sOnesReg];

        for (var i:int = 0; i < numTextures; ++i)
        {
            fragmentShader.push(
                "ifg v2.x, " + boundReg(sLowerBoundsReg, i), // v2.x > i - 0.5 ?
                "ifl v2.x, " + boundReg(sUpperBoundsReg, i), // v2.x < i + 0.5 ?
                tex("ft0", "v0", i, _textures[i]),
                "eif",
                "eif"
            );
        }

        fragmentShader.push("mul oc, ft0, v1"); // multiply color with texel color
        return fragmentShader;
    }

    // Returns the AGAL address of texture 'index's bound within the given register block,
    // e.g. "fc0.x" or "fc1.z" – so the bounds can span more than one constant register.
    private function boundReg(baseReg:int, index:int):String
    {
        var register:int = baseReg + int(index / 4);
        var component:String = "xyzw".charAt(index % 4);
        return "fc" + register + "." + component;
    }

    override protected function beforeDraw(context:Context3D):void
    {
        super.beforeDraw(context);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, sLowerBoundsReg, sLowerBounds);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, sUpperBoundsReg, sUpperBounds);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, sOnesReg, sOnes);

        vertexFormat.setVertexBufferAt(1, vertexBuffer, "texCoords");
        vertexFormat.setVertexBufferAt(3, vertexBuffer, "texture");

        for (var i:int = 0; i < numTextures; ++i)
        {
            var texture:Texture = _textures[i];
            RenderUtil.setSamplerStateAt(i, texture.mipMapping, textureSmoothing, textureRepeat);
            context.setTextureAt(i, texture.base);
        }
    }

    override protected function afterDraw(context:Context3D):void
    {
        for (var i:int = 0; i < numTextures; ++i)
            context.setTextureAt(i, null);

        context.setVertexBufferAt(1, null);
        context.setVertexBufferAt(3, null);

        super.afterDraw(context);
    }

    override public function get vertexFormat():VertexDataFormat
    {
        return MultiTextureStyle.VERTEX_FORMAT;
    }

    override protected function get programVariantName():uint
    {
        var numTextures:int = _textures.length;
        var bits:uint = 0;

        // four bits per texture: with 'MAX_NUM_TEXTURES' textures, that fills all 32 bits
        for (var i:int = 0; i < numTextures; ++i)
            bits |= RenderUtil.getTextureVariantBits(_textures[i]) << (4 * i);

        return bits;
    }

    override public function set texture(value:Texture):void
    {
        if (value) _textures[0] = value;
        super.texture = value;
    }

    public function setTextureAt(index:int, texture:Texture):void
    {
        _textures[index] = texture;
    }

    public function clearTextures():void
    {
        _textures.length = 0;
    }

    public function get numTextures():int { return _textures.length; }
}
