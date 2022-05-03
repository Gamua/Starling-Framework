package
{
    import starling.events.Event;
    import starling.text.BitmapFont;
    import starling.text.TextField;

    import utils.MenuButton;

    /** The Menu shows the logo of the game and a start button that will, once triggered,
     *  start the actual game. In a real game, it will probably contain several buttons and
     *  link to several screens (e.g. a settings screen or the credits). If your menu contains
     *  a lot of logic, you could use the "Feathers" library to make your life easier. */
    public class Menu extends Scene
    {
        public static const START_GAME:String = "startGame";

        private var _textField:TextField;
        private var _menuButton:MenuButton;

        public function Menu()
        { }

        override public function init():void
        {
            // Set up objects. 'this.stage' is available, but we don't know the scene size yet.

            _textField = new TextField(250, 50, "Game Scaffold");
            _textField.format.setTo("Desyrel", BitmapFont.NATIVE_SIZE, 0xffffff);
            addChild(_textField);

            _menuButton = new MenuButton("Start", 150, 40);
            _menuButton.textFormat.setTo("Ubuntu", 16);
            _menuButton.addEventListener(Event.TRIGGERED, onButtonTriggered);
            addChild(_menuButton);
        }

        override public function updatePositions():void
        {
            // Set up positions.
            // => When this method is called, "sceneWidth" and "sceneHeight" are set.

            _textField.x = (sceneWidth - _textField.width) / 2;
            _textField.y = sceneHeight * 0.1;

            _menuButton.x = (sceneWidth - _menuButton.width) / 2;
            _menuButton.y = sceneHeight * 0.9 - _menuButton.height;
        }
        
        private function onButtonTriggered():void
        {
            dispatchEventWith(START_GAME, true, "classic");
        }
    }
}