package
{
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.system.Capabilities;
    
    import starling.core.Starling;
    import starling.events.Event;
    
    [SWF(width="320", height="480", frameRate="30", backgroundColor="#222222")]
    public class Startup_iOS extends Sprite
    {
        private var mStarling:Starling;
        
        public function Startup_iOS()
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            // While Stage3D is initializing, the screen will be blank. To avoid any flickering, 
            // we display the background image for now, but will remove it below, when Starling
            // is ready to go.
            var startupBitmap:Bitmap = Capabilities.screenResolutionX <= 320 ?
                new AssetEmbeds_1x.Background() : new AssetEmbeds_2x.Background();
            addChild(startupBitmap);
            
            Starling.multitouchEnabled = true;  // useful on mobile devices
            Starling.handleLostContext = false; // deactivate on mobile devices (to save memory)
            
            mStarling = new Starling(Game, stage);
            mStarling.simulateMultitouch = true;
            mStarling.enableErrorChecking = false;
            mStarling.start();
            
            mStarling.addEventListener(Event.CONTEXT3D_CREATE, function(e:Event):void 
            {
                // Starling is ready! Remove the startup image.
                removeChild(startupBitmap);
            });
        }
    }
}