// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
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

    public class BlurFilter extends FragmentFilter
    {
        private const MAX_SIGMA:Number = 2.0;
        private const SAMPLE_1:Number  = 1.3;
        private const SAMPLE_2:Number  = 3.1;
        
        private var mNormalProgram:Program3D;
        private var mTintedProgram:Program3D;
        
        private var mOffsets:Vector.<Number> = new <Number>[0, 0, 0, 0];
        private var mWeights:Vector.<Number> = new <Number>[0, 0, 0, 0];
        private var mColor:Vector.<Number>   = new <Number>[1, 1, 1, 1];
        
        private var mBlurX:Number;
        private var mBlurY:Number;
        private var mScale:Number;
        
        public function BlurFilter(blurX:Number, blurY:Number)
        {
            mScale = Starling.contentScaleFactor;
            mBlurX = blurX * mScale;
            mBlurY = blurY * mScale;
            updateMarginsAndPasses();
        }
        
        public override function dispose():void
        {
            disposePrograms();
            super.dispose();
        }
        
        private function disposePrograms():void
        {
            if (mNormalProgram) mNormalProgram.dispose();
            if (mTintedProgram) mTintedProgram.dispose();
        }
        
        protected override function createPrograms():void
        {
            disposePrograms();
            mNormalProgram = createProgram(false);
            mTintedProgram = createProgram(true);
        }
        
        private function createProgram(tinted:Boolean):Program3D
        {
            // vc0-3 - mvp matrix
            // vc4   - kernel offset
            // va0   - position 
            // va1   - texture coords
            
            var vertexProgramCode:String =
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
            // ft0   - pixel color from texture
            // ft1   - output color
            
            var fragmentProgramCode:String =
                "tex ft0,  v0, fs0 <2d, clamp, linear, mipnone> \n" +  // read center pixel
                "mul ft1, ft0, fc0.xxxx                         \n" +  // multiply with center weight
                
                "tex ft0,  v1, fs0 <2d, clamp, linear, mipnone> \n" +  // read texture
                "mul ft0, ft0, fc0.zzzz                         \n" +  // multiply with weight
                "add ft1, ft1, ft0                              \n" +  // add to output color
                
                "tex ft0,  v2, fs0 <2d, clamp, linear, mipnone> \n" +  // read texture
                "mul ft0, ft0, fc0.yyyy                         \n" +  // multiply with weight
                "add ft1, ft1, ft0                              \n" +  // add to output color

                "tex ft0,  v3, fs0 <2d, clamp, linear, mipnone> \n" +  // read texture
                "mul ft0, ft0, fc0.yyyy                         \n" +  // multiply with weight
                "add ft1, ft1, ft0                              \n" +  // add to output color

                "tex ft0,  v4, fs0 <2d, clamp, linear, mipnone> \n" +  // read texture
                "mul ft0, ft0, fc0.zzzz                         \n";   // multiply with weight

            if (tinted) fragmentProgramCode +=
                "add ft1, ft1, ft0                              \n" +  // add to output color
                "mov ft1.xyz, fc1.xyz                           \n" +  // set color
                "mul ft1.w, ft1.w, fc1.w                        \n" +  // multiply alpha
                "mov  oc, ft1                                   \n";   // copy to output 
            
            else fragmentProgramCode +=
                "add  oc, ft1, ft0                              \n";   // add to output color
            
            return assembleAgal(fragmentProgramCode, vertexProgramCode);
        }
        
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            // 
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            
            updateParameters(pass, texture.width * mScale, texture.height * mScale);
            
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,   4, mOffsets);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mWeights);
            
            if (pass == numPasses - 1 && isTinted)
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
            // algorithm inspired by: 
            // http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
            // 
            // To run in constrained mode, we can only make 5 texture lookups in the fragment
            // shader. By making use of linear texture sampling, we can produce similar output
            // to what would be 9 lookups.
            //
            // Instead of sampling at "-2 -1 0 +1 +2", we sample at "-3.1 -1.3 0 +1.3 +3.1"
            // That way, the two side pixels contain values of pixels 1 to 4 in both directions.
            
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
            
            var offset1:Number = SAMPLE_1 * pixelSize;
            var offset2:Number = SAMPLE_2 * pixelSize;
            
            mWeights[0] = multiplier;
            mWeights[1] = multiplier * Math.exp(-SAMPLE_1*SAMPLE_1 / twoSigmaSq);
            mWeights[2] = multiplier * Math.exp(-SAMPLE_2*SAMPLE_2 / twoSigmaSq);

            // normalize weights so that sum equals "1.0"
            
            var weightSum:Number = mWeights[0] + 2*mWeights[1] + 2*mWeights[2];
            var invWeightSum:Number = 1.0 / weightSum;
            
            mWeights[0] *= invWeightSum;
            mWeights[1] *= invWeightSum;
            mWeights[2] *= invWeightSum;
                        
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
            
            numPasses  = Math.ceil(mBlurX) + Math.ceil(mBlurY);
            marginLeft = marginRight = 4 + Math.ceil(mBlurX);
            marginTop  = marginBottom = 4 + Math.ceil(mBlurY); 
        }
        
        private function get isTinted():Boolean 
        { 
            return mColor[0] != 1.0 || mColor[1] != 1.0 || 
                   mColor[2] != 1.0 || mColor[3] != 1.0;
        }
        
        public function get blurX():Number { return mBlurX / mScale; }
        public function set blurX(value:Number):void 
        { 
            mBlurX = value * mScale; 
            updateMarginsAndPasses(); 
        }
        
        public function get blurY():Number { return mBlurY / mScale; }
        public function set blurY(value:Number):void 
        { 
            mBlurY = value * mScale; 
            updateMarginsAndPasses(); 
        }
        
        public function get color():uint 
        { 
            return Color.rgb(mColor[0] * 255, mColor[1] * 255, mColor[2] * 255); 
        }
        
        public function set color(value:uint):void 
        {
            mColor[0] = Color.getRed(value)   / 255.0;
            mColor[1] = Color.getGreen(value) / 255.0;
            mColor[2] = Color.getBlue(value)  / 255.0;
        }
        
        public function get alpha():Number { return mColor[3]; }
        public function set alpha(value:Number):void { mColor[3] = value; }
    }
}