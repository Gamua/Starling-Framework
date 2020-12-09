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

    import org.flexunit.assertThat;
    import org.flexunit.asserts.assertEquals;
    import org.hamcrest.object.equalTo;

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

        [Test]
        public function testGetAllBlendModes():void
        {
            var name:String = "test";
            var srcFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            var dstFactor:String = Context3DBlendFactor.DESTINATION_COLOR;

            BlendMode.register(name, srcFactor, dstFactor);

            var modeFilter:Function = function(modeName:String):Function
            {
                return function(mode:BlendMode, ...args):Boolean {
                    return mode.name == modeName;
                };
            };

            var modes:Array = BlendMode.getAll();
            assertThat(modes.filter(modeFilter("test")).length, equalTo(1));
            assertThat(modes.filter(modeFilter("normal")).length, equalTo(1));
        }
    }
}