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
    import starling.utils.Padding;

    /** The DropShadowFilter class lets you add a drop shadow to display objects.
     *  To create the shadow, the class internally uses the BlurFilter.
     */
    public class DropShadowFilter extends FragmentFilter
    {
        private var _blurFilter:BlurFilter;
        private var _compositeFilter:CompositeFilter;
        private var _distance:Number;
        private var _angle:Number;
        private var _inner:Boolean;
        private var _knockout:Boolean;

        /** Creates a new DropShadowFilter instance with the specified parameters.
         *
         * @param distance   the offset distance of the shadow, in points.
         * @param angle      the angle with which the shadow is offset, in radians.
         * @param color      the color of the shadow.
         * @param alpha      the alpha value of the shadow. Values between 0 and 1 modify the
         *                   opacity; values > 1 will make it stronger, i.e. produce a harder edge.
         * @param blur       the amount of blur with which the shadow is created. Note that high
         *                   values will cause the number of render passes to grow.
         * @param quality    the quality of the shadow blur, '1' being the best (range 0.1 - 1.0)
         * @param inner      if enabled, the shadow will be drawn inside the object.
         * @param knockout   if enabled, only the shadow will be drawn.
         */
        public function DropShadowFilter(distance:Number=4.0, angle:Number=0.785,
                                         color:uint=0x0, alpha:Number=0.5, blur:Number=1.0,
                                         quality:Number=0.5, inner:Boolean=false, knockout:Boolean=false)
        {
            _compositeFilter = new CompositeFilter();
            _blurFilter = new BlurFilter(blur, blur);
            _distance = distance;
            _angle = angle;

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
            var shadow:Texture = _blurFilter.process(painter, helper, input0);
            var result:Texture = _compositeFilter.process(painter, helper, input0, shadow);
            helper.putTexture(shadow);
            return result;
        }

        /** @private */
        override public function get numPasses():int
        {
            return _blurFilter.numPasses + _compositeFilter.numPasses;
        }

        private function updatePadding():void
        {
            var offsetX:Number = Math.cos(_angle) * _distance;
            var offsetY:Number = Math.sin(_angle) * _distance;

            _compositeFilter.setOffsetAt(1, offsetX, offsetY);

            var blurPadding:Padding = _blurFilter.padding;
            var left:Number = blurPadding.left;
            var right:Number = blurPadding.right;
            var top:Number = blurPadding.top;
            var bottom:Number = blurPadding.bottom;

            if (offsetX > 0) right += offsetX; else left -= offsetX;
            if (offsetY > 0) bottom += offsetY; else top -= offsetY;

            padding.setTo(left, right, top, bottom);
        }

        /** The color of the shadow. @default 0x0 */
        public function get color():uint { return _compositeFilter.getColorAt(1); }
        public function set color(value:uint):void
        {
            if (color != value || !_compositeFilter.getReplaceColorAt(1))
            {
                _compositeFilter.setColorAt(1, value, true);
                setRequiresRedraw();
            }
        }

        /** The alpha value of the shadow. Values between 0 and 1 modify the opacity;
         *  values > 1 will make it stronger, i.e. produce a harder edge. @default 0.5 */
        public function get alpha():Number { return _compositeFilter.getAlphaAt(1); }
        public function set alpha(value:Number):void
        {
            if (alpha != value)
            {
                _compositeFilter.setAlphaAt(1, value);
                setRequiresRedraw();
            }
        }

        /** The offset distance for the shadow, in points. @default 4.0 */
        public function get distance():Number { return _distance; }
        public function set distance(value:Number):void
        {
            if (_distance != value)
            {
                _distance = value;
                setRequiresRedraw();
                updatePadding();
            }
        }

        /** The angle with which the shadow is offset, in radians. @default Math.PI / 4 */
        public function get angle():Number { return _angle; }
        public function set angle(value:Number):void
        {
            if (_angle != value)
            {
                _angle = value;
                setRequiresRedraw();
                updatePadding();
            }
        }

        /** The amount of blur with which the shadow is created.
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

        /** The quality used for blurring the shadow (range: 0.1 - 1).
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

        /** Indicates whether or not the shadow is an inner shadow. The default is
         *  <code>false</code>, an outer shadow (a shadow around the outer edges of the object). */
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
