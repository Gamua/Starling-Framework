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

    public class InverseFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        private var mOnes:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
        
        public function InverseFilter()
        {
            super();
        }
        
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        protected override function createPrograms():void
        {
            // One might expect that we could just subtract the RGB values from 1, right?
            // The problem is that the input arrives with premultiplied alpha values, and the
            // output is expected in the same form. So we first have to restore the original RGB
            // values, subtract them from one, and then multiply with the original alpha again.
            
            var fragmentProgramCode:String =
                "tex ft0, v0, fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
                "div ft0.xyz, ft0.xyz, ft0.www  \n" + // restore original (non-PMA) RGB values
                "sub ft0.xyz, fc0.xyz, ft0.xyz  \n" + // subtract rgb values from '1'
                "mul ft0.xyz, ft0.xyz, ft0.www  \n" + // multiply with alpha again (PMA)
                "mov oc, ft0                    \n";  // copy to output
            
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
            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mOnes, 1);
            context.setProgram(mShaderProgram);
        }
    }
}