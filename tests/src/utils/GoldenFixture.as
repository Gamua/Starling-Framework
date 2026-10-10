// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package utils
{
    import flash.display.BitmapData;
    import flash.geom.Rectangle;

    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.textures.Texture;

    /** Provides the building blocks for golden image tests. Create it in 'setUp' and
     *  dispose it in 'tearDown', which also disposes the textures it created. */
    public class GoldenFixture
    {
        private var _width:int;
        private var _height:int;
        private var _checkerboardTexture:Texture;

        public function GoldenFixture(width:int=128, height:int=128)
        {
            _width = width;
            _height = height;
        }

        public function dispose():void
        {
            if (_checkerboardTexture) _checkerboardTexture.dispose();
            _checkerboardTexture = null;
        }

        /** A container with an opaque background, so that the rendered area does not depend
         *  on the bounds of its content (filters may draw outside of them). */
        public function createCanvas():Sprite
        {
            var canvas:Sprite = new Sprite();
            canvas.addChild(new Quad(_width, _height, 0x303030));
            return canvas;
        }

        /** A colorful 32x32 checkerboard with 8x8 cells. Created on first access. */
        public function get checkerboardTexture():Texture
        {
            if (_checkerboardTexture == null)
            {
                var bitmap:BitmapData = new BitmapData(32, 32, false, 0xffffff);
                var colors:Array = [0xe04040, 0x40c040, 0x4040e0, 0xe0c040];

                for (var y:int = 0; y < 4; ++y)
                    for (var x:int = 0; x < 4; ++x)
                        bitmap.fillRect(new Rectangle(x * 8, y * 8, 8, 8),
                            (x + y) % 2 ? 0xffffff : colors[(x + 2 * y) % 4]);

                _checkerboardTexture = Texture.fromBitmapData(bitmap, false);
            }

            return _checkerboardTexture;
        }

        public function get width():int { return _width; }
        public function get height():int { return _height; }
    }
}
