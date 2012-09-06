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
    import flash.geom.Matrix;
    
    import starling.textures.Texture;

    public class ColorMatrixFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        
        private var mMatrix:Vector.<Number>; // offset in range 0-255
        private var mShaderMatrix:Vector.<Number>; // offset in range 0-1, changed order
        
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
            context.setProgram(mShaderProgram);
        }
        
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
                for (var i:int=0; i<20; ++i)
                    mMatrix[i] = value[i];
            }
            
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
    }
}