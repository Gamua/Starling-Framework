package utils
{
    import starling.display.DisplayObjectContainer;
    import starling.display.Quad;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.utils.Align;

    public class SafeAreaOverlay extends DisplayObjectContainer
    {
        private var _topLeft:TextField;
        private var _bottomRight:TextField;
        private var _overlay:Quad;

        public function SafeAreaOverlay(color:uint = 0xff0000, alpha:Number = 0.1)
        {
            _overlay = new Quad(200, 200, color);
            _overlay.alpha = alpha;

            _topLeft = new TextField(100, 15, "top left");
            _topLeft.format.setTo(BitmapFont.MINI, BitmapFont.NATIVE_SIZE, 0x0, Align.LEFT, Align.TOP);

            _bottomRight = new TextField(100, 15, "bottom right");
            _bottomRight.format.setTo(BitmapFont.MINI, BitmapFont.NATIVE_SIZE, 0x0, Align.RIGHT, Align.BOTTOM);
            _bottomRight.alignPivot(Align.RIGHT, Align.BOTTOM);

            addChild(_overlay);
            addChild(_topLeft);
            addChild(_bottomRight);

            touchable = false;
        }

        public function setSize(width:Number, height:Number):void
        {
            _overlay.width = width;
            _overlay.height = height;
            _bottomRight.x = width;
            _bottomRight.y = height;
        }
    }
}
