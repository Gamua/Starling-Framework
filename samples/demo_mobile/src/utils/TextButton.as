package utils
{
    import flash.geom.Point;

    import starling.display.ButtonState;
    import starling.display.DisplayObject;
    import starling.text.TextField;
    import starling.text.TextFormat;
    import starling.text.TextOptions;
    import starling.utils.ButtonBehavior;

    /** This class shows how to use "ButtonBehavior": you add the behavior as instance member
     *  and react to state changes in a custom callback. Furthermore, you forward hit tests.
     *  As a result, the class will dispatch "TRIGGERED" events and will allow users to cancel
     *  the touch by moving away the finger before lifting it.
     */
    public class TextButton extends TextField
    {
        private var _behavior:ButtonBehavior;
        private var _tint:uint = 0xffc0ff;

        public function TextButton(width:int, height:int, text:String="",
                                   format:TextFormat=null, options:TextOptions=null)
        {
            super(width, height, text, format, options);

            _behavior = new ButtonBehavior(this, onStateChange);

            batchable = true;
        }

        private function onStateChange(state:String):void
        {
            if (state == ButtonState.DOWN)
                format.color = _tint;
            else
                format.color = 0xffffff;
        }

        public override function hitTest(localPoint:Point):DisplayObject
        {
            return _behavior.hitTest(localPoint);
        }

        public function get tint():uint { return _tint; }
        public function set tint(value:uint):void { _tint = value; }
    }
}
