package
{
    import starling.display.Button;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    
    /** The Menu shows the logo of the game and a start button that will, once triggered, 
     *  start the actual game. In a real game, it will probably contain several buttons and
     *  link to several screens (e.g. a settings screen or the credits). If your menu contains
     *  a lot of logic, you could use the "Feathers" library to make your life easier. */
    public class Menu extends Sprite
    {
        public static const START_GAME:String = "startGame";
        
        public function Menu()
        {
            init();
        }
        
        private function init():void
        {
            var textField:TextField = new TextField(250, 50, "Game Scaffold", 
                "Desyrel", BitmapFont.NATIVE_SIZE, 0xffffff);
            textField.x = (Constants.STAGE_WIDTH - textField.width) / 2;
            textField.y = 50;
            addChild(textField);
            
            var button:Button = new Button(Root.assets.getTexture("button_normal"), "Start");
            button.fontName = "Ubuntu";
            button.fontSize = 16;
            button.x = int((Constants.STAGE_WIDTH - button.width) / 2);
            button.y = Constants.STAGE_HEIGHT * 0.75;
            button.addEventListener(Event.TRIGGERED, onButtonTriggered);
            addChild(button);
        }
        
        private function onButtonTriggered():void
        {
            dispatchEventWith(START_GAME, true, "classic");
        }
    }
}