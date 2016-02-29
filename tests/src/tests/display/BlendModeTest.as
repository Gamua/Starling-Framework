// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.display
{
    import flash.display3D.Context3DBlendFactor;

    import org.flexunit.asserts.assertEquals;

    import starling.display.BlendMode;

    public class BlendModeTest
    {		
        [Test]
        public function testRegisterBlendMode():void
        {
            var name:String = "test";
            var srcFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            var dstFactor:String = Context3DBlendFactor.DESTINATION_COLOR;
            
            BlendMode.register(name, srcFactor, dstFactor);

            assertEquals(srcFactor, BlendMode.get(name).sourceFactor);
            assertEquals(dstFactor, BlendMode.get(name).destinationFactor);
        }
    }
}