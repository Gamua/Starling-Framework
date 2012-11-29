package
{
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    
    import starling.core.Starling;
    import starling.utils.RectangleUtil;
    
    [SWF(width="320", height="480", frameRate="30", backgroundColor="#000000")]
    public class Startup_Mobile extends Sprite
    {
        private var mStarling:Starling;
        
        public function Startup_Mobile()
        {
            // This project requires the sources of the "demo" project. Add them either by 
            // referencing the "demo/src" directory as a "source path", or by copying the files.
            // The "media" folder of this project has to be added to its "source paths" as well, 
            // to make sure the icon and startup images are added to the compiled mobile app.
            
            // set general properties

            var stageWidth:int  = 320;
            var stageHeight:int = 480;
            var iOS:Boolean = Capabilities.manufacturer.indexOf("iOS") != -1;
            
            Starling.multitouchEnabled = true;  // useful on mobile devices
            Starling.handleLostContext = !iOS;  // not necessary on iOS. Saves a lot of memory!
            
            // create a suitable viewport for the screen size
            // 
            // we develop the game in a *fixed* coordinate system of 320x480; the game might 
            // then run on a device with a different resolution; for that case, we zoom the 
            // viewPort to the optimal size for any display and load the optimal textures.
            
            var viewPort:Rectangle = RectangleUtil.fit(
                new Rectangle(0, 0, stageWidth, stageHeight), 
                new Rectangle(0, 0, stage.fullScreenWidth, stage.fullScreenHeight), true);
            
            // While Stage3D is initializing, the screen will be blank. To avoid any flickering, 
            // we display a startup image now and remove it below, when Starling is ready to go.
            // This is especially useful on iOS, where "Default.png" (or a variant) is displayed
            // during Startup. You can create an absolute seemless startup that way.
            
            var startupBitmap:Bitmap = Capabilities.screenResolutionX <= 320 ?
                new AssetEmbeds_1x.Background() : new AssetEmbeds_2x.Background();
            startupBitmap.x = viewPort.x;
            startupBitmap.y = viewPort.y;
            startupBitmap.width  = viewPort.width;
            startupBitmap.height = viewPort.height;
            startupBitmap.smoothing = true;
            addChild(startupBitmap);
            
            // launch Starling
            
            mStarling = new Starling(Game, stage, viewPort);
            mStarling.stage.stageWidth  = stageWidth;  // <- same size on all devices!
            mStarling.stage.stageHeight = stageHeight; // <- same size on all devices!
            mStarling.simulateMultitouch  = false;
            mStarling.enableErrorChecking = false;

            mStarling.stage3D.addEventListener(Event.CONTEXT3D_CREATE, 
                function onContextCreated(e:Event):void 
                {
                    // Starling is ready! We remove the startup image and start the game.
                    mStarling.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated); 
                    removeChild(startupBitmap);
                    mStarling.start();
                });
            
            // When the game becomes inactive, we pause Starling; otherwise, the enter frame event
            // would report a very long 'passedTime' when the app is reactivated. 
            
            NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, 
                function (e:Event):void { mStarling.start(); });
            
            NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, 
                function (e:Event):void { mStarling.stop(); });
        }
    }
}