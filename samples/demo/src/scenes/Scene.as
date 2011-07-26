package scenes
{
    import starling.display.Button;
    import starling.display.Sprite;
    import starling.events.Event;
    
    public class Scene extends Sprite
    {
        public static const CLOSING:String = "closing";
        
        private var mBackButton:Button;
        
        public function Scene()
        {
            mBackButton = new Button(Assets.getTexture("ButtonBack"), "Back");
            mBackButton.x = Constants.CenterX - mBackButton.width / 2;
            mBackButton.y = Constants.GameHeight - mBackButton.height + 1;
            mBackButton.addEventListener(Event.TRIGGERED, onBackButtonTriggered);
            addChild(mBackButton);
        }
        
        private function onBackButtonTriggered(event:Event):void
        {
            mBackButton.removeEventListener(Event.TRIGGERED, onBackButtonTriggered);
            dispatchEvent(new Event(CLOSING, true));
        }
    }
}