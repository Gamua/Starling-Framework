// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.rendering
{
    import flash.display.BitmapData;
    import flash.geom.Rectangle;

    import starling.display.BlendMode;
    import starling.display.Canvas;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.filters.BlurFilter;
    import starling.filters.ColorMatrixFilter;
    import starling.textures.Texture;
    import starling.unit.UnitTest;
    import starling.utils.Color;

    public class GoldenImageTest extends UnitTest
    {
        private static const SIZE:int = 128;

        private var _texture:Texture;

        override public function setUp():void
        {
            super.setUp();
            _texture = Texture.fromBitmapData(createCheckerboard(), false);
        }

        override public function tearDown():void
        {
            _texture.dispose();
            super.tearDown();
        }

        public function testQuads(onComplete:Function):void
        {
            var canvas:Sprite = createCanvas();

            var gradient:Quad = new Quad(80, 80);
            gradient.setVertexColor(0, Color.RED);
            gradient.setVertexColor(1, Color.GREEN);
            gradient.setVertexColor(2, Color.BLUE);
            gradient.setVertexColor(3, Color.YELLOW);
            gradient.x = gradient.y = 10;
            canvas.addChild(gradient);

            var rotated:Quad = new Quad(50, 50, Color.WHITE);
            rotated.alignPivot();
            rotated.rotation = Math.PI / 6;
            rotated.alpha = 0.5;
            rotated.x = rotated.y = 85;
            canvas.addChild(rotated);

            assertMatchesGolden(canvas, "quads", onComplete);
        }

        public function testImage(onComplete:Function):void
        {
            var canvas:Sprite = createCanvas();

            // scaled up and rotated, to exercise bilinear filtering
            var image:Image = new Image(_texture);
            image.alignPivot();
            image.scale = 2.5;
            image.rotation = Math.PI / 8;
            image.x = image.y = SIZE / 2;
            image.color = 0xffcc88;
            canvas.addChild(image);

            assertMatchesGolden(canvas, "image", onComplete);
        }

        public function testBlendModes(onComplete:Function):void
        {
            var canvas:Sprite = createCanvas();
            var blendModes:Array = [BlendMode.NORMAL, BlendMode.ADD, BlendMode.MULTIPLY, BlendMode.SCREEN];

            var background:Image = new Image(_texture);
            background.width = background.height = SIZE;
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

            assertMatchesGolden(canvas, "blend-modes", onComplete);
        }

        public function testBlurFilter(onComplete:Function):void
        {
            var canvas:Sprite = createCanvas();

            var image:Image = new Image(_texture);
            image.scale = 2;
            image.x = image.y = 32;
            image.filter = new BlurFilter(2, 2);
            canvas.addChild(image);

            assertMatchesGolden(canvas, "blur-filter", onComplete);
            image.filter.dispose();
        }

        public function testColorMatrixFilter(onComplete:Function):void
        {
            var canvas:Sprite = createCanvas();

            var filter:ColorMatrixFilter = new ColorMatrixFilter();
            filter.adjustHue(0.5);
            filter.adjustContrast(0.3);

            var image:Image = new Image(_texture);
            image.width = image.height = SIZE;
            image.filter = filter;
            canvas.addChild(image);

            assertMatchesGolden(canvas, "color-matrix-filter", onComplete);
            filter.dispose();
        }

        public function testMask(onComplete:Function):void
        {
            var canvas:Sprite = createCanvas();

            var mask:Canvas = new Canvas();
            mask.drawCircle(SIZE / 2, SIZE / 2, 50);

            var image:Image = new Image(_texture);
            image.width = image.height = SIZE;

            // the mask is placed in the local space of the masked object, which is unscaled here
            var content:Sprite = new Sprite();
            content.addChild(image);
            content.mask = mask;
            canvas.addChild(content);

            assertMatchesGolden(canvas, "mask", onComplete);
        }

        // helpers

        /** A container with an opaque background, so that the rendered area does not depend
         *  on the bounds of its content (filters may draw outside of them). */
        private static function createCanvas():Sprite
        {
            var canvas:Sprite = new Sprite();
            canvas.addChild(new Quad(SIZE, SIZE, 0x303030));
            return canvas;
        }

        private static function createCheckerboard():BitmapData
        {
            var bitmap:BitmapData = new BitmapData(32, 32, false, 0xffffff);
            var colors:Array = [0xe04040, 0x40c040, 0x4040e0, 0xe0c040];

            for (var y:int = 0; y < 4; ++y)
                for (var x:int = 0; x < 4; ++x)
                    bitmap.fillRect(new Rectangle(x * 8, y * 8, 8, 8),
                        (x + y) % 2 ? 0xffffff : colors[(x + 2 * y) % 4]);

            return bitmap;
        }
    }
}
