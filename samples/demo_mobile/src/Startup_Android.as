package
{
    import flash.desktop.NativeApplication;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;
    
    import starling.core.Starling;
    import starling.utils.RectangleUtil;
    
    [SWF(width="320", height="480", frameRate="30", backgroundColor="#000000")]
    public class Startup_Android extends Sprite
    {
        private var mStarling:Starling;
        
        public function Startup_Android()
        {
            // This project requires the sources of the "demo" project. Add them either by 
            // referencing the "demo/src" directory as a "source path", or by copying the files.
            // The "media" folder of this project has to be added to its "source paths" as well, 
            // to make sure the icon and startup images are added to the compiled mobile app.
            
            Starling.multitouchEnabled = true; // useful on mobile devices
            Starling.handleLostContext = true; // required on Android
            
            // create a suitable viewport for the screen size
            //
            // we develop the game in a *fixed* coordinate system of 320x480; the game might 
            // then run on a device with a different resolution; for that case, we zoom the 
            // viewPort to the optimal size for any display and load the optimal textures.
            
            var stageWidth:int  = 320;
            var stageHeight:int = 480;
            var viewPort:Rectangle = RectangleUtil.fit(
                new Rectangle(0, 0, stageWidth, stageHeight), 
                new Rectangle(0, 0, stage.fullScreenWidth, stage.fullScreenHeight), true);
            
            // initialize Starling
            
            mStarling = new Starling(Game, stage, viewPort);
            mStarling.stage.stageWidth  = stageWidth;
            mStarling.stage.stageHeight = stageHeight;
            mStarling.simulateMultitouch  = false;
            mStarling.enableErrorChecking = false;
            mStarling.start();
            
            // When the game becomes inactive, we pause Starling; otherwise, the enter frame event
            // would report a very long 'passedTime' when the app is reactivated. 
            
            NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, 
                function (e:Event):void { mStarling.start(); });
            
            NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, 
                function (e:Event):void { mStarling.stop(); });
        }
    }
}