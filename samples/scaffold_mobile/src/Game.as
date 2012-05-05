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
    import starling.utils.deg2rad;

    public class Game extends Sprite
    {
        private var mBackground:Image;
        private var mLogo:Image;
        
        public function Game()
        {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        private function onAddedToStage(event:Event):void
        {
            init();
        }
        
        private function init():void
        {
            // we create the game with a fixed stage size -- only the viewPort is variable.
            stage.stageWidth  = Constants.STAGE_WIDTH;
            stage.stageHeight = Constants.STAGE_HEIGHT;
            
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
            mLogo.x = int((Constants.STAGE_WIDTH  - mLogo.width)  / 2);
            mLogo.y = int((Constants.STAGE_HEIGHT - mLogo.height) / 2);
            addChild(mLogo);
        }
        
        private function onLogoTouched(event:TouchEvent):void
        {
            if (event.getTouch(mLogo, TouchPhase.BEGAN))
                Assets.getSound("Click").play();
        }
    }
}