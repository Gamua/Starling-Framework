package 
{
    import starling.animation.Transitions;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.utils.deg2rad;

    /** The Game class represents the actual game. In this scaffold, it just displays a 
     *  Starling that moves around fast. When the user touches the Starling, the game ends. */ 
    public class Game extends Sprite
    {
        public static const GAME_OVER:String = "gameOver";
        
        private var mBird:Image;
        
        public function Game()
        {
            init();
        }
        
        private function init():void
        {
            mBird = new Image(Root.assets.getTexture("starling_rocket"));
            mBird.pivotX = mBird.width / 2;
            mBird.pivotY = mBird.height / 2;
            mBird.x = Constants.STAGE_WIDTH / 2;
            mBird.y = Constants.STAGE_HEIGHT / 2;
            mBird.addEventListener(TouchEvent.TOUCH, onBirdTouched);
            addChild(mBird);
            
            moveBird();
        }
        
        private function moveBird():void
        {
            var scale:Number = Math.random() * 0.8 + 0.2;
            
            Starling.juggler.tween(mBird, Math.random() * 0.5 + 0.5, {
                x: Math.random() * Constants.STAGE_WIDTH,
                y: Math.random() * Constants.STAGE_HEIGHT,
                scaleX: scale,
                scaleY: scale,
                rotation: Math.random() * deg2rad(180) - deg2rad(90),
                transition: Transitions.EASE_IN_OUT,
                onComplete: moveBird
            });
        }
        
        private function onBirdTouched(event:TouchEvent):void
        {
            if (event.getTouch(mBird, TouchPhase.BEGAN))
            {
                Root.assets.playSound("click");
                Starling.juggler.removeTweens(mBird);
                dispatchEventWith(GAME_OVER, true, 100);
            }
        }
    }
}