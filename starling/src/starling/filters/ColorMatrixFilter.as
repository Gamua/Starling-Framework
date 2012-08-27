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
    
    import starling.textures.Texture;

    public class ColorMatrixFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        private var mRawData:Vector.<Number>;
        
        // TODO: add convenience methods for easier matrix creation
        
        public function ColorMatrixFilter(rawData:Vector.<Number>)
        {
            if (rawData.length != 20) throw new Error("Invalid vector length: must be 20");
            mRawData = transpose(rawData);
        }
        
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        protected override function createPrograms():void
        {
            // TODO: we could create an optimized shader when the offset values are all zero
            
            var fragmentProgramCode:String =
                "tex ft0, v0,  fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
                "m44 ft1, ft0, fc0    \n" +  // multiply color with 4x4 matrix
                "add ft1, ft1, fc4    \n" +  // add 5th column
                "mov  oc, ft1            ";  // copy to output
            
            mShaderProgram = assembleAgal(fragmentProgramCode);
        }
        
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            // 
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mRawData, 5);
            context.setProgram(mShaderProgram);
        }
        
        private function transpose(input:Vector.<Number>, output:Vector.<Number>=null):Vector.<Number>
        {
            if (output) output.length = 0;
            else        output = new Vector.<Number>();
            
            output.push(
                input[0], input[5], input[10], input[15],
                input[1], input[6], input[11], input[16],
                input[2], input[7], input[12], input[17], 
                input[3], input[8], input[13], input[18],
                input[4], input[9], input[14], input[19] 
            );
            
            return output;
        }
        
        public function get rawData():Vector.<Number> { return transpose(mRawData); }
        public function set rawData(value:Vector.<Number>):void { transpose(value, mRawData); }
    }
}