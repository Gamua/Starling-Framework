package
{
    import flash.desktop.NativeApplication;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Rectangle;
    
    import starling.core.Starling;
    
    [SWF(frameRate="30", backgroundColor="#000")]
    public class Scaffold_iOS extends Sprite
    {
        private var mStarling:Starling;
        
        public function Scaffold_iOS()
        {
            // set general properties
            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            Starling.multitouchEnabled = true;  // useful on mobile devices
            Starling.handleLostContext = false; // not necessary on iOS. Saves a lot of memory!
            
            // Create a suitable viewport for the screen size.
            // 
            // On the iPhone, the viewPort will fill the complete screen; on the iPad, there
            // will be black bars at the left and right, because it has a different aspect ratio.
            // Since the game is scaled up a little, it won't be as perfectly sharp as on the 
            // iPhone. Alernatively, you can exchange this code with the one used in the Starling
            // demo: it does not scale the viewPort, but adds bars on all sides.

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
            
            // While Stage3D is initializing, the screen will be blank. To avoid any flickering, 
            // we display a startup image for now, but will remove it when Starling is ready to go.
            //
            // (Note that we *cannot* embed the "Default*.png" images, because then they won't
            //  be copied into the package any longer once they are embedded.)
            
            var startupImage:Sprite = createStartupImage(viewPort, screenWidth > 320);
            addChild(startupImage);
            
            // Set up Starling
            
            mStarling = new Starling(Game, stage, viewPort);
            
            mStarling.stage3D.addEventListener(Event.CONTEXT3D_CREATE, function(e:Event):void 
            {
                // Starling is ready! We remove the startup image and start the game.
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