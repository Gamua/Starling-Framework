package
{
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    
    import starling.core.Starling;
    
    [SWF(frameRate="30", backgroundColor="#000")]
    public class Scaffold_iOS extends Sprite
    {
        private var mStarling:Starling;
        
        public function Scaffold_iOS()
        {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            var screenWidth:int  = stage.fullScreenWidth;
            var screenHeight:int = stage.fullScreenHeight;
            
            // While Stage3D is initializing, the screen will be blank. To avoid any flickering, 
            // we display the background image for now, but will remove it when Starling
            // is ready to go.
            //
            // (Note that we *cannot* embed the "Default*.png" images, because then they won't
            //  be copied into the package any longer once they are embedded.)
            
            var startupBitmap:Bitmap = screenWidth <= 320 ?
                new AssetEmbeds_1x.Background() : new AssetEmbeds_2x.Background();

            startupBitmap.x = (screenWidth  - startupBitmap.width)  / 2;
            startupBitmap.y = (screenHeight - startupBitmap.height) / 2;
            
            addChild(startupBitmap);
            
            // Set up Starling.
            
            Starling.multitouchEnabled = true;  // useful on mobile devices
            Starling.handleLostContext = false; // not necessary on iOS. Saves a lot of memory!
            
            mStarling = new Starling(Game, stage, new Rectangle(0, 0, screenWidth, screenHeight));
            
            mStarling.stage3D.addEventListener(Event.CONTEXT3D_CREATE, function(e:Event):void 
            {
                // Starling is ready! We remove the startup image and start the game.
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