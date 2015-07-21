// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flash.display3D.Context3DBlendFactor;
    
    import flexunit.framework.Assert;
    
    import starling.display.BlendMode;

    public class BlendModeTest
    {		
        [Test]
        public function testRegisterBlendMode():void
        {
            var name:String = "test";
            
            // register for pma = true; should set factors for both pma possibilities.
            
            BlendMode.register(name, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA,
                                     Context3DBlendFactor.DESTINATION_COLOR, true);
            
            var modesPma:Array = BlendMode.getBlendFactors(name, true);
            var modesNoPma:Array = BlendMode.getBlendFactors(name, false);
            
            Assert.assertEquals(Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA, modesPma[0]);
            Assert.assertEquals(Context3DBlendFactor.DESTINATION_COLOR, modesPma[1]);
            
            Assert.assertEquals(Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA, modesNoPma[0]);
            Assert.assertEquals(Context3DBlendFactor.DESTINATION_COLOR, modesNoPma[1]);
            
            // now overwrite for pma = false; should not change pma = true factors.
            
            BlendMode.register(name, Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO, 
                               false);
            
            modesPma = BlendMode.getBlendFactors(name, true);
            modesNoPma = BlendMode.getBlendFactors(name, false);
            
            Assert.assertEquals(Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA, modesPma[0]);
            Assert.assertEquals(Context3DBlendFactor.DESTINATION_COLOR, modesPma[1]);
            
            Assert.assertEquals(Context3DBlendFactor.ONE, modesNoPma[0]);
            Assert.assertEquals(Context3DBlendFactor.ZERO, modesNoPma[1]);
        }
    }
}