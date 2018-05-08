package scenes
{
    import flash.geom.Rectangle;

    import starling.display.Button;
    import starling.display.Sprite;

    import utils.MenuButton;

    public class Scene extends Sprite
    {
        private var _backButton:Button;
        
        public function Scene()
        {
            // the main menu listens for TRIGGERED events, so we just need to add the button.
            // (the event will bubble up when it's dispatched.)
            
            _backButton = new MenuButton("Back", 88, 50);
            _backButton.x = Constants.CenterX - _backButton.width / 2;
            _backButton.y = Constants.GameHeight - _backButton.height + 12;
            _backButton.name = "backButton";
            _backButton.textBounds.y -= 3;
            _backButton.readjustSize(); // forces textBounds to update

            addChild(_backButton);
        }
    }
}