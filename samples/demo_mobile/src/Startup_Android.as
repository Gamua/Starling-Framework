package
{
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    
    import starling.core.Starling;
    
    [SWF(width="320", height="480", frameRate="30", backgroundColor="#000000")]
    public class Startup_Android extends Sprite
    {
        private var mStarling:Starling;
        
        public function Startup_Android()
        {
            // This project requires that you add the "src" path of the normal Starling demo to 
            // this project, either by referencing it via a "source path", or by copying the 
            // files. The "media" folder of this project has to be added as a "source path" as
            // well, to make sure that the icon and startup images are added to the .apk package.
            
            // set general properties
            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            Starling.multitouchEnabled = true; // useful on mobile devices
            Starling.handleLostContext = true; // required on Android
            
            // create a suitable viewport for the screen size
            
            var viewPort:Rectangle = new Rectangle();
            
            if (stage.fullScreenHeight / stage.fullScreenWidth < 1.5)
            {
                viewPort.height = stage.fullScreenHeight;
                viewPort.width  = int(viewPort.height / 1.5);
                viewPort.x = int((stage.fullScreenWidth - viewPort.width) / 2);
            }
            else
            {            
                viewPort.width = stage.fullScreenWidth; 
                viewPort.height = int(viewPort.width * 1.5);
                viewPort.y = int((stage.fullScreenHeight - viewPort.height) / 2);
            }
            
            // initialize Starling
            
            mStarling = new Starling(Game, stage, viewPort);
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