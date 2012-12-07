package scenes
{
    import starling.display.Button;
    import starling.display.Sprite;
    
    public class Scene extends Sprite
    {
        private var mBackButton:Button;
        
        public function Scene()
        {
            // the main menu listens for TRIGGERED events, so we just need to add the button.
            // (the event will bubble up when it's dispatched.)
            
            mBackButton = new Button(Game.assets.getTexture("button_back"), "Back");
            mBackButton.x = Constants.CenterX - mBackButton.width / 2;
            mBackButton.y = Constants.GameHeight - mBackButton.height + 1;
            mBackButton.name = "backButton";
            addChild(mBackButton);
        }
    }
}