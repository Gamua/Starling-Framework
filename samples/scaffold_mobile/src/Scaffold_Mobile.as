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
    
    [SWF(frameRate="30", backgroundColor="#000")]
    public class Scaffold_Mobile extends Sprite
    {
        private var mStarling:Starling;
        
        public function Scaffold_Mobile()
        {
            // set general properties
            
            var stageWidth:int   = Constants.STAGE_WIDTH;
            var stageHeight:int  = Constants.STAGE_HEIGHT;
            var screenWidth:int  = stage.fullScreenWidth;
            var screenHeight:int = stage.fullScreenHeight;
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
                new Rectangle(0, 0, screenWidth, screenHeight), true);
            
            // While Stage3D is initializing, the screen will be blank. To avoid any flickering, 
            // we display a startup image now and remove it below, when Starling is ready to go.
            // This is especially useful on iOS, where "Default.png" (or a variant) is displayed
            // during Startup. You can create an absolute seemless startup that way.
            
            var startupImage:Sprite = createStartupImage(viewPort, screenWidth > 320);
            addChild(startupImage);
            
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
                    removeChild(startupImage);
                    mStarling.start();
                });
            
            // When the game becomes inactive, we pause Starling; otherwise, the enter frame event
            // would report a very long 'passedTime' when the app is reactivated. 
            
            NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, 
                function (e:Event):void { mStarling.start(); });
            
            NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, 
                function (e:Event):void { mStarling.stop(); });
        }
        
        private function createStartupImage(viewPort:Rectangle, isHD:Boolean):Sprite
        {
            var sprite:Sprite = new Sprite();
            
            var background:Bitmap = isHD ?
                new AssetEmbeds_2x.Background() : new AssetEmbeds_1x.Background();
            
            var loadingIndicator:Bitmap = isHD ?
                new AssetEmbeds_2x.Loading() : new AssetEmbeds_1x.Loading();
            
            background.smoothing = true;
            sprite.addChild(background);
            
            loadingIndicator.smoothing = true;
            loadingIndicator.x = (background.width - loadingIndicator.width) / 2;
            loadingIndicator.y =  background.height * 0.75;
            sprite.addChild(loadingIndicator);
            
            sprite.x = viewPort.x;
            sprite.y = viewPort.y;
            sprite.width  = viewPort.width;
            sprite.height = viewPort.height;
            
            return sprite;
        }
    }
}