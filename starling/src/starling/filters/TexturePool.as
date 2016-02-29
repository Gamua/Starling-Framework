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
        private var _scale:Number;
        private var _width:Number;
        private var _height:Number;
        private var _nativeWidth:int;
        private var _nativeHeight:int;
        private var _pool:Vector.<Texture>;
        private var _usePotTextures:Boolean;
        private var _sizeStep:int;

        // helpers
        private var sRegion:Rectangle = new Rectangle();

        /** Creates a new, empty instance. */
        public function TexturePool()
        {
            _usePotTextures = Starling.current.profile == Context3DProfile.BASELINE_CONSTRAINED;
            _sizeStep = 64; // must be POT!
            _pool = new <Texture>[];

            setSize(_sizeStep, _sizeStep, 1);
        }

        /** Purges the pool. */
        public function dispose():void
        {
            purge();
        }

        /** Updates the size of the returned textures. Small size changes may allow the
         *  existing textures to be reused; big size changes will automatically dispose
         *  them. */
        public function setSize(width:Number, height:Number, scale:Number=-1):void
        {
            if (scale <= 0) scale = Starling.contentScaleFactor;

            var factor:Number;
            var maxNativeSize:int   = Texture.maxSize;
            var newNativeWidth:int  = getNativeSize(width,  scale);
            var newNativeHeight:int = getNativeSize(height, scale);

            if (newNativeWidth > maxNativeSize || newNativeHeight > maxNativeSize)
            {
                factor = maxNativeSize / Math.max(newNativeWidth, newNativeHeight);
                newNativeWidth  *= factor;
                newNativeHeight *= factor;
                scale *= factor;
            }

            if (_nativeWidth != newNativeWidth || _nativeHeight != newNativeHeight)
            {
                purge();

                _nativeWidth  = newNativeWidth;
                _nativeHeight = newNativeHeight;
            }

            _width  = width;
            _height = height;
            _scale  = scale;
        }

        /** @inheritDoc */
        public function getTexture():Texture
        {
            var texture:Texture;

            if (_pool.length)
                texture = _pool.pop();
            else
                texture = Texture.empty(_nativeWidth / _scale, _nativeHeight / _scale,
                    true, false, true, _scale);

            if (texture.width != _width || texture.height != _height)
            {
                sRegion.setTo(0, 0, _width, _height);
                texture = new SubTexture(texture.root, sRegion, true);
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
        public function get textureScale():Number { return _scale; }
    }
}
