// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import flash.display3D.Context3DProfile;
    import flash.display3D.Context3DTextureFormat;
    import flash.geom.Rectangle;

    import starling.core.Starling;
    import starling.textures.SubTexture;
    import starling.textures.Texture;
    import starling.utils.MathUtil;

    /** @private
     *
     *  This class manages texture creation, pooling and disposal of all textures
     *  during filter processing.
     */
    internal class TexturePool implements ITexturePool
    {
        private var _width:Number;
        private var _height:Number;
        private var _nativeWidth:int;
        private var _nativeHeight:int;
        private var _pool:Vector.<Texture>;
        private var _usePotTextures:Boolean;
        private var _textureFormat:String;
        private var _preferredScale:Number;
        private var _scale:Number;
        private var _sizeStep:int;

        // helpers
        private var sRegion:Rectangle = new Rectangle();

        /** Creates a new, empty instance. */
        public function TexturePool()
        {
            _usePotTextures = Starling.current.profile == Context3DProfile.BASELINE_CONSTRAINED;
            _preferredScale = Starling.contentScaleFactor;
            _textureFormat = Context3DTextureFormat.BGRA;
            _sizeStep = 64; // must be POT!
            _pool = new <Texture>[];

            setSize(_sizeStep, _sizeStep);
        }

        /** Purges the pool. */
        public function dispose():void
        {
            purge();
        }

        /** Updates the size of the returned textures. Small size changes may allow the
         *  existing textures to be reused; big size changes will automatically dispose
         *  them. */
        public function setSize(width:Number, height:Number):void
        {
            _scale = _preferredScale;

            var factor:Number;
            var maxNativeSize:int   = Texture.maxSize;
            var newNativeWidth:int  = getNativeSize(width,  _scale);
            var newNativeHeight:int = getNativeSize(height, _scale);

            if (newNativeWidth > maxNativeSize || newNativeHeight > maxNativeSize)
            {
                factor = maxNativeSize / Math.max(newNativeWidth, newNativeHeight);
                newNativeWidth  *= factor;
                newNativeHeight *= factor;
                _scale *= factor;
            }

            if (_nativeWidth != newNativeWidth || _nativeHeight != newNativeHeight)
            {
                purge();

                _nativeWidth  = newNativeWidth;
                _nativeHeight = newNativeHeight;
            }

            _width  = width;
            _height = height;
        }

        /** @inheritDoc */
        public function getTexture(resolution:Number=1.0):Texture
        {
            var texture:Texture;

            if (_pool.length)
                texture = _pool.pop();
            else
                texture = Texture.empty(_nativeWidth / _scale, _nativeHeight / _scale,
                    true, false, true, _scale, _textureFormat);

            if (!MathUtil.isEquivalent(texture.width, _width) ||
                !MathUtil.isEquivalent(texture.height, _height) ||
                !MathUtil.isEquivalent(texture.scale, _scale * resolution))
            {
                sRegion.setTo(0, 0, _width * resolution, _height * resolution);
                texture = new SubTexture(texture.root, sRegion, true, null, false, resolution);
            }

            texture.root.clear();
            return texture;
        }

        /** @inheritDoc */
        public function putTexture(texture:Texture):void
        {
            if (texture)
            {
                if (texture.root.nativeWidth == _nativeWidth && texture.root.nativeHeight == _nativeHeight)
                    _pool.insertAt(_pool.length, texture);
                else
                    texture.dispose();
            }
        }

        /** Purges the pool and disposes all textures. */
        public function purge():void
        {
            for (var i:int = 0, len:int = _pool.length; i < len; ++i)
                _pool[i].dispose();

            _pool.length = 0;
        }

        private function getNativeSize(size:Number, textureScale:Number):int
        {
            var nativeSize:Number = size * textureScale;

            if (_usePotTextures)
                return nativeSize > _sizeStep ? MathUtil.getNextPowerOfTwo(nativeSize) : _sizeStep;
            else
                return Math.ceil(nativeSize / _sizeStep) * _sizeStep;
        }

        /** The width of the returned textures (in points). */
        public function get textureWidth():Number { return _width; }

        /** The height of the returned textures (in points). */
        public function get textureHeight():Number { return _height; }

        /** The scale factor of the returned textures. */
        public function get textureScale():Number { return _preferredScale; }
        public function set textureScale(value:Number):void
        {
            _preferredScale = value > 0 ? value : Starling.contentScaleFactor;
        }

        /** The texture format of the returned textures. @default BGRA */
        public function get textureFormat():String { return _textureFormat; }
        public function set textureFormat(value:String):void { _textureFormat = value; }
    }
}
