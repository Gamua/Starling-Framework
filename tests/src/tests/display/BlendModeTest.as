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
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.unit.UnitTest;

    import utils.GoldenFixture;

    public class BlendModeTest extends UnitTest
    {
        private var _fixture:GoldenFixture;

        override public function setUp():void
        {
            super.setUp();
            _fixture = new GoldenFixture();
        }

        override public function tearDown():void
        {
            _fixture.dispose();
            super.tearDown();
        }

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

        public function testRendering(onComplete:Function):void
        {
            var canvas:Sprite = _fixture.createCanvas();
            var blendModes:Array = [BlendMode.NORMAL, BlendMode.ADD, BlendMode.MULTIPLY, BlendMode.SCREEN];

            var background:Image = new Image(_fixture.checkerboardTexture);
            background.width = _fixture.width;
            background.height = _fixture.height;
            canvas.addChild(background);

            for (var i:int = 0; i < blendModes.length; ++i)
            {
                var quad:Quad = new Quad(48, 48, 0x4080ff);
                quad.alpha = 0.7;
                quad.blendMode = blendModes[i];
                quad.x = 8 + (i % 2) * 64;
                quad.y = 8 + int(i / 2) * 64;
                canvas.addChild(quad);
            }

            assertMatchesGolden(canvas, "display/blend-modes", onComplete);
        }
    }
}