// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package tests.styles
{
    import flash.display.BitmapData;
    import flash.geom.Rectangle;

    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.MeshBatch;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.rendering.Painter;
    import starling.styles.MultiTextureStyle;
    import starling.textures.Texture;
    import starling.unit.UnitTest;
    import starling.utils.MeshSubset;
    import starling.utils.StringUtil;

    import utils.GoldenFixture;

    public class MultiTextureStyleTest extends UnitTest
    {
        private static const COLORS:Array = [0xff0000, 0x00ff00, 0x0000ff, 0xffff00,
                                             0xff00ff, 0x00ffff, 0xff8000, 0x8000ff];
        private static const SIZE:int = 16;

        private var _textures:Vector.<Texture>;
        private var _maxTextures:int;
        private var _fixture:GoldenFixture;

        override public function setUp():void
        {
            super.setUp();
            _fixture = new GoldenFixture();
            _maxTextures = MultiTextureStyle.maxTextures;
            _textures = new <Texture>[];

            // non-power-of-two sizes, so that "baselineConstrained" pads them, each differently
            for (var i:int = 0; i < COLORS.length; ++i)
            {
                var bitmap:BitmapData = new BitmapData(3 + 2 * i, 17 - 2 * i, false, COLORS[i]);
                _textures.push(Texture.fromBitmapData(bitmap, false));
            }
        }

        override public function tearDown():void
        {
            for each (var texture:Texture in _textures) texture.dispose();
            MultiTextureStyle.maxTextures = _maxTextures;
            _fixture.dispose();
            super.tearDown();
        }

        public function testMaxTexturesIsClamped():void
        {
            MultiTextureStyle.maxTextures = 0;
            assertEqual(MultiTextureStyle.maxTextures, 1);

            MultiTextureStyle.maxTextures = MultiTextureStyle.MAX_NUM_TEXTURES + 1;
            assertEqual(MultiTextureStyle.maxTextures, MultiTextureStyle.MAX_NUM_TEXTURES);
        }

        public function testTextureOrderWithDifferentLimits():void
        {
            var order:Array = [0, 1, 2, 3, 1, 0, 3, 2, 4, 5, 6, 7, 7, 0, 5];
            var maxNumTextures:int = MultiTextureStyle.MAX_NUM_TEXTURES;
            var profileLimit:int = Starling.current.profile == "baselineConstrained" ? 4 : maxNumTextures;
            var painter:Painter = Starling.painter;

            // draw calls needed for that order, indexed by the effective limit minus one
            var expectedDrawCounts:Array = [14, 7, 5, 3, 2, 2, 2, 1];

            for (var maxTextures:int = 1; maxTextures <= maxNumTextures; ++maxTextures)
            {
                MultiTextureStyle.maxTextures = maxTextures;
                var row:Sprite = new Sprite();
                for (var i:int = 0; i < order.length; ++i) {
                    row.addChild(createImage(order[i], i));
                }

                var info:String = "max=" + maxTextures;
                var drawCount:int = painter.drawCount;
                assertColors(row, order, info);

                var actualDrawCount:int = painter.drawCount - drawCount;
                var expectedDrawCount:int = expectedDrawCounts[Math.min(maxTextures, profileLimit) - 1];
                assertEqual(actualDrawCount, expectedDrawCount, StringUtil.format(
                    "{0}: expected {1} draw calls, got {2}", info, expectedDrawCount, actualDrawCount));
            }
        }

        public function testUntexturedQuadsInBetween():void
        {
            var row:Sprite = new Sprite();
            var expected:Array = [];
            for (var i:int = 0; i < 8; ++i)
            {
                if (i % 2) { row.addChild(createQuad(0xffffff, i)); expected.push(-1); }
                else { row.addChild(createImage((i / 2) % 4, i)); expected.push((i / 2) % 4); }
            }
            assertColors(row, expected, "quads");
        }

        public function testNestedMeshBatch():void
        {
            // a batch that already references two textures, rendered next to other images
            var batch:MeshBatch = new MeshBatch();
            batch.style = new MultiTextureStyle();
            batch.batchable = true;
            batch.addMesh(createImage(2, 2));
            batch.addMesh(createImage(3, 3));

            var row:Sprite = new Sprite();
            row.addChild(createImage(0, 0));
            row.addChild(createImage(1, 1));
            row.addChild(batch);
            row.addChild(createImage(3, 4));
            row.addChild(createImage(2, 5));

            assertColors(row, [0, 1, 2, 3, 3, 2], "nested (first frame)");
            assertColors(row, [0, 1, 2, 3, 3, 2], "nested (second frame)");
        }

        public function testTextureRemovedFromQuad():void
        {
            var quad:Quad = createQuad(0xffffff, 0);
            quad.texture = _textures[0];
            quad.texture = null;
            assertColors(quad, [-1], "texture removed");
        }

        public function testSubsetOfBatch():void
        {
            // the render cache adds subsets of the previous frame's batches, without transformation
            var source:MeshBatch = new MeshBatch();
            source.style = new MultiTextureStyle();
            for (var i:int = 0; i < 4; ++i) source.addMesh(createImage(i, i));

            var target:MeshBatch = new MeshBatch();
            target.style = new MultiTextureStyle();
            target.addMesh(createImage(3, 0));
            target.addMesh(source, null, 1.0, new MeshSubset(8, 8, 12, 12), true);

            assertColors(target, [3, null, 2, 3], "subset");
        }

        public function testRendering(onComplete:Function):void
        {
            MultiTextureStyle.maxTextures = MultiTextureStyle.MAX_NUM_TEXTURES;

            var canvas:Sprite = _fixture.createCanvas();
            var cellSize:int = _fixture.width / 4;
            var stripedTextures:Vector.<Texture> = new <Texture>[];

            // rotated and tinted, so that texture coordinates and vertex colors must be right, too
            for (var i:int = 0; i < 8; ++i)
            {
                var texture:Texture = createStripedTexture(COLORS[i]);
                var image:Image = new Image(texture);
                image.style = new MultiTextureStyle();
                image.alignPivot();
                image.scale = 0.75;
                image.rotation = (i - 4) * Math.PI / 16;
                image.x = (i % 4 + 0.5) * cellSize;
                image.y = (int(i / 4) + 0.5) * cellSize;
                if (i == 5) image.color = 0x808080;
                if (i == 6) image.alpha = 0.5;
                canvas.addChild(image);
                stripedTextures.push(texture);
            }

            var quad:Quad = new Quad(_fixture.width - 16, cellSize / 2, 0x8080ff);
            quad.style = new MultiTextureStyle();
            quad.x = 8;
            quad.y = 2.25 * cellSize;
            canvas.addChild(quad);

            assertMatchesGolden(canvas, "styles/multi-texture", function():void
            {
                for each (texture in stripedTextures) texture.dispose();
                onComplete();
            });
        }

        // Power-of-two size: "baselineConstrained" pads other sizes with transparent pixels,
        // which bilinear filtering would pull into the edges of the rotated images.
        private function createStripedTexture(color:uint):Texture
        {
            var bitmap:BitmapData = new BitmapData(32, 32, false, 0xffffff);
            for (var y:int = 0; y < 32; y += 8)
                bitmap.fillRect(new Rectangle(0, y, 32, 4), color);
            return Texture.fromBitmapData(bitmap, false);
        }

        private function createImage(textureIndex:int, slot:int):Image
        {
            var image:Image = new Image(_textures[textureIndex]);
            image.style = new MultiTextureStyle();
            image.width = image.height = SIZE;
            image.x = slot * SIZE;
            return image;
        }

        private function createQuad(color:uint, slot:int):Quad
        {
            var quad:Quad = new Quad(SIZE, SIZE, color);
            quad.style = new MultiTextureStyle();
            quad.x = slot * SIZE;
            return quad;
        }

        // Checks the center pixel of each slot: a texture index, -1 for white, or null to skip.
        private function assertColors(object:DisplayObject, textureIndices:Array, info:String):void
        {
            var bitmap:BitmapData = object.drawToBitmapData(null, 0x0, 1.0);
            for (var i:int = 0; i < textureIndices.length; ++i)
            {
                if (textureIndices[i] == null) continue;

                var index:int = textureIndices[i];
                var expected:uint = index < 0 ? 0xffffff : COLORS[index];
                var actual:uint = bitmap.getPixel(i * SIZE + SIZE / 2, SIZE / 2);
                assert(actual == expected, StringUtil.format("{0}, slot {1}: expected {2}, got {3}",
                    info, i, expected.toString(16), actual.toString(16)));
            }
            bitmap.dispose();
        }
    }
}
