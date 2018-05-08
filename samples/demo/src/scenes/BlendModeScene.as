package scenes
{
    import starling.display.BlendMode;
    import starling.display.Button;
    import starling.display.Image;
    import starling.events.Event;
    import starling.text.TextField;

    import utils.MenuButton;

    public class BlendModeScene extends Scene
    {
        private var _button:Button;
        private var _image:Image;
        private var _infoText:TextField;
        
        private var _blendModes:Array = [
            BlendMode.NORMAL,
            BlendMode.MULTIPLY,
            BlendMode.SCREEN,
            BlendMode.ADD,
            BlendMode.ERASE,
            BlendMode.NONE
        ];
        
        public function BlendModeScene()
        {
            _button = new MenuButton("Switch Mode");
            _button.x = int(Constants.CenterX - _button.width / 2);
            _button.y = 15;
            _button.addEventListener(Event.TRIGGERED, onButtonTriggered);
            addChild(_button);
            
            _image = new Image(Game.assets.getTexture("starling_rocket"));
            _image.x = int(Constants.CenterX - _image.width / 2);
            _image.y = 170;
            addChild(_image);
            
            _infoText = new TextField(300, 32);
            _infoText.format.size = 19;
            _infoText.x = 10;
            _infoText.y = 330;
            addChild(_infoText);
            
            onButtonTriggered();
        }
        
        private function onButtonTriggered():void
        {
            var blendMode:String = _blendModes.shift() as String;
            _blendModes.push(blendMode);
            
            _infoText.text = blendMode;
            _image.blendMode = blendMode;
        }
    }
}