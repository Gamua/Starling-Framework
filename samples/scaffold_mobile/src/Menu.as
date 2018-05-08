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

        override public function init(width:Number, height:Number):void
        {
            super.init(width, height);

            _textField = new TextField(250, 50, "Game Scaffold");
            _textField.format.setTo("Desyrel", BitmapFont.NATIVE_SIZE, 0xffffff);
            addChild(_textField);

            _menuButton = new MenuButton("Start", 150, 40);
            _menuButton.textFormat.setTo("Ubuntu", 16);
            _menuButton.addEventListener(Event.TRIGGERED, onButtonTriggered);
            addChild(_menuButton);

            updatePositions();
        }

        override public function resizeTo(width:Number, height:Number):void
        {
            super.resizeTo(width, height);
            updatePositions();
        }

        private function updatePositions():void
        {
            _textField.x = (_width - _textField.width) / 2;
            _textField.y = _height * 0.1;

            _menuButton.x = (_width - _menuButton.width) / 2;
            _menuButton.y = _height * 0.9 - _menuButton.height;
        }
        
        private function onButtonTriggered():void
        {
            dispatchEventWith(START_GAME, true, "classic");
        }
    }
}