package
{
    import flash.desktop.NativeApplication;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Rectangle;
    
    import starling.core.Starling;
    
    [SWF(frameRate="30", backgroundColor="#000")]
    public class Scaffold_Android extends Sprite
    {
        private var mStarling:Starling;
        
        public function Scaffold_Android()
        {
            // set general properties
            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            Starling.multitouchEnabled = true;  // useful on mobile devices
            Starling.handleLostContext = true;  // required on Android
            
            // create a suitable viewport for the screen size
            
            var screenWidth:int  = stage.fullScreenWidth;
            var screenHeight:int = stage.fullScreenHeight;
            var viewPort:Rectangle = new Rectangle();
            
            if (stage.fullScreenHeight / stage.fullScreenWidth < Constants.ASPECT_RATIO)
            {
                viewPort.height = screenHeight;
                viewPort.width  = int(viewPort.height / Constants.ASPECT_RATIO);
                viewPort.x = int((screenWidth - viewPort.width) / 2);
            }
            else
            {
                viewPort.width = screenWidth; 
                viewPort.height = int(viewPort.width * Constants.ASPECT_RATIO);
                viewPort.y = int((screenHeight - viewPort.height) / 2);
            }
            
            // Set up Starling
            
            mStarling = new Starling(Game, stage, viewPort);
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