package starling.unit
{
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.utils.Align;
    import starling.utils.Color;
    import starling.utils.StringUtil;

    public class SimpleTestGui extends TestGui
    {
        private static const LINE_HEIGHT:int = 10;
        private static const FONT_NAME:String = "mini";
        private static const FONT_SIZE:int = -1;

        private var _width:int;
        private var _height:int;
        private var _logLines:Sprite;
        private var _numLogLines:int;
        private var _statusInfo:TextField;

        public function SimpleTestGui(testRunner:TestRunner, width:int, height:int)
        {
            super(testRunner);

            _width = width;
            _height = height;

            _statusInfo = new TextField(width, LINE_HEIGHT, "");
            _statusInfo.format.setTo(FONT_NAME, FONT_SIZE, Color.WHITE);
            _statusInfo.format.horizontalAlign = Align.RIGHT;
            addChild(_statusInfo);

            _logLines = new Sprite();
            addChild(_logLines);
        }

        override public function log(message:String, color:uint=0xffffff):void
        {
            super.log(message, color);

            var logLine:TextField = new TextField(_width, LINE_HEIGHT, message);
            logLine.format.setTo(FONT_NAME, FONT_SIZE, color);
            logLine.format.horizontalAlign = Align.LEFT;
            logLine.y = _numLogLines * LINE_HEIGHT;
            _logLines.addChild(logLine);
            _numLogLines++;

            if (_numLogLines * LINE_HEIGHT > _height)
            {
                _logLines.removeChildAt(0);
                _logLines.y -= LINE_HEIGHT;
            }
        }

        override public function assert(success:Boolean, message:String=null):void
        {
            super.assert(success, message);

            _statusInfo.text = StringUtil.format("Passed {0} of {1} tests", successCount, testCount);
            _statusInfo.format.color = (successCount == testCount) ? Color.GREEN : Color.RED;
        }
    }
}