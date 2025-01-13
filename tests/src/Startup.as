package
{
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.UncaughtErrorEvent;

    import starling.core.Starling;

    [SWF(width="800", height="800", frameRate="20", backgroundColor="#000000")]
    public class Startup extends Sprite
    {
        private var _starling:Starling;

        public function Startup()
        {
            loaderInfo.uncaughtErrorEvents.addEventListener (
                UncaughtErrorEvent.UNCAUGHT_ERROR, function(event:UncaughtErrorEvent):void
                {
                    trace(event.error, "Uncaught Error: " + event.error.message);
                }
            );

            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            _starling = new Starling(TestSuite, stage);
            _starling.start();
        }
    }
}