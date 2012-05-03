package 
{
    import flash.geom.Rectangle;
    
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.ResizeEvent;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;

    public class Game extends Sprite
    {
        private var mBackground:Image;
        private var mLogo:Image;
        
        public function Game()
        {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }
        
        private function onAddedToStage(event:Event):void
        {
            stage.addEventListener(Event.RESIZE, onResize);
            init();
        }
        
        private function onRemovedFromStage(event:Event):void
        {
            stage.removeEventListener(Event.RESIZE, onResize);
        }
        
        private function init():void
        {
            // this will size your stage to either 320x480 (iPhone) or 384x512 (iPad)
            updateStageSize();
            
            // the contentScaleFactor is calculated from stage size and viewport size
            Assets.contentScaleFactor = Starling.current.contentScaleFactor;
            
            // prepare assets
            Assets.prepareSounds();
            Assets.loadBitmapFonts();
            
            // add some content
            mBackground = new Image(Assets.getTexture("Background"));
            addChild(mBackground);
            
            mLogo = new Image(Assets.getAtlasTexture("logo"));
            mLogo.addEventListener(TouchEvent.TOUCH, onLogoTouched);
            addChild(mLogo);
            
            // ... and update their positions depending on the stage size
            alignObjects();
        }
        
        private function onResize(event:ResizeEvent):void
        {
            Starling.current.viewPort = new Rectangle(0, 0, event.width, event.height);
            updateStageSize();
            alignObjects();
        }
        
        private function onLogoTouched(event:TouchEvent):void
        {
            if (event.getTouch(mLogo, TouchPhase.BEGAN))
                Assets.getSound("Click").play();
        }
        
        private function updateStageSize():void
        {
            var screenSize:Rectangle = Starling.current.viewPort;
            var stageWidth:int, stageHeight:int;
            
            var shortSide:int = Math.min(screenSize.width, screenSize.height);
            var longSize:int  = Math.max(screenSize.width, screenSize.height);
            var isPortrait:Boolean = screenSize.width == shortSide;
            
            if (shortSide == 320 || shortSide == 640)
            {
                // iPhone
                stageWidth  = isPortrait ? 320 : 480;
                stageHeight = isPortrait ? 480 : 320;
            }
            else
            {
                // iPad
                stageWidth  = isPortrait ? 384 : 512;
                stageHeight = isPortrait ? 512 : 384;
            }
            
            stage.stageWidth  = stageWidth;
            stage.stageHeight = stageHeight;
        }
        
        private function alignObjects():void
        {
            var stageWidth:int  = stage.stageWidth;
            var stageHeight:int = stage.stageHeight;
            
            mLogo.x = int((stageWidth  - mLogo.width)  / 2);
            mLogo.y = int((stageHeight - mLogo.height) / 2);
            
            mBackground.x = int((stageWidth  - mBackground.width)  / 2);
            mBackground.y = int((stageHeight - mBackground.height) / 2);
        }
    }
}