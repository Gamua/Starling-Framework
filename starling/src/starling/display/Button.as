// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import starling.styles.MeshStyle;
    import starling.text.TextField;
    import starling.text.TextFormat;
    import starling.textures.Texture;
    import starling.utils.ButtonBehavior;
    import starling.utils.SystemUtil;

    /** Dispatched when the user triggers the button. Bubbles. */
    [Event(name="triggered", type="starling.events.Event")]
    
    /** A simple button composed of an image and, optionally, text.
     *  
     *  <p>You can use different textures for various states of the button. If you're providing
     *  only an up state, the button is simply scaled a little when it is touched.</p>
     *
     *  <p>In addition, you can overlay text on the button. To customize the text, you can use
     *  properties equivalent to those of the TextField class. Move the text to a certain position
     *  by updating the <code>textBounds</code> property.</p>
     *  
     *  <p>To react on touches on a button, there is special <code>Event.TRIGGERED</code> event.
     *  Use this event instead of normal touch events. That way, users can cancel button
     *  activation by moving the mouse/finger away from the button before releasing.</p>
     */
    public class Button extends DisplayObjectContainer
    {
        private var _upState:Texture;
        private var _downState:Texture;
        private var _overState:Texture;
        private var _disabledState:Texture;
        
        private var _contents:Sprite;
        private var _body:Image;
        private var _textField:TextField;
        private var _textBounds:Rectangle;
        private var _overlay:Sprite;
        
        private var _behavior:ButtonBehavior;
        private var _scaleWhenDown:Number;
        private var _scaleWhenOver:Number;
        private var _alphaWhenDown:Number;
        private var _alphaWhenDisabled:Number;

        /** Creates a button with a set of state-textures and (optionally) some text.
         *  Any state that is left 'null' will display the up-state texture. Beware that all
         *  state textures should have the same dimensions. */
        public function Button(upState:Texture, text:String="", downState:Texture=null,
                               overState:Texture=null, disabledState:Texture=null)
        {
            if (upState == null) throw new ArgumentError("Texture 'upState' cannot be null");
            
            _upState = upState;
            _downState = downState;
            _overState = overState;
            _disabledState = disabledState;

            _behavior = new ButtonBehavior(this, onStateChange, SystemUtil.isDesktop ? 16 : 44);
            _body = new Image(upState);
            _body.pixelSnapping = true;
            _scaleWhenDown = downState ? 1.0 : 0.9;
            _scaleWhenOver = _alphaWhenDown = 1.0;
            _alphaWhenDisabled = disabledState ? 1.0: 0.5;
            _textBounds = new Rectangle(0, 0, _body.width, _body.height);

            _contents = new Sprite();
            _contents.addChild(_body);
            addChild(_contents);

            setStateTexture(upState);

            this.touchGroup = true;
            this.text = text;
        }
        
        /** @inheritDoc */
        public override function dispose():void
        {
            // text field might be disconnected from parent, so we have to dispose it manually
            if (_textField)
                _textField.dispose();
            
            super.dispose();
        }

        private function onStateChange(state:String):void
        {
            _contents.x = _contents.y = 0;
            _contents.scaleX = _contents.scaleY = _contents.alpha = 1.0;

            switch (state)
            {
                case ButtonState.DOWN:
                    setStateTexture(_downState);
                    setContentScale(_scaleWhenDown);
                    _contents.alpha = _alphaWhenDown;
                    break;
                case ButtonState.UP:
                    setStateTexture(_upState);
                    break;
                case ButtonState.OVER:
                    setStateTexture(_overState);
                    setContentScale(_scaleWhenOver);
                    break;
                case ButtonState.DISABLED:
                    setStateTexture(_disabledState);
                    _contents.alpha = _alphaWhenDisabled;
                    break;
            }
        }

        /** @private */
        public override function hitTest(localPoint:Point):DisplayObject
        {
            return _behavior.hitTest(localPoint);
        }
        
        /** Readjusts the dimensions of the button according to its current state texture.
         *  Call this method to synchronize button and texture size after assigning a texture
         *  with a different size. */
        public function readjustSize():void
        {
            var prevWidth:Number = _body.width;
            var prevHeight:Number = _body.height;

            _body.readjustSize();

            var scaleX:Number = _body.width  / prevWidth;
            var scaleY:Number = _body.height / prevHeight;

            _textBounds.x *= scaleX;
            _textBounds.y *= scaleY;
            _textBounds.width *= scaleX;
            _textBounds.height *= scaleY;

            if (_textField) createTextField();
        }

        private function createTextField():void
        {
            if (_textField == null)
            {
                _textField = new TextField(_textBounds.width, _textBounds.height);
                _textField.pixelSnapping = _body.pixelSnapping;
                _textField.touchable = false;
                _textField.autoScale = true;
                _textField.batchable = true;
            }
            
            _textField.width  = _textBounds.width;
            _textField.height = _textBounds.height;
            _textField.x = _textBounds.x;
            _textField.y = _textBounds.y;
        }
        
        /** The current state of the button. The corresponding strings are found
         *  in the ButtonState class. */
        public function get state():String { return _behavior.state; }
        public function set state(value:String):void { _behavior.state = value; }

        private function setContentScale(scale:Number):void
        {
            _contents.scaleX = _contents.scaleY = scale;
            _contents.x = (1.0 - scale) / 2.0 * _body.width;
            _contents.y = (1.0 - scale) / 2.0 * _body.height;
        }

        private function setStateTexture(texture:Texture):void
        {
            _body.texture = texture ? texture : _upState;

            if (_body.pivotX || _body.pivotY)
            {
                // The texture might force a custom pivot point on the image. We better use
                // this pivot point on the button itself, because that's easier to access.
                // (Plus, it simplifies internal object placement.)

                pivotX = _body.pivotX;
                pivotY = _body.pivotY;

                _body.pivotX = 0;
                _body.pivotY = 0;
            }
        }

        /** The scale factor of the button on touch. Per default, a button without a down state
         *  texture will be made slightly smaller, while a button with a down state texture
         *  remains unscaled. */
        public function get scaleWhenDown():Number { return _scaleWhenDown; }
        public function set scaleWhenDown(value:Number):void { _scaleWhenDown = value; }

        /** The scale factor of the button while the mouse cursor hovers over it. @default 1.0 */
        public function get scaleWhenOver():Number { return _scaleWhenOver; }
        public function set scaleWhenOver(value:Number):void { _scaleWhenOver = value; }

        /** The alpha value of the button on touch. @default 1.0 */
        public function get alphaWhenDown():Number { return _alphaWhenDown; }
        public function set alphaWhenDown(value:Number):void { _alphaWhenDown = value; }

        /** The alpha value of the button when it is disabled. @default 0.5 */
        public function get alphaWhenDisabled():Number { return _alphaWhenDisabled; }
        public function set alphaWhenDisabled(value:Number):void { _alphaWhenDisabled = value; }
        
        /** Indicates if the button can be triggered. */
        public function get enabled():Boolean { return _behavior.enabled; }
        public function set enabled(value:Boolean):void { _behavior.enabled = value; }

        /** The text that is displayed on the button. */
        public function get text():String { return _textField ? _textField.text : ""; }
        public function set text(value:String):void
        {
            if (value.length == 0)
            {
                if (_textField)
                {
                    _textField.text = value;
                    _textField.removeFromParent();
                }
            }
            else
            {
                createTextField();
                _textField.text = value;
                
                if (_textField.parent == null)
                    _contents.addChild(_textField);
            }
        }

        /** The format of the button's TextField. */
        public function get textFormat():TextFormat
        {
            if (_textField == null) createTextField();
            return _textField.format;
        }

        public function set textFormat(value:TextFormat):void
        {
            if (_textField == null) createTextField();
            _textField.format = value;
        }

        /** The style that is used to render the button's TextField. */
        public function get textStyle():MeshStyle
        {
            if (_textField == null) createTextField();
            return _textField.style;
        }

        public function set textStyle(value:MeshStyle):void
        {
            if (_textField == null) createTextField();
            _textField.style = value;
        }

        /** The style that is used to render the button.
         *  Note that a style instance may only be used on one mesh at a time. */
        public function get style():MeshStyle { return _body.style; }
        public function set style(value:MeshStyle):void { _body.style = value; }

        /** The texture that is displayed when the button is not being touched. */
        public function get upState():Texture { return _upState; }
        public function set upState(value:Texture):void
        {
            if (value == null)
                throw new ArgumentError("Texture 'upState' cannot be null");

            if (_upState != value)
            {
                _upState = value;
                var state:String = _behavior.state;

                if ( state == ButtonState.UP ||
                    (state == ButtonState.DISABLED && _disabledState == null) ||
                    (state == ButtonState.DOWN && _downState == null) ||
                    (state == ButtonState.OVER && _overState == null))
                {
                    setStateTexture(value);
                }
            }
        }
        
        /** The texture that is displayed while the button is touched. */
        public function get downState():Texture { return _downState; }
        public function set downState(value:Texture):void
        {
            if (_downState != value)
            {
                _downState = value;
                if (state == ButtonState.DOWN) setStateTexture(value);
            }
        }

        /** The texture that is displayed while mouse hovers over the button. */
        public function get overState():Texture { return _overState; }
        public function set overState(value:Texture):void
        {
            if (_overState != value)
            {
                _overState = value;
                if (state == ButtonState.OVER) setStateTexture(value);
            }
        }

        /** The texture that is displayed when the button is disabled. */
        public function get disabledState():Texture { return _disabledState; }
        public function set disabledState(value:Texture):void
        {
            if (_disabledState != value)
            {
                _disabledState = value;
                if (state == ButtonState.DISABLED) setStateTexture(value);
            }
        }
        
        /** The bounds of the button's TextField. Allows moving the text to a custom position.
         *  CAUTION: not a copy, but the actual object! Text will only update on re-assignment.
         */
        public function get textBounds():Rectangle { return _textBounds; }
        public function set textBounds(value:Rectangle):void
        {
            _textBounds.copyFrom(value);
            createTextField();
        }
        
        /** The color of the button's state image. Just like every image object, each pixel's
         *  color is multiplied with this value. @default white */
        public function get color():uint { return _body.color; }
        public function set color(value:uint):void { _body.color = value; }

        /** The smoothing type used for the button's state image. */
        public function get textureSmoothing():String { return _body.textureSmoothing; }
        public function set textureSmoothing(value:String):void { _body.textureSmoothing = value; }

        /** The overlay sprite is displayed on top of the button contents. It scales with the
         *  button when pressed. Use it to add additional objects to the button (e.g. an icon). */
        public function get overlay():Sprite
        {
            if (_overlay == null)
                _overlay = new Sprite();

            _contents.addChild(_overlay); // make sure it's always on top
            return _overlay;
        }

        /** Indicates if the mouse cursor should transform into a hand while it's over the button. 
         *  @default true */
        public override function get useHandCursor():Boolean { return _behavior.useHandCursor; }
        public override function set useHandCursor(value:Boolean):void
        {
            _behavior.useHandCursor = value;
        }

        /** Controls whether or not the instance snaps to the nearest pixel. This can prevent the
         *  object from looking blurry when it's not exactly aligned with the pixels of the screen.
         *  @default true */
        public function get pixelSnapping():Boolean { return _body.pixelSnapping; }
        public function set pixelSnapping(value:Boolean):void
        {
            _body.pixelSnapping = value;
            if (_textField) _textField.pixelSnapping = value;
        }

        /** @private */
        override public function set width(value:Number):void
        {
            // The Button might use a Scale9Grid ->
            // we must update the body width/height manually for the grid to scale properly.

            var newWidth:Number = value / (this.scaleX || 1.0);
            var scale:Number = newWidth / (_body.width || 1.0);

            _body.width = newWidth;
            _textBounds.x *= scale;
            _textBounds.width *= scale;

            if (_textField) _textField.width = newWidth;
        }

        /** @private */
        override public function set height(value:Number):void
        {
            var newHeight:Number = value /  (this.scaleY || 1.0);
            var scale:Number = newHeight / (_body.height || 1.0);

            _body.height = newHeight;
            _textBounds.y *= scale;
            _textBounds.height *= scale;

            if (_textField) _textField.height = newHeight;
        }

        /** The current scaling grid used for the button's state image. Use this property to create
         *  buttons that resize in a smart way, i.e. with the four corners keeping the same size
         *  and only stretching the center area.
         *
         *  @see Image#scale9Grid
         *  @default null
         */
        public function get scale9Grid():Rectangle { return _body.scale9Grid; }
        public function set scale9Grid(value:Rectangle):void { _body.scale9Grid = value; }

        /** The button's hit area will be extended to have at least this width / height.
         *  @default on Desktop: 16, on mobile: 44 */
        public function get minHitAreaSize():Number { return _behavior.minHitAreaSize; }
        public function set minHitAreaSize(value:Number):void { _behavior.minHitAreaSize = value; }

        /** The distance you can move away your finger before triggering is aborted.
         *  @default 50 */
        public function get abortDistance():Number { return _behavior.abortDistance; }
        public function set abortDistance(value:Number):void { _behavior.abortDistance = value; }
    }
}