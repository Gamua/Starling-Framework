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
     *
     *  <p>This filter can also be used to create outlines around objects. The trick is to
     *  assign an alpha value that's (much) greater than <code>1.0</code>, and full resolution.
     *  For example, the following code will yield a nice black outline:</p>
     *
     *  <listing>object.filter = new GlowFilter(0x0, 30, 1, 1.0);</listing>
     */
    public class GlowFilter extends FragmentFilter
    {
        private var _blurFilter:BlurFilter;
        private var _compositeFilter:CompositeFilter;
        private var _inner:Boolean;
        private var _knockout:Boolean;

        /** Initializes a new GlowFilter instance with the specified parameters.
         *
         * @param color      the color of the glow
         * @param alpha      the alpha value of the glow. Values between 0 and 1 modify the
         *                   opacity; values > 1 will make it stronger, i.e. produce a harder edge.
         * @param blur       the amount of blur used to create the glow. Note that high
         *                   values will cause the number of render passes to grow.
         * @param quality    the quality of the glow's blur, '1' being the best (range 0.1 - 1.0)
         * @param inner      if enabled, the glow will be drawn inside the object.
         * @param knockout   if enabled, only the glow will be drawn.
         */
        public function GlowFilter(color:uint=0xffff00, alpha:Number=1.0, blur:Number=1.0,
                                   quality:Number=0.5, inner:Boolean=false, knockout:Boolean=false)
        {
            _compositeFilter = new CompositeFilter();
            _blurFilter = new BlurFilter(blur, blur);

            this.color = color;
            this.alpha = alpha;
            this.quality = quality;
            this.inner = inner;
            this.knockout = knockout;

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
            var result:Texture = _compositeFilter.process(painter, helper, input0, glow);
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
        public function get color():uint { return _compositeFilter.getColorAt(1); }
        public function set color(value:uint):void
        {
            if (color != value || !_compositeFilter.getReplaceColorAt(1))
            {
                _compositeFilter.setColorAt(1, value, true);
                setRequiresRedraw();
            }
        }

        /** The alpha value of the glow. Values between 0 and 1 modify the opacity;
         *  values > 1 will make it stronger, i.e. produce a harder edge. @default 1.0 */
        public function get alpha():Number { return _compositeFilter.getAlphaAt(1); }
        public function set alpha(value:Number):void
        {
            if (alpha != value)
            {
                _compositeFilter.setAlphaAt(1, value);
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

        /** The quality used for blurring the glow.
         *  Forwarded to the internally used <em>BlurFilter</em>. */
        public function get quality():Number { return _blurFilter.quality; }
        public function set quality(value:Number):void
        {
            if (quality != value)
            {
                _blurFilter.quality = value;
                setRequiresRedraw();
                updatePadding();
            }
        }

        /** Indicates whether or not the glow is an inner glow. The default is
         *  <code>false</code>, an outer glow (a glow around the outer edges of the object). */
        public function get inner():Boolean { return _inner; }
        public function set inner(value:Boolean) :void
        {
            _inner = value;
            _compositeFilter.setModeAt(1, getMode(_inner, _knockout));
            _compositeFilter.setInvertAlphaAt(1, _inner);
            setRequiresRedraw();
        }

        /** If enabled, applies a knockout effect, which effectively makes the object's fill
         *  transparent. @default false */
        public function get knockout():Boolean { return _knockout; }
        public function set knockout(value:Boolean):void
        {
            _knockout = value;
            _compositeFilter.setModeAt(1, getMode(_inner, _knockout));
            setRequiresRedraw();
        }

        private static function getMode(inner:Boolean, knockout:Boolean):String
        {
            return knockout
                ? (inner ? CompositeMode.INSIDE_KNOCKOUT : CompositeMode.OUTSIDE_KNOCKOUT)
                : (inner ? CompositeMode.INSIDE : CompositeMode.OUTSIDE);
        }
    }
}
