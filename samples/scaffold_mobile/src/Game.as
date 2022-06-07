package 
{
    import starling.animation.Transitions;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.utils.deg2rad;

    /** The Game class represents the actual game. In this scaffold, it just displays a
     *  Starling that moves around fast. When the user touches the Starling, the game ends. */ 
    public class Game extends Scene
    {
        public static const GAME_OVER:String = "gameOver";
        
        private var _bird:Image;
        private var _tweenID:uint = 0;

        public function Game()
        { }
        
        override public function init():void
        {
            // Set up objects. 'this.stage' is available, but we don't know the scene size yet.

            _bird = new Image(Root.assets.getTexture("starling_rocket"));
            _bird.pivotX = _bird.width / 2;
            _bird.pivotY = _bird.height / 2;
            _bird.addEventListener(TouchEvent.TOUCH, onBirdTouched);
            addChild(_bird);
        }

        override public function updatePositions():void
        {
            // Set up positions.
            // => When this method is called, "sceneWidth" and "sceneHeight" are already set.
            // => They indicate the available "safe area".

            _bird.x = sceneWidth / 2.0;
            _bird.y = sceneHeight / 2.0;
            if (_tweenID == 0) moveBird();
        }

        private function moveBird():void
        {
            var scale:Number = Math.random() * 0.8 + 0.2;
            _tweenID = Starling.juggler.tween(_bird, Math.random() * 0.5 + 0.5, {
                x: Math.random() * sceneWidth,
                y: Math.random() * sceneHeight,
                scaleX: scale,
                scaleY: scale,
                rotation: Math.random() * deg2rad(180) - deg2rad(90),
                transition: Transitions.EASE_IN_OUT,
                onComplete: moveBird
            });
        }
        
        private function onBirdTouched(event:TouchEvent):void
        {
            if (event.getTouch(_bird, TouchPhase.BEGAN))
            {
                Root.assets.playSound("click");
                Starling.juggler.removeTweens(_bird);
                dispatchEventWith(GAME_OVER, true, 100);
            }
        }
    }
}