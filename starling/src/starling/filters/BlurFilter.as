// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import starling.core.Starling;
    import starling.rendering.FilterEffect;
    import starling.rendering.Painter;
    import starling.textures.Texture;

    /** The BlurFilter applies a Gaussian blur to an object. The strength of the blur can be
     *  set for x- and y-axis separately. */
    public class BlurFilter extends FragmentFilter
    {
        private var _blurX:Number;
        private var _blurY:Number;

        /** Create a new BlurFilter.
         *
         *  <p>The blur is rendered for each direction (x and y) separately; the number of
         *  draw calls add up. The blur value itself is internally multiplied with the current
         *  <code>contentScaleFactor</code> in order to guarantee a consistent look on HiDPI
         *  displays (dubbed 'totalBlur' below).</p>
         *
         *  <p>The number of draw calls per blur value is the following:</p>
         *  <ul><li>totalBlur &lt;= 1: 1 draw call</li>
         *      <li>totalBlur &lt;= 2: 2 draw calls</li>
         *      <li>totalBlur &lt;= 4: 3 draw calls</li>
         *      <li>totalBlur &lt;= 8: 4 draw calls</li>
         *      <li>... etc.</li>
         *  </ul>
         */
        public function BlurFilter(blurX:Number=1.0, blurY:Number=1.0, resolution:Number=1.0)
        {
            _blurX = Math.abs(blurX);
            _blurY = Math.abs(blurY);
            this.resolution = resolution;
        }

        /** @private */
        override public function process(painter:Painter, helper:IFilterHelper,
                                         input0:Texture = null, input1:Texture = null,
                                         input2:Texture = null, input3:Texture = null):Texture
        {
            var effect:BlurEffect = this.effect as BlurEffect;

            if (_blurX == 0 && _blurY == 0)
            {
                effect.strength = 0;
                return super.process(painter, helper, input0);
            }

            var inTexture:Texture;
            var outTexture:Texture = input0;
            var strengthX:Number = totalBlurX;
            var strengthY:Number = totalBlurY;

            effect.direction = BlurEffect.HORIZONTAL;

            while (strengthX > 0)
            {
                effect.strength = strengthX;

                inTexture = outTexture;
                outTexture = super.process(painter, helper, inTexture);

                if (inTexture != input0) helper.putTexture(inTexture);
                if (strengthX <= 1) break; else strengthX /= 2;
            }

            effect.direction = BlurEffect.VERTICAL;

            while (strengthY > 0)
            {
                effect.strength = strengthY;

                inTexture = outTexture;
                outTexture = super.process(painter, helper, inTexture);

                if (inTexture != input0) helper.putTexture(inTexture);
                if (strengthY <= 1) break; else strengthY /= 2;
            }

            return outTexture;
        }

        /** @private */
        override protected function createEffect():FilterEffect
        {
            return new BlurEffect();
        }

        /** @private */
        override public function set resolution(value:Number):void
        {
            super.resolution = value;
            updatePadding();
        }

        private function updatePadding():void
        {
            var paddingX:Number = _blurX ? (totalBlurX * 3 + 2) / resolution : 0;
            var paddingY:Number = _blurY ? (totalBlurY * 3 + 2) / resolution : 0;

            padding.setTo(paddingX, paddingX, paddingY, paddingY);
        }

        /** @private */
        override public function get numPasses():int
        {
            if (_blurX == 0 && _blurY == 0) return 1;
            else return getNumPasses(totalBlurX) + getNumPasses(totalBlurY);
        }

        private static function getNumPasses(blur:Number):int
        {
            var numPasses:int = 1;
            while (blur > 1) { numPasses += 1; blur /= 2; }
            return numPasses;
        }

        /** The blur values scaled by the current contentScaleFactor. */
        private function get totalBlurX():Number { return _blurX * Starling.contentScaleFactor; }
        private function get totalBlurY():Number { return _blurY * Starling.contentScaleFactor; }

        /** The blur factor in x-direction. */
        public function get blurX():Number { return _blurX; }
        public function set blurX(value:Number):void
        {
            _blurX = Math.abs(value);
            updatePadding();
        }

        /** The blur factor in y-direction. */
        public function get blurY():Number { return _blurY; }
        public function set blurY(value:Number):void
        {
            _blurY = Math.abs(value);
            updatePadding();
        }
    }
}

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

import starling.rendering.FilterEffect;
import starling.rendering.Program;

class BlurEffect extends FilterEffect
{
    public static const HORIZONTAL:String = "horizontal";
    public static const VERTICAL:String = "vertical";

    private var _strength:Number;
    private var _direction:String;

    private static const sTmpWeights:Vector.<Number> = new <Number>[0, 0, 0, 0, 0];
    private static const sWeights:Vector.<Number> = new <Number>[0, 0, 0, 0];
    private static const sOffsets:Vector.<Number> = new <Number>[0, 0, 0, 0];

    /** Creates a new BlurEffect. */
    public function BlurEffect():void
    {
        _strength = 0.0;
        _direction = HORIZONTAL;
    }

