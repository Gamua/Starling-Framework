package scenes
{
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.Button;
    import starling.display.Image;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.utils.Color;
    import starling.utils.deg2rad;

    import utils.MenuButton;

    public class AnimationScene extends Scene
    {
        private var _startButton:Button;
        private var _delayButton:Button;
        private var _egg:Image;
        private var _transitionLabel:TextField;
        private var _transitions:Array;
        
        public function AnimationScene()
        {
            _transitions = [Transitions.LINEAR, Transitions.EASE_IN_OUT,
                            Transitions.EASE_OUT_BACK, Transitions.EASE_OUT_BOUNCE,
                            Transitions.EASE_OUT_ELASTIC];
            
            // create a button that starts the tween
            _startButton = new MenuButton("Start animation");
            _startButton.addEventListener(Event.TRIGGERED, onStartButtonTriggered);
            _startButton.x = Constants.CenterX - int(_startButton.width / 2);
            _startButton.y = 20;
            addChild(_startButton);
            
            // this button will show you how to call a method with a delay
            _delayButton = new MenuButton("Delayed call");
            _delayButton.addEventListener(Event.TRIGGERED, onDelayButtonTriggered);
            _delayButton.x = _startButton.x;
            _delayButton.y = _startButton.y + 40;
            addChild(_delayButton);
            
            // the Starling will be tweened
            _egg = new Image(Game.assets.getTexture("starling_front"));
            addChild(_egg);
            resetEgg();
            
            _transitionLabel = new TextField(320, 30);
            _transitionLabel.format.size = 20;
            _transitionLabel.format.bold = true;
            _transitionLabel.y = _delayButton.y + 40;
            _transitionLabel.alpha = 0.0; // invisible, will be shown later
            addChild(_transitionLabel);
        }
        
        private function resetEgg():void
        {
            _egg.x = 20;
            _egg.y = 100;
            _egg.scaleX = _egg.scaleY = 1.0;
            _egg.rotation = 0.0;
        }
        
        private function onStartButtonTriggered():void
        {
            _startButton.enabled = false;
            resetEgg();
            
            // get next transition style from array and enqueue it at the end
            var transition:String = _transitions.shift();
            _transitions.push(transition);
            
            // to animate any numeric property of an arbitrary object (not just display objects!), 
            // you can create a 'Tween'. One tween object animates one target for a certain time, 
            // a with certain transition function.
            var tween:Tween = new Tween(_egg, 2.0, transition);
            
            // you can animate any property as long as it's numeric (int, uint, Number). 
            // it is animated from it's current value to a target value.  
            tween.animate("rotation", deg2rad(90)); // conventional 'animate' call
            tween.moveTo(300, 360);                 // convenience method for animating 'x' and 'y'
            tween.scaleTo(0.5);                     // convenience method for 'scaleX' and 'scaleY'
            tween.onComplete = function():void { _startButton.enabled = true; };
            
            // the tween alone is useless -- for an animation to be carried out, it has to be 
            // advance once in every frame.            
            // This is done by the 'Juggler'. It receives the tween and will carry it out.
            // We use the default juggler here, but you can create your own jugglers, as well.            
            // That way, you can group animations into logical parts.  
            Starling.juggler.add(tween);
            
            // show which tweening function is used
            _transitionLabel.text = transition;
            _transitionLabel.alpha = 1.0;
            
            var hideTween:Tween = new Tween(_transitionLabel, 2.0, Transitions.EASE_IN);
            hideTween.animate("alpha", 0.0);
            Starling.juggler.add(hideTween);
        }
        
        private function onDelayButtonTriggered():void
        {
            _delayButton.enabled = false;
            
            // Using the juggler, you can delay a method call. This is especially useful when
            // you use your own juggler in a component of your game, because it gives you perfect 
            // control over the flow of time and animations. 
            
            Starling.juggler.delayCall(colorizeEgg, 1.0, true);
            Starling.juggler.delayCall(colorizeEgg, 2.0, false);
            Starling.juggler.delayCall(function():void { _delayButton.enabled = true; }, 2.0);
        }
        
        private function colorizeEgg(colorize:Boolean):void
        {
            _egg.color = colorize ? Color.RED : Color.WHITE;
        }
        
        public override function dispose():void
        {
            _startButton.removeEventListener(Event.TRIGGERED, onStartButtonTriggered);
            _delayButton.removeEventListener(Event.TRIGGERED, onDelayButtonTriggered);
            super.dispose();
        }
    }
}