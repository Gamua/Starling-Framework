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

    /** This filter is only kept as a sample filter implementation you can learn from. 
      * It will be removed with the next official Starling release! 
      * As a replacement, use the 'desaturate' method in the ColorMatrixFilter. */
    public class GrayscaleFilter extends FragmentFilter
    {
        private var mQuantifiers:Vector.<Number>;
        private var mShaderProgram:Program3D;
        
        public function GrayscaleFilter(red:Number=0.299, green:Number=0.587, blue:Number=0.114)
        {
            mQuantifiers = new <Number>[red, green, blue, 0.0];
        }
        
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        protected override function createPrograms():void
        {
            var fragmentProgramCode:String =
                "tex ft0, v0, fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
                "dp3 ft0.xyz, ft0.xyz, fc0.xyz \n" +  // dot product color with quantifiers
                "mov oc, ft0                   \n";   // output color
            
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
            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, mQuantifiers, 1);
            context.setProgram(mShaderProgram);
        }
    }
}