// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

// Most of the color transformation math was taken from the excellent ColorMatrix class by
// Mario Klingemann: http://www.quasimondo.com/archives/000565.php -- THANKS!!!

package starling.filters
{
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Program3D;
    import flash.geom.Matrix;
    
    import starling.textures.Texture;

    public class ColorMatrixFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        
        private var mMatrix:Vector.<Number>; // offset in range 0-255
        private var mShaderMatrix:Vector.<Number>; // offset in range 0-1, changed order
        private var mMinColor:Vector.<Number> = new <Number>[0, 0, 0, 0.0001];
        
        private static const LUMA_R:Number = 0.299;
        private static const LUMA_G:Number = 0.587;
        private static const LUMA_B:Number = 0.114;
        
        /** helper objects */
        private static var sTmpMatrix1:Vector.<Number> = new Vector.<Number>(20, true);
        private static var sTmpMatrix2:Vector.<Number> = new <Number>[];
        
        public function ColorMatrixFilter(matrix:Vector.<Number>=null)
        {
            mMatrix = new Vector.<Number>(20);
            mShaderMatrix = new Vector.<Number>(20);
            
            this.matrix = matrix;
        }
        
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        protected override function createPrograms():void
        {
            // vc0-3: matrix
            // vc4:   offset
            
            var fragmentProgramCode:String =
                "tex ft0, v0,  fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
                "max ft0, ft0, fc5              \n" + // avoid division through zero in next step
                "div ft0.xyz, ft0.xyz, ft0.www  \n" + // restore original (non-PMA) RGB values
                "m44 ft0, ft0, fc0              \n" + // multiply color with 4x4 matrix
                "add ft0, ft0, fc4              \n" + // add offset
                "mul ft0.xyz, ft0.xyz, ft0.www  \n" + // multiply with alpha again (PMA)
                "mov oc, ft0                    \n";  // copy to output
            
            mShaderProgram = assembleAgal(fragmentProgramCode);
        }
        
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mShaderMatrix);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, mMinColor);
            context.setProgram(mShaderProgram);
        }
        
        // matrix manipulation helpers
        
        /** Changes the filter matrix back to the identity matrix. */
        public function reset():void
        {
            matrix = null;
        }

        /** Normalizes the matrix. */
        public function normalize():void
        {
            for (var i:int=0; i<4; ++i)
            {
                var sum:Number = 0;
                
                for (var j:int=0; j<4; ++j)
                    sum += mMatrix[int(i*5+j)] * mMatrix[int(i*5+j)];
                
                sum = 1.0 / Math.sqrt(sum);
                
                if (sum != 1.0)
                {
                    for (j=0; j<4; ++j)
                        mMatrix[int(i*5+j)] *= sum;
                }
            }
            
            updateShaderMatrix();
        }

        /** Invertes the image colors. */
        public function invert():void
        {
            concatValues(-1,  0,  0,  0, 255,
                          0, -1,  0,  0, 255,
                          0,  0, -1,  0, 255,
                          0,  0,  0,  1,   0);
        }
        
        /** Convertes the image to gray scale, using the given weight factors for each channel. */
        public function desaturate(red:Number=0.299, green:Number=0.587, blue:Number=0.114):void
        {
            concatValues(red, green, blue, 0, 0,
                         red, green, blue, 0, 0,
                         red, green, blue, 0, 0,
                         0, 0, 0, 1, 0);
        }
        
        /** Changes the saturation. Typical values are in the range (0, 2):
          * <ul>
          *   <li>0.0 means 0% saturation</li>
          *   <li>0.5 means 50% saturation</li>
          *   <li>1.0 means 100% saturation (no change)</li>
          *   <li>2.0 means 200% saturation</li>
          * </ul>
          */
        public function adjustSaturation(sat:Number):void
        {
            var invSat:Number = 1 - sat;
            var invLumR:Number = invSat * LUMA_R;
            var invLumG:Number = invSat * LUMA_G;
            var invLumB:Number = invSat * LUMA_B;
            
            concatValues((invLumR + sat), invLumG, invLumB, 0, 0,
                         invLumR, (invLumG + sat), invLumB, 0, 0,
                         invLumR, invLumG, (invLumB + sat), 0, 0,
                         0, 0, 0, 1, 0);
        }
        
        /** Changes the contrast. Use values in the range (-1, 1). "-1" means no contrast (gray),
         *  "0" means no change, and "1" means high contrast. */
        public function adjustContrast(r:Number, g:Number=NaN, b:Number=NaN):void
        {
            r = r + 1;
            g = isNaN(g) ? r : g + 1;
            b = isNaN(b) ? r : b + 1;
            
            concatValues(r, 0, 0, 0, (128 * (1-r)),
                         0, g, 0, 0, (128 * (1-g)),
                         0, 0, b, 0, (128 * (1-b)),
                         0, 0, 0, 1, 0);
        }
        
        /** Changes the brightness by adding an offset to the colors. "0" means no change,
         *  "255" will make every image white. */ 
        public function adjustBrightness(r:Number, g:Number=NaN, b:Number=NaN):void
        {
            if (isNaN(g)) g = r;
            if (isNaN(b)) b = r;
            
            concatValues(1, 0, 0, 0, r,
                         0, 1, 0, 0, g,
                         0, 0, 1, 0, b,
                         0, 0, 0, 1, 0);
        }
        
        /** Changes the hue of the image. Expects the angle in radians. */
        public function adjustHue(angle:Number):void
        {
            var cos:Number = Math.cos(angle);
            var sin:Number = Math.sin(angle);
            
            concatValues(
                ((LUMA_R + (cos * (1 - LUMA_R))) + (sin * -(LUMA_R))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * -(LUMA_G))), ((LUMA_B + (cos * -(LUMA_B))) + (sin * (1 - LUMA_B))), 0, 0,
                ((LUMA_R + (cos * -(LUMA_R))) + (sin * 0.143)), ((LUMA_G + (cos * (1 - LUMA_G))) + (sin * 0.14)), ((LUMA_B + (cos * -(LUMA_B))) + (sin * -0.283)), 0, 0,
                ((LUMA_R + (cos * -(LUMA_R))) + (sin * -((1 - LUMA_R)))), ((LUMA_G + (cos * -(LUMA_G))) + (sin * LUMA_G)), ((LUMA_B + (cos * (1 - LUMA_B))) + (sin * LUMA_B)), 0, 0,
                0, 0, 0, 1, 0);
        }
        
        /** Concatenates the current matrix with another one. */
        public function concat(matrix:Vector.<Number>):void
        {
            var i:int = 0;

            for (var y:int=0; y<4; ++y)
            {
                for (var x:int=0; x<5; ++x)
                {
                    sTmpMatrix1[int(i+x)] = 
                        matrix[i]        * mMatrix[x]           +
                        matrix[int(i+1)] * mMatrix[int(x +  5)] +
                        matrix[int(i+2)] * mMatrix[int(x + 10)] +
                        matrix[int(i+3)] * mMatrix[int(x + 15)] +
                        (x == 4 ? matrix[int(i+4)] : 0);
                }
                
                i+=5;
            }
            
            copyMatrix(sTmpMatrix1, mMatrix);
            updateShaderMatrix();
        }
        
        /** Concatenates the current matrix with another one, passing its contents directly. */
        public function concatValues(m0:Number, m1:Number, m2:Number, m3:Number, m4:Number, 
                                     m5:Number, m6:Number, m7:Number, m8:Number, m9:Number, 
                                     m10:Number, m11:Number, m12:Number, m13:Number, m14:Number, 
                                     m15:Number, m16:Number, m17:Number, m18:Number, m19:Number
                                     ):void
        {
            sTmpMatrix2.length = 0;
            sTmpMatrix2.push(m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, 
                m10, m11, m12, m13, m14, m15, m16, m17, m18, m19);
            
            concat(sTmpMatrix2);
        }

        private function copyMatrix(from:Vector.<Number>, to:Vector.<Number>):void
        {
            for (var i:int=0; i<20; ++i)
                to[i] = from[i];
        }
        
        private function updateShaderMatrix():void
        {
            // the shader needs the matrix components in a different order, 
            // and it needs the offsets in the range 0-1.
            
            mShaderMatrix.length = 0;
            mShaderMatrix.push(
                mMatrix[0],  mMatrix[1],  mMatrix[2],  mMatrix[3],
                mMatrix[5],  mMatrix[6],  mMatrix[7],  mMatrix[8],
                mMatrix[10], mMatrix[11], mMatrix[12], mMatrix[13], 
                mMatrix[15], mMatrix[16], mMatrix[17], mMatrix[18],
                mMatrix[4] / 255.0,  mMatrix[9] / 255.0,  mMatrix[14] / 255.0,  mMatrix[19] / 255.0
            );
        }
        
        // properties
        
        public function get matrix():Vector.<Number> { return mMatrix; }
        public function set matrix(value:Vector.<Number>):void
        {
            if (value && value.length != 20) 
                throw new ArgumentError("Invalid matrix length: must be 20");
            
            if (value == null)
            {
                mMatrix.length = 0;
                mMatrix.push(1,0,0,0,0,  0,1,0,0,0,  0,0,1,0,0,  0,0,0,1,0);
            }
            else
            {
                copyMatrix(value, mMatrix);
            }
            
            updateShaderMatrix();
        }
    }
}