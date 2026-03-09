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
	import starling.textures.ConcreteTexture;

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

		private static var _MAX_NUM_TEXTURES:int = 5;
		
        /** Maximum number of textures that can be batched. */
        public static function get MAX_NUM_TEXTURES():int { return _MAX_NUM_TEXTURES; }

        private var _dirty:Boolean = true;
        private const _textures:Vector.<Texture> = new Vector.<Texture>();

        private static var sMaxTextures:int = 2;
        private static const sTextureIndexMap:Vector.<int> = new Vector.<int>();

        /** Maximum number of textures to be batched, default 2. */
        public static function get maxTextures():int { return sMaxTextures; }
        public static function set maxTextures(value:int):void
        {
			if (!_initDone) init();
            value = value < 1 ? 1 : value;
            sMaxTextures = value > _MAX_NUM_TEXTURES ? _MAX_NUM_TEXTURES : value;
        }
		
		private static var _TEXTURE_INDEX_FACTOR:Number;
		
		private static var _initDone:Boolean = false;
		public static function init():void
		{
			if (_initDone) return;
			
			if (Starling.current.profile.indexOf("baseline") != -1)
			{
				_MAX_NUM_TEXTURES = 5;
				_TEXTURE_INDEX_FACTOR = 4.0;
			}
			else
			{
				_MAX_NUM_TEXTURES = 16;
				_TEXTURE_INDEX_FACTOR = 1.0;
			}
			
			_initDone = true;
		}

        public function MultiTextureStyle() 
		{
			if (!_initDone) init();
		}

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
			var count:int;

            if (matrix && _dirty)
            {
				count = vertexData.numVertices;
				for (i = 0; i < count; i++)
                    vertexData.setFloat(i, "texture", 0);
                
                _dirty = false;
            }

            super.batchVertexData(targetStyle, targetVertexID, matrix, vertexID, numVertices);

            const mtTarget:MultiTextureStyle = targetStyle as MultiTextureStyle;

            if (mtTarget)
            {
                var dirty:Boolean = false;
				count = numTextures;
                for (i = 0; i < count; i++)
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
                            "texture") * _TEXTURE_INDEX_FACTOR);
                        const targetTexID:int = sTextureIndexMap[sourceTexID];

                        if (sourceTexID != targetTexID)
                            targetVertexData.setFloat(targetVertexID + i, "texture",
                                targetTexID / _TEXTURE_INDEX_FACTOR);
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
			if (this.texture.root == texture) return 0;
			const count:int = _textures.length;
			for (var i:int = 0; i < count; i++)
				if (_textures[i] == texture) return i + 1;
			
            return -1;
        }

        // Returns an element of the shared texture list.
        [Inline]
        private function getTexture(index:int):Texture
        {
            return index > 0 ? _textures[index - 1] : texture.root;
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

    private static const baselineTextureIndices:Vector.<Number> = new <Number>[
        0.125, 0.375, 0.625, 0.875,
        1, 0, 0, 0
    ];
	
	private static const textureIndices:Vector.<Number> = new <Number>[
		0.5, 1.5, 2.5, 3.5,
		4.5, 5.5, 6.5, 7.5,
		8.5, 9.5, 10.5, 11.5,
		12.5, 13.5, 14.5, 15.5
	];
	
	private var _multiTexturingConstants:Vector.<Number>;

    public function MultiTextureEffect()
    {
        _isBaseline = Starling.current.profile.indexOf("baseline") != -1;
		if (_isBaseline) 
		{
			_multiTexturingConstants = baselineTextureIndices;
		}
		else
		{
			_multiTexturingConstants = textureIndices;
		}
    }

    override protected function get programVariantName():uint
    {
        var bits:uint = super.programVariantName;

        for (var i:int = 0; i < textures.length; i++)
			bits |= RenderUtil.getTextureVariantBits(textures[i]) << (i + 4);
        
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
				textures.unshift(texture); // add base texture temporarily
				multiTex(fragmentShader, textures);
				textures.shift(); // remove base texture
				
                fragmentShader.push(
                    "mul oc, ft0, v1"       // multiply color with texel color
                );
            }
            return Program.fromSource(vertexShader, fragmentShader.join("\n"),
                _isBaseline ? 1 : 2);
        }

        return super.createProgram();
    }
	
	protected function multiTex(data:Vector.<String>, textures:Vector.<Texture>, numTextures:int = 0, textureOffset:int = 0, textureRegister:String = "ft0", textureIndexSource:String = "v2.x", constantsStartIndex:int = 0):void
	{
		if (numTextures == 0) numTextures = textures.length;
		
		if (numTextures <= 2)
		{
			if (numTextures == 2)
			{
				checkTexIndex(data, textureOffset, textureIndexSource, constantsStartIndex);
				data[data.length] = RenderUtil.createAGALTexOperation(textureRegister, "v0", textureOffset, textures[textureOffset]);
				data[data.length] = "els";
				data[data.length] = RenderUtil.createAGALTexOperation(textureRegister, "v0", textureOffset + 1, textures[textureOffset + 1]);
				data[data.length] = "eif";
			}
			else
			{
				data[data.length] = RenderUtil.createAGALTexOperation(textureRegister, "v0", textureOffset, textures[textureOffset]);
			}
		}
		else
		{
			var halfNumTextures:int = Math.ceil(numTextures / 2);
			var remainingTextures:int = numTextures - halfNumTextures;
			
			checkTexIndex(data, textureOffset + halfNumTextures - 1, textureIndexSource, constantsStartIndex);
			multiTex(data, textures, halfNumTextures, textureOffset, textureRegister, textureIndexSource, constantsStartIndex);
			data[data.length] = "els";
			multiTex(data, textures, remainingTextures, textureOffset + halfNumTextures, textureRegister, textureIndexSource, constantsStartIndex);
			data[data.length] = "eif";
		}
	}
	
	protected function checkTexIndex(data:Vector.<String>, textureNum:int, textureIndexSource:String, constantsStartIndex:int):void
	{
		var constantIndex:int = constantsStartIndex + Math.floor(textureNum / 4);
		var constantSubIndex:int = textureNum % 4;
		var constant:String;
		
		switch (constantSubIndex)
		{
			case 0 :
				constant = " fc" + constantIndex + ".x";
				break;
			
			case 1 :
				constant = " fc" + constantIndex + ".y";
				break;
			
			case 2 :
				constant = " fc" + constantIndex + ".z";
				break;
			
			case 3 :
				constant = " fc" + constantIndex + ".w";
				break;
			
			default :
				throw new Error("incorrect constant sub index");
		}
		
		data[data.length] = "ifl " + textureIndexSource + constant;
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
                0, _multiTexturingConstants, _isBaseline ? -1 : Math.ceil((length + 1) / 4));
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
