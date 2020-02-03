package starling.utils
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;

    import starling.display.ButtonState;
    import starling.display.DisplayObject;
    import starling.events.Event;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;

    /** A utility class that can help with creating button-like display objects.
     *
     *  <p>When reacting to touch input, taps can easily be recognized through standard touch
     *  events via <code>TouchPhase.ENDED</code>. However, you often want a more elaborate kind of
     *  input handling, like that provide by Starling's <em>Button</em> class and its
     *  <em>TRIGGERED</em> event. It allows users to cancel a tap by moving the finger away from
     *  the object, for example; and it supports changing its appearance depending on its state.</p>
     *
     *  <p>Here is an example: a class that extends <em>TextField</em> and uses
     *  <em>ButtonBehavior</em> to add TRIGGER events and state-based coloring.</p>
     *
     *  <listing>
     *  public class TextButton extends TextField
     *  {
     *      private var _behavior:ButtonBehavior;
     *      private var _tint:uint = 0xffaaff;
     *      
     *      public function TextButton(width:int, height:int, text:String="",
     *                                 format:TextFormat=null, options:TextOptions=null)
     *      {
     *          super(width, height, text, format, options);
     *          _behavior = new ButtonBehavior(this, onStateChange);
     *      }
     *      
     *      private function onStateChange(state:String):void
     *      {
     *          if (state == ButtonState.DOWN) format.color = _tint;
     *          else format.color = 0xffffff;
     *      }
     *      
     *      public override function hitTest(localPoint:Point):DisplayObject
     *      {
     *          return _behavior.hitTest(localPoint);
     *      }
     *  }</listing>
     *
     *  <p>Instances of this class will now dispatch <em>Event.TRIGGERED</em> events (just like
     *  conventional buttons) and they will change their color when being touched.</p>
     */
    public class ButtonBehavior
    {
        // 'minHitAreaSize' defaults to 44 points, as recommended by Apple Human Interface Guidelines.
        // -> https://developer.apple.com/ios/human-interface-guidelines/visual-design/adaptivity-and-layout/

        private var _state:String;
        private var _target:DisplayObject;
        private var _triggerBounds:Rectangle;
        private var _minHitAreaSize:Number;
        private var _abortDistance:Number;
        private var _onStateChange:Function;
        private var _useHandCursor:Boolean;
        private var _enabled:Boolean;

        private static var sBounds:Rectangle = new Rectangle();

        /** Create a new ButtonBehavior.
         *
         * @param target           The object on which to listen for touch events.
         * @param onStateChange    This callback will be executed whenever the button's state ought
         *                         to change. <code>function(state:String):void</code>
         * @param minHitAreaSize   If the display area of 'target' is smaller than a square of this
         *                         size, its hit area will be extended accordingly.
         * @param abortDistance    The distance you can move away your finger before triggering
         *                         is aborted.
         */
        public function ButtonBehavior(target:DisplayObject, onStateChange:Function,
                                       minHitAreaSize:Number = 44, abortDistance:Number = 50)
        {
            if (target == null) throw new ArgumentError("target cannot be null");
            if (onStateChange == null) throw new ArgumentError("onStateChange cannot be null");

            _target = target;
            _target.addEventListener(TouchEvent.TOUCH, onTouch);
            _onStateChange = onStateChange;
            _minHitAreaSize = minHitAreaSize;
            _abortDistance = abortDistance;
            _triggerBounds = new Rectangle();
            _state = ButtonState.UP;
            _useHandCursor = true;
            _enabled = true;
        }

        private function onTouch(event:TouchEvent):void
        {
            Mouse.cursor = (_useHandCursor && _enabled && event.interactsWith(_target)) ?
                MouseCursor.BUTTON : MouseCursor.AUTO;

            var touch:Touch = event.getTouch(_target);
            var isWithinBounds:Boolean;

            if (!_enabled)
            {
                // do nothing
            }
            else if (touch == null)
            {
                state = ButtonState.UP;
            }
            else if (touch.phase == TouchPhase.HOVER)
            {
                state = ButtonState.OVER;
            }
            else if (touch.phase == TouchPhase.BEGAN && _state != ButtonState.DOWN)
            {
                _triggerBounds = _target.getBounds(_target.stage, _triggerBounds);
                _triggerBounds.inflate(_abortDistance, _abortDistance);

                state = ButtonState.DOWN;
            }
            else if (touch.phase == TouchPhase.MOVED)
            {
                isWithinBounds = _triggerBounds.contains(touch.globalX, touch.globalY);

                if (_state == ButtonState.DOWN && !isWithinBounds)
                {
                    // reset button when finger is moved too far away ...
                    state = ButtonState.UP;
                }
                else if (_state == ButtonState.UP && isWithinBounds)
                {
                    // ... and reactivate when the finger moves back into the bounds.
                    state = ButtonState.DOWN;
                }
            }
            else if (touch.phase == TouchPhase.ENDED && _state == ButtonState.DOWN)
            {
                state = ButtonState.UP;
                if (!touch.cancelled) _target.dispatchEventWith(Event.TRIGGERED, true);
            }
        }

        /** Forward your target's <code>hitTests</code> to this method to make sure that the hit
         *  area is extended to <code>minHitAreaSize</code>. */
        public function hitTest(localPoint:Point):DisplayObject
        {
            if (!_target.visible || !_target.touchable || !_target.hitTestMask(localPoint))
                return null;

            _target.getBounds(_target, sBounds);

            if (sBounds.width < _minHitAreaSize)
                sBounds.inflate((_minHitAreaSize - sBounds.width) / 2, 0);
            if (sBounds.height < _minHitAreaSize)
                sBounds.inflate(0, (_minHitAreaSize - sBounds.height) / 2);

            if (sBounds.containsPoint(localPoint)) return _target;
            else return null;
        }

        /** The current state of the button. The corresponding strings are found
         *  in the ButtonState class. */
        public function get state():String { return _state; }
        public function set state(value:String):void
        {
            if (_state != value)
            {
                if (ButtonState.isValid(value))
                {
                    _state = value;
                    execute(_onStateChange, value);
                }
                else throw new ArgumentError("Invalid button state: " + value);
            }
        }

        /** The target on which this behavior operates. */
        public function get target():DisplayObject { return _target; }

        /** The callback that is executed whenever the state changes.
         *  Format: <code>function(state:String):void</code>
         */
        public function get onStateChange():Function { return _onStateChange; }
        public function set onStateChange(value:Function):void { _onStateChange = value; }

        /** Indicates if the mouse cursor should transform into a hand while it's over the button.
         *  @default true */
        public function get useHandCursor():Boolean { return _useHandCursor; }
        public function set useHandCursor(value:Boolean):void { _useHandCursor = value; }

        /** Indicates if the button can be triggered. */
        public function get enabled():Boolean { return _enabled; }
        public function set enabled(value:Boolean):void
        {
            if (_enabled != value)
            {
                _enabled = value;
                state = value ? ButtonState.UP : ButtonState.DISABLED;
            }
        }

        /** The target's hit area will be extended to have at least this width / height. 
         *  Note that for this to work, you need to forward your hit tests to this class. */
        public function get minHitAreaSize():Number { return _minHitAreaSize; }
        public function set minHitAreaSize(value:Number):void { _minHitAreaSize = value; }

        /** The distance you can move away your finger before triggering is aborted. */
        public function get abortDistance():Number { return _abortDistance; }
        public function set abortDistance(value:Number):void { _abortDistance = value; }
    }
}
