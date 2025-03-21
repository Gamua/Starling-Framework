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

    import starling.display.BlendMode;
    import starling.unit.UnitTest;

    public class BlendModeTest extends UnitTest
    {
        public function testRegisterBlendMode():void
        {
            var name:String = "test";
            var srcFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            var dstFactor:String = Context3DBlendFactor.DESTINATION_COLOR;

            BlendMode.register(name, srcFactor, dstFactor);

            assertEqual(srcFactor, BlendMode.get(name).sourceFactor);
            assertEqual(dstFactor, BlendMode.get(name).destinationFactor);
        }

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
            assertEqual(modes.filter(modeFilter("test")).length, 1);
            assertEqual(modes.filter(modeFilter("normal")).length, 1);
        }
    }
}