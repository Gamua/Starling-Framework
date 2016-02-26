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
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;
    
    import starling.core.Starling;
    import starling.textures.Texture;
    import starling.utils.Color;

    /** The BlurFilter applies a Gaussian blur to an object. The strength of the blur can be
     *  set for x- and y-axis separately (always relative to the stage).
     *  A blur filter can also be set up as a drop shadow or glow filter. Use the respective
     *  static methods to create such a filter.
     */
    public class BlurFilter extends FragmentFilter
    {
        private static const NORMAL_PROGRAM_NAME:String = "BF_n";
        private static const TINTED_PROGRAM_NAME:String = "BF_t";
        private static const MAX_SIGMA:Number = 2.0;
        
        private var mNormalProgram:Program3D;
        private var mTintedProgram:Program3D;
        
        private var mOffsets:Vector.<Number> = new <Number>[0, 0, 0, 0];
        private var mWeights:Vector.<Number> = new <Number>[0, 0, 0, 0];
        private var mColor:Vector.<Number>   = new <Number>[1, 1, 1, 1];
        
        private var mBlurX:Number;
        private var mBlurY:Number;
        private var mUniformColor:Boolean;
        
        /** helper object */
        private var sTmpWeights:Vector.<Number> = new Vector.<Number>(5, true);
        
        /** Create a new BlurFilter. For each blur direction, the number of required passes is
         *  <code>Math.ceil(blur)</code>. 
         *  
         *  <ul><li>blur = 0.5: 1 pass</li>  
         *      <li>blur = 1.0: 1 pass</li>
         *      <li>blur = 1.5: 2 passes</li>
         *      <li>blur = 2.0: 2 passes</li>
         *      <li>etc.</li>
         *  </ul>
         *  
         *  <p>Instead of raising the number of passes, you should consider lowering the resolution.
         *  A lower resolution will result in a blurrier image, while reducing the rendering
         *  cost.</p>
         */
        public function BlurFilter(blurX:Number=1, blurY:Number=1, resolution:Number=1)
        {
            super(1, resolution);
            mBlurX = blurX;
            mBlurY = blurY;
            updateMarginsAndPasses();
        }
        
        /** Creates a blur filter that is set up for a drop shadow effect. */
        public static function createDropShadow(distance:Number=4.0, angle:Number=0.785, 
                                                color:uint=0x0, alpha:Number=0.5, blur:Number=1.0, 
                                                resolution:Number=0.5):BlurFilter
        {
            var dropShadow:BlurFilter = new BlurFilter(blur, blur, resolution);
            dropShadow.offsetX = Math.cos(angle) * distance;
            dropShadow.offsetY = Math.sin(angle) * distance;
            dropShadow.mode = FragmentFilterMode.BELOW;
            dropShadow.setUniformColor(true, color, alpha);
            return dropShadow;
        }
        
        /** Creates a blur filter that is set up for a glow effect. */
        public static function createGlow(color:uint=0xffff00, alpha:Number=1.0, blur:Number=1.0,
                                          resolution:Number=0.5):BlurFilter
        {
            var glow:BlurFilter = new BlurFilter(blur, blur, resolution);
            glow.mode = FragmentFilterMode.BELOW;
            glow.setUniformColor(true, color, alpha);
            return glow;
        }
        
        /** @private */
        protected override function createPrograms():void
        {
            mNormalProgram = createProgram(false);
            mTintedProgram = createProgram(true);
        }
        
        private function createProgram(tinted:Boolean):Program3D
        {
            var programName:String = tinted ? TINTED_PROGRAM_NAME : NORMAL_PROGRAM_NAME;
            var target:Starling = Starling.current;
            
            if (target.hasProgram(programName))
                return target.getProgram(programName);
            
            // vc0-3 - mvp matrix
            // vc4   - kernel offset
            // va0   - position 
            // va1   - texture coords
            
            var vertexShader:String =
                "m44 op, va0, vc0       \n" + // 4x4 matrix transform to output space
                "mov v0, va1            \n" + // pos:  0 |
                "sub v1, va1, vc4.zwxx  \n" + // pos: -2 |
                "sub v2, va1, vc4.xyxx  \n" + // pos: -1 | --> kernel positions
                "add v3, va1, vc4.xyxx  \n" + // pos: +1 |     (only 1st two parts are relevant)
                "add v4, va1, vc4.zwxx  \n";  // pos: +2 |
            
            // v0-v4 - kernel position
            // fs0   - input texture
            // fc0   - weight data
            // fc1   - color (optional)
            // ft0-4 - pixel color from texture
            // ft5   - output color
            
            var fragmentShader:String =
                "tex ft0,  v0, fs0 <2d, clamp, linear, mipnone> \n" +  // read center pixel
                "mul ft5, ft0, fc0.xxxx                         \n" +  // multiply with center weight
                
                "tex ft1,  v1, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel -2
                "mul ft1, ft1, fc0.zzzz                         \n" +  // multiply with weight
                "add ft5, ft5, ft1                              \n" +  // add to output color
                
                "tex ft2,  v2, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel -1
                "mul ft2, ft2, fc0.yyyy                         \n" +  // multiply with weight
                "add ft5, ft5, ft2                              \n" +  // add to output color

                "tex ft3,  v3, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel +1
                "mul ft3, ft3, fc0.yyyy                         \n" +  // multiply with weight
                "add ft5, ft5, ft3                              \n" +  // add to output color

                "tex ft4,  v4, fs0 <2d, clamp, linear, mipnone> \n" +  // read pixel +2
                "mul ft4, ft4, fc0.zzzz                         \n";   // multiply with weight

            if (tinted) fragmentShader +=
                "add ft5, ft5, ft4                              \n" + // add to output color
                "mul ft5.xyz, fc1.xyz, ft5.www                  \n" + // set rgb with correct alpha
                "mul oc, ft5, fc1.wwww                          \n";  // multiply alpha
            
            else fragmentShader +=
                "add  oc, ft5, ft4                              \n";   // add to output color
            
            return target.registerProgramFromSource(programName, vertexShader, fragmentShader);
        }
        
        /** @private */
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            // 
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            
            updateParameters(pass, texture.nativeWidth, texture.nativeHeight);
            
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,   4, mOffsets);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mWeights);
            
            if (mUniformColor && pass == numPasses - 1)
            {
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, mColor);
                context.setProgram(mTintedProgram);
            }
            else
            {
                context.setProgram(mNormalProgram);
            }
        }
        
        private function updateParameters(pass:int, textureWidth:int, textureHeight:int):void
        {
            // algorithm described here: 
            // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
            // 
            // To run in constrained mode, we can only make 5 texture lookups in the fragment
            // shader. By making use of linear texture sampling, we can produce similar output
            // to what would be 9 lookups.
            
            var sigma:Number;
            var horizontal:Boolean = pass < mBlurX;
            var pixelSize:Number;
            
            if (horizontal)
            {
                sigma = Math.min(1.0, mBlurX - pass) * MAX_SIGMA;
                pixelSize = 1.0 / textureWidth; 
            }
            else
            {
                sigma = Math.min(1.0, mBlurY - (pass - Math.ceil(mBlurX))) * MAX_SIGMA;
                pixelSize = 1.0 / textureHeight;
            }
            
            const twoSigmaSq:Number = 2 * sigma * sigma; 
            const multiplier:Number = 1.0 / Math.sqrt(twoSigmaSq * Math.PI);
            
            // get weights on the exact pixels (sTmpWeights) and calculate sums (mWeights)
            
            for (var i:int=0; i<5; ++i)
                sTmpWeights[i] = multiplier * Math.exp(-i*i / twoSigmaSq);
            
            mWeights[0] = sTmpWeights[0];
            mWeights[1] = sTmpWeights[1] + sTmpWeights[2]; 
            mWeights[2] = sTmpWeights[3] + sTmpWeights[4];

            // normalize weights so that sum equals "1.0"
            
            var weightSum:Number = mWeights[0] + 2*mWeights[1] + 2*mWeights[2];
            var invWeightSum:Number = 1.0 / weightSum;
            
            mWeights[0] *= invWeightSum;
            mWeights[1] *= invWeightSum;
            mWeights[2] *= invWeightSum;
            
            // calculate intermediate offsets
            
            var offset1:Number = (  pixelSize * sTmpWeights[1] + 2*pixelSize * sTmpWeights[2]) / mWeights[1];
            var offset2:Number = (3*pixelSize * sTmpWeights[3] + 4*pixelSize * sTmpWeights[4]) / mWeights[2];
            
            // depending on pass, we move in x- or y-direction
            
            if (horizontal) 
            {
                mOffsets[0] = offset1;
                mOffsets[1] = 0;
                mOffsets[2] = offset2;
                mOffsets[3] = 0;
            }
            else
            {
                mOffsets[0] = 0;
                mOffsets[1] = offset1;
                mOffsets[2] = 0;
                mOffsets[3] = offset2;
            }
        }
        
        private function updateMarginsAndPasses():void
        {
            if (mBlurX == 0 && mBlurY == 0) mBlurX = 0.001;
            
            numPasses = Math.ceil(mBlurX) + Math.ceil(mBlurY);
            marginX = (3 + Math.ceil(mBlurX)) / resolution;
            marginY = (3 + Math.ceil(mBlurY)) / resolution;
        }
        
        /** A uniform color will replace the RGB values of the input color, while the alpha
         *  value will be multiplied with the given factor. Pass <code>false</code> as the
         *  first parameter to deactivate the uniform color. */
        public function setUniformColor(enable:Boolean, color:uint=0x0, alpha:Number=1.0):void
        {
            mColor[0] = Color.getRed(color)   / 255.0;
            mColor[1] = Color.getGreen(color) / 255.0;
            mColor[2] = Color.getBlue(color)  / 255.0;
            mColor[3] = alpha;
            mUniformColor = enable;
        }
        
        /** The blur factor in x-direction (stage coordinates). 
         *  The number of required passes will be <code>Math.ceil(value)</code>. */
        public function get blurX():Number { return mBlurX; }
        public function set blurX(value:Number):void 
        { 
            mBlurX = value; 
            updateMarginsAndPasses(); 
        }
        
        /** The blur factor in y-direction (stage coordinates). 
         *  The number of required passes will be <code>Math.ceil(value)</code>. */
        public function get blurY():Number { return mBlurY; }
        public function set blurY(value:Number):void 
        { 
            mBlurY = value; 
            updateMarginsAndPasses(); 
        }
    }
}