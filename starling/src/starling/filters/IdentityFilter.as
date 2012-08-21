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
    
    import starling.core.RenderSupport;
    import starling.textures.Texture;

    public class IdentityFilter extends FragmentFilter
    {
        private var mShaderProgram:Program3D;
        
        public function IdentityFilter()
        {
            super();
        }
        
        public override function dispose():void
        {
            mShaderProgram.dispose();
            super.dispose();
        }
        
        protected override function createPrograms():void
        {
            var vertexProgramCode:String =
                "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output space
                "mov v0, va1      \n"   // pass texture coordinates to fragment program
            
            var fragmentProgramCode:String =
                "tex oc, v0, fs0 <2d, clamp, linear, mipnone>"; // just forward texture color
            
            mShaderProgram = assembleAgal(vertexProgramCode, fragmentProgramCode);            
        }
        
        protected override function renderFilter(support:RenderSupport, context:Context3D):void
        {
            // already set by super class:
            // 
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            
            context.setProgram(mShaderProgram);
            drawTriangles(context);
        }
    }
}