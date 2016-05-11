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
    import starling.rendering.Painter;
    import starling.textures.Texture;

    /** The GlowFilter class lets you apply a glow effect to display objects.
     *  It is similar to the drop shadow filter with the distance and angle properties set to 0.
     */
    public class GlowFilter extends FragmentFilter
    {
        private var _blurFilter:BlurFilter;
        private var _compositeFilter:CompositeFilter;

        /** Initializes a new GlowFilter instance with the specified parameters. */
        public function GlowFilter(color:uint=0xffff00, alpha:Number=1.0, blur:Number=1.0, strength:Number = 1.0, resolution:Number=0.5)
        {
            _compositeFilter = new CompositeFilter();
            _blurFilter = new BlurFilter(blur, blur, strength, resolution);

            this.color = color;
            this.alpha = alpha;

            updatePadding();
        }

        /** @inheritDoc */
        override public function dispose():void
        {
            _blurFilter.dispose();
            _compositeFilter.dispose();

            super.dispose();
        }

        /** @private */
        override public function process(painter:Painter, helper:IFilterHelper,
                                         input0:Texture = null, input1:Texture = null,
                                         input2:Texture = null, input3:Texture = null):Texture
        {
            var glow:Texture = _blurFilter.process(painter, helper, input0);
            var result:Texture = _compositeFilter.process(painter, helper, glow, input0);
            helper.putTexture(glow);
            return result;
        }

        /** @private */
        override public function get numPasses():int
        {
            return _blurFilter.numPasses + _compositeFilter.numPasses;
        }

        private function updatePadding():void
        {
            padding.copyFrom(_blurFilter.padding);
        }

        /** The color of the glow. @default 0xffff00 */
        public function get color():uint { return _compositeFilter.getColorAt(0); }
        public function set color(value:uint):void
        {
            if (color != value)
            {
                _compositeFilter.setColorAt(0, value, true);
                setRequiresRedraw();
            }
        }

        /** The alpha transparency value for the color. @default 1.0 */
        public function get alpha():Number { return _compositeFilter.getAlphaAt(0); }
        public function set alpha(value:Number):void
        {
            if (alpha != value)
            {
                _compositeFilter.setAlphaAt(0, value);
                setRequiresRedraw();
            }
        }

        /** The amount of blur with which the glow is created.
         *  The number of required passes will be <code>Math.ceil(value) × 2</code>.
         *  @default 1.0 */
        public function get blur():Number { return _blurFilter.blurX; }
        public function set blur(value:Number):void
        {
            if (blur != value)
            {
                _blurFilter.blurX = _blurFilter.blurY = value;
                setRequiresRedraw();
                updatePadding();
            }
        }

        /** @private */
        override public function get resolution():Number { return _blurFilter.resolution; }
        override public function set resolution(value:Number):void
        {
            if (resolution != value)
            {
                _blurFilter.resolution = value;
                setRequiresRedraw();
                updatePadding();
            }
        }
        
        public function get strength():Number { return _blurFilter.strength; }
        public function set strength(value:Number):void
        {
            if (_blurFilter.strength != value)
            {
                _blurFilter.strength = value;
                updatePadding();
            }
        }
    }
}
