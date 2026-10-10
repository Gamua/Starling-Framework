package
{
    import flash.desktop.NativeApplication;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.InvokeEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.filesystem.File;

    import starling.core.Starling;
    import starling.events.Event;
    import starling.unit.GoldenImageStore;

    [SWF(width="800", height="800", frameRate="60", backgroundColor="#000000")]
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

            // command line arguments only arrive with the invoke event
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
        }

        private function onInvoke(event:InvokeEvent):void
        {
            NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, onInvoke);
            var recordGoldenImages:Boolean = event.arguments.indexOf("--record") != -1;

            // 'run.sh' passes one profile per run, so that profile-specific code paths get tested
            var profile:String = "auto";
            for each (var argument:String in event.arguments)
                if (argument.indexOf("--profile=") == 0) profile = argument.substr(10);

            // The app directory is the output folder ('out'), both in the IDE and with 'run.sh'.
            // Goldens are accessed in the source folder, so that recording updates the checked-in files.
            // Failures are kept per profile; otherwise, the next run would overwrite them.
            var appDir:File = new File(File.applicationDirectory.nativePath);
            var goldenImageStore:GoldenImageStore = new GoldenImageStore(
                appDir.resolvePath("../fixtures/golden"),
                appDir.resolvePath("golden-failures/" + profile));

            _starling = new Starling(TestSuite, stage, null, null, "auto", profile);
            _starling.addEventListener(Event.ROOT_CREATED, function(event:Event, root:TestSuite):void
            {
                root.start(goldenImageStore, recordGoldenImages);
            });
            _starling.start();
        }
    }
}