    override protected function createProgram():Program
    {
        if (_strength == 0) return super.createProgram();

        // vc4.xy - offset1
        // vc4.zw - offset2

        var vertexShader:String = [
            "m44 op, va0, vc0      ", // 4x4 matrix transform to output space
            "mov v0, va1           ", // pos:  0 (center)

            "add v1,  va1, vc4.xyww", // pos: +1
            "sub v2,  va1, vc4.xyww", // pos: -1

            "add v3,  va1, vc4.zwxx", // pos: +2
            "sub v4,  va1, vc4.zwxx"  // pos: -2
        ].join("\n");

        // v0-v6 - kernel positions
        // fs0   - input texture
        // fc0   - weight data
        // ft0-4 - pixel color from texture
        // ft5   - output color

        var fragmentShader:String = [
            tex("ft0", "v0", 0, texture),    // read center pixel
            "mul ft5, ft0, fc0.xxxx       ", // multiply with center weight

            tex("ft1", "v1", 0, texture),    // read pixel +1
            "mul ft1, ft1, fc0.yyyy       ", // multiply with weight
            "add ft5, ft5, ft1            ", // add to output color

            tex("ft2", "v2", 0, texture),    // read pixel -1
            "mul ft2, ft2, fc0.yyyy       ", // multiply with weight
            "add ft5, ft5, ft2            ", // add to output color

            tex("ft3", "v3", 0, texture),    // read pixel +2
            "mul ft3, ft3, fc0.zzzz       ", // multiply with weight
            "add ft5, ft5, ft3            ", // add to output color

            tex("ft4", "v4", 0, texture),    // read pixel -2
            "mul ft4, ft4, fc0.zzzz       ", // multiply with weight
            "add  oc, ft5, ft4            "  // add to output color
        ].join("\n");

        return Program.fromSource(vertexShader, fragmentShader);
    }

    override protected function beforeDraw(context:Context3D):void
    {
        super.beforeDraw(context);

        if (_strength)
        {
            updateParameters();

            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,   4, sOffsets);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sWeights);
        }
    }

    private function updateParameters():void
    {
        var offset1:Number, offset2:Number;
        var pixelSize:Number = 1.0 / (_direction == HORIZONTAL ?
                texture.root.nativeWidth : texture.root.nativeHeight);

        if (_strength <= 1)
        {
            // algorithm described here:
            // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
            //
            // To support the baseline constrained profile, we can only make 5 texture look-ups
            // in the fragment shader. By making use of linear texture sampling, we can produce
            // similar output to what would be 9 look-ups.

            var sigma:Number = _strength * 2;
            var twoSigmaSq:Number = 2 * sigma * sigma;
            var multiplier:Number = 1.0 / Math.sqrt(twoSigmaSq * Math.PI);

            // get weights on the exact pixels (sTmpWeights) and calculate sums (sWeights)

            for (var i:int=0; i<5; ++i)
                sTmpWeights[i] = multiplier * Math.exp(-i*i / twoSigmaSq);

            sWeights[0] = sTmpWeights[0];
            sWeights[1] = sTmpWeights[1] + sTmpWeights[2];
            sWeights[2] = sTmpWeights[3] + sTmpWeights[4];

            // normalize weights so that sum equals "1.0"

            var weightSum:Number = sWeights[0] + 2 * sWeights[1] + 2 * sWeights[2];
            var invWeightSum:Number = 1.0 / weightSum;

            sWeights[0] *= invWeightSum;
            sWeights[1] *= invWeightSum;
            sWeights[2] *= invWeightSum;

            // calculate intermediate offsets

            offset1 = (    sTmpWeights[1] + 2 * sTmpWeights[2]) / sWeights[1];
            offset2 = (3 * sTmpWeights[3] + 4 * sTmpWeights[4]) / sWeights[2];
        }
        else
        {
            // All other passes look up 5 texels with a standard gauss distribution and bigger
            // offsets. In itself, this looks as if the object was drawn multiple times; combined
            // with the last pass (strength <= 1), though, the result is a very strong blur.

            sWeights[0] = 0.29412;
            sWeights[1] = 0.23529;
            sWeights[2] = 0.11765;

            offset1 = _strength * 1.3; // the additional '0.3' compensate the difference between
            offset2 = _strength * 2.3; // the two gauss distributions.
        }

        // depending on pass, we move in x- or y-direction

        if (_direction == HORIZONTAL)
        {
            sOffsets[0] = offset1 * pixelSize; sOffsets[1] = 0;
            sOffsets[2] = offset2 * pixelSize; sOffsets[3] = 0;
        }
        else
        {
            sOffsets[0] = 0; sOffsets[1] = offset1 * pixelSize;
            sOffsets[2] = 0; sOffsets[3] = offset2 * pixelSize;
        }
    }

    override protected function get programVariantName():uint
    {
        return super.programVariantName | (_strength ? 1 << 4 : 0);
    }

    public function get direction():String { return _direction; }
    public function set direction(value:String):void { _direction = value; }

    public function get strength():Number { return _strength; }
    public function set strength(value:Number):void { _strength = value; }
}