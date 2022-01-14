package
{
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.display.StageDisplayState;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.net.URLRequest;
    import flash.system.Capabilities;
    import flash.system.System;
    import flash.utils.setTimeout;

    import starling.assets.AssetManager;
    import starling.core.Starling;
    import starling.events.Event;
    import starling.utils.MathUtil;
    import starling.utils.StringUtil;
    import starling.utils.SystemUtil;

    import utils.ProgressBar;
    import utils.ScreenSetup;

    [SWF(width="320", height="480", frameRate="30", backgroundColor="#CFEAF9")]
    public class Scaffold extends Sprite
    {
        [Embed(source="../assets/fonts/Ubuntu-R.ttf", embedAsCFF="false", fontFamily="Ubuntu")]
        private static const UbuntuRegular:Class;

        private var _starling:Starling;
        private var _logo:Loader;
        private var _progressBar:ProgressBar;

        public function Scaffold()
        {
            var resX:int = Capabilities.screenResolutionX;
            var resY:int = Capabilities.screenResolutionY;
            var aspectRatio:Number = MathUtil.max(resX, resY) / MathUtil.min(resX, resY);

            // On long screens, use the additional space to show the status bar.
            // Otherwise, give the app access to as much space as possible.
            if (aspectRatio > 1.95)
                stage.displayState = StageDisplayState.NORMAL;
            else
                stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;

            // launch in next frame - that way, the stage has already been resized.
            setTimeout(launch, 40);
        }

        private function launch():void
        {
            // The "ScreenSetup" class is part of the "utils" package of this project.
            // It figures out the perfect scale factor and stage size for the given device.
            // The last parameter describes the available asset sets (here, '1x' and '2x').

            const screen:ScreenSetup = new ScreenSetup(stage, [1, 2]);

            Starling.multitouchEnabled = true; // we want to make use of multitouch

            _starling = new Starling(Root, stage, screen.viewPort);
            _starling.stage.stageWidth  = screen.stageWidth;
            _starling.stage.stageHeight = screen.stageHeight;
            _starling.skipUnchangedFrames = true;
            _starling.addEventListener(starling.events.Event.ROOT_CREATED, function():void
            {
                loadAssets(screen.assetScale,
                    function onAssetsLoaded(assets:AssetManager):void
                    {
                        startGame(assets, screen);
                    });
            });

            _starling.start();
            initLoadingScreen(screen.assetScale);

            // When the game becomes inactive, we pause Starling; otherwise, the enter frame event
            // would report a very long 'passedTime' when the app is reactivated.

            if (!SystemUtil.isDesktop)
            {
                NativeApplication.nativeApplication.addEventListener(
                    flash.events.Event.ACTIVATE, function (e:*):void { _starling.start(); });
                NativeApplication.nativeApplication.addEventListener(
                    flash.events.Event.DEACTIVATE, function (e:*):void { _starling.stop(true); });
            }
        }

        private function loadAssets(scale:int, onComplete:Function):void
        {
            // Our assets are loaded and managed by the 'AssetManager'. To use that class,
            // we first have to enqueue pointers to all assets we want it to load.

            var appDir:File = File.applicationDirectory;
            var assets:AssetManager = new AssetManager(scale);

            assets.verbose = Capabilities.isDebugger;
            assets.enqueue(
                appDir.resolvePath("assets/audio"),
                appDir.resolvePath(StringUtil.format("assets/fonts/{0}x",    scale)),
                appDir.resolvePath(StringUtil.format("assets/textures/{0}x", scale))
            );

            // Now, while the AssetManager now contains pointers to all the assets, it actually
            // has not loaded them yet. This happens in the "loadQueue" method; and since this
            // will take a while, we'll update the progress bar accordingly.

            assets.loadQueue(onAssetsLoaded, onAssetError, onAssetProgress);

            function onAssetsLoaded():void
            {
                // now would be a good time for a clean-up
                System.pauseForGCIfCollectionImminent(0);
                System.gc();

                onComplete(assets);
            }

            function onAssetError(error:String):void
            {
                trace("Error while loading assets: " + error);
            }

            function onAssetProgress(ratio:Number):void
            {
                _progressBar.ratio = ratio;
            }
        }

        private function startGame(assets:AssetManager, screen:ScreenSetup):void
        {
            var root:Root = _starling.root as Root;
            root.start(assets, screen);
            removeLoadingScreen();
        }

        private function initLoadingScreen(scale:int):void
        {
            var stageWidth:Number = _starling.stage.stageWidth;
            var stageHeight:Number = _starling.stage.stageHeight;

            // While the assets are loaded, we will display a progress bar ...

            _progressBar = new ProgressBar(175, 20);
            _progressBar.x = (stageWidth - _progressBar.width) / 2;
            _progressBar.y =  stageHeight * 0.8;

            // ... and a centered logo.

            var logoPath:String = StringUtil.format("assets/textures/{0}x/logo.png", scale);
            var logoFile:File = File.applicationDirectory.resolvePath(logoPath);

            _logo = new Loader();
            _logo.load(new URLRequest(logoFile.url));
            _logo.scaleX = 1.0 / scale;
            _logo.scaleY = 1.0 / scale;
            _logo.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE,
                function(e:Object):void
                {
                    (_logo.content as Bitmap).smoothing = true;
                    _logo.x = (stageWidth  - _logo.width)  / 2;
                    _logo.y = (stageHeight - _logo.height) / 2;

                    _starling.nativeOverlay.addChild(_logo);
                    _starling.nativeOverlay.addChild(_progressBar);
                });
        }

        private function removeLoadingScreen():void
        {
            if (_logo)
            {
                _starling.nativeOverlay.removeChild(_logo);
                _logo = null;
            }

            if (_progressBar)
            {
                _starling.nativeOverlay.removeChild(_progressBar);
                _progressBar = null;
            }
        }
    }
}