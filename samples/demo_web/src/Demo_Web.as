package 
{
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.system.Capabilities;
    import flash.system.System;
    import flash.utils.setTimeout;

    import starling.assets.AssetManager;
    import starling.core.Starling;
    import starling.events.Event;

    import utils.ProgressBar;

    // If you set this class as your 'default application', it will run without a preloader.
    // To use a preloader, see 'Demo_Web_Preloader.as'.

    // This project requires the sources of the "demo" project. Add them either by
    // referencing the "demo/src" directory as a "source path", or by copying the files.
    // The "media" folder of this project has to be added to its "source paths" as well,
    // to make sure the icon and startup images are added to the compiled mobile app.
    
    [SWF(width="320", height="480", frameRate="60", backgroundColor="#222222")]
    public class Demo_Web extends Sprite
    {
        private var _starling:Starling;
        private var _background:Bitmap;
        private var _progressBar:ProgressBar;

        public function Demo_Web()
        {
            if (stage) start();
            else addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(event:Object):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            start();
        }

        private function start():void
        {
            // We develop the game in a *fixed* coordinate system of 320x480. The game might
            // then run on a device with a different resolution; for that case, we zoom the
            // viewPort to the optimal size for any display and load the optimal textures.

            Starling.multitouchEnabled = true; // for Multitouch Scene

            _starling = new Starling(Game, stage);
            _starling.simulateMultitouch = true;
            _starling.skipUnchangedFrames = true;
            _starling.supportBrowserZoom = true;
            _starling.supportHighResolutions = true;
            _starling.enableErrorChecking = Capabilities.isDebugger;
            _starling.addEventListener(Event.ROOT_CREATED, function():void
            {
                loadAssets(startGame);
            });

            _starling.start();
            initElements();
        }

        private function loadAssets(onComplete:Function):void
        {
            // Our assets are loaded and managed by the 'AssetManager'. To use that class,
            // we first have to enqueue pointers to all assets we want it to load.

            var assets:AssetManager = new AssetManager();

            assets.verbose = Capabilities.isDebugger;
            assets.enqueue(EmbeddedAssets);

            // Now, while the AssetManager now contains pointers to all the assets, it actually
            // has not loaded them yet. This happens in the "loadQueue" method; and since this
            // will take a while, we'll update the progress bar accordingly.

            assets.loadQueue(onLoadComplete, onLoadError, onLoadProgress);

            function onLoadComplete():void
            {
                // now would be a good time for a clean-up
                System.pauseForGCIfCollectionImminent(0);
                System.gc();

                onComplete(assets);
            }

            function onLoadError(error:String):void
            {
                trace("Error while loading assets: " + error);
            }

            function onLoadProgress(ratio:Number):void
            {
                _progressBar.ratio = ratio;
            }
        }

        private function startGame(assets:AssetManager):void
        {
            var game:Game = _starling.root as Game;
            game.start(assets);
            setTimeout(removeElements, 150); // delay to make 100% sure there's no flickering.
        }

        private function initElements():void
        {
            // Add background image.

            _background = new EmbeddedAssets.background();
            _background.smoothing = true;
            addChild(_background);

            // While the assets are loaded, we will display a progress bar.

            _progressBar = new ProgressBar(175, 20);
            _progressBar.x = (_background.width - _progressBar.width) / 2;
            _progressBar.y =  _background.height * 0.7;
            addChild(_progressBar);
        }

        private function removeElements():void
        {
            if (_background)
            {
                removeChild(_background);
                _background = null;
            }

            if (_progressBar)
            {
                removeChild(_progressBar);
                _progressBar = null;
            }
        }
    }
}