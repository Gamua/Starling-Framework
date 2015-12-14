package scenes
{
    import starling.display.Button;
    import starling.display.Sprite;

    public class Scene extends Sprite
    {
        private var _backButton:Button;
        
        public function Scene()
        {
            // the main menu listens for TRIGGERED events, so we just need to add the button.
            // (the event will bubble up when it's dispatched.)
            
            _backButton = new Button(Game.assets.getTexture("button_back"), "Back");
            _backButton.x = Constants.CenterX - _backButton.width / 2;
            _backButton.y = Constants.GameHeight - _backButton.height + 1;
            _backButton.name = "backButton";
            addChild(_backButton);
        }
    }
}