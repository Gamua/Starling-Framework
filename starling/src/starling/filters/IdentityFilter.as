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
    import flash.display3D.Program3D;
    
    import starling.textures.Texture;

    /** This filter is only kept as a sample filter implementation you can learn from. It will
      * be removed with the next official Starling release! */
    public class IdentityFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        
        public function IdentityFilter()
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
            var fragmentProgramCode:String =
                "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
            
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
            
            context.setProgram(mShaderProgram);
        }
    }
}