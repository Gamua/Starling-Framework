package
{
    import flash.geom.Rectangle;

    import starling.assets.AssetManager;
    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.Event;

    import utils.SafeAreaOverlay;
    import utils.ScreenSetup;

    /** The Root class is the topmost display object in your game.
     *  It is responsible for switching between game and menu. For this, it listens to
     *  "START_GAME" and "GAME_OVER" events fired by the Menu and Game classes.
     *  In other words, this class is supposed to control the high level behaviour of your game.
     */
    public class Root extends Sprite
    {
        private static var sAssets:AssetManager;
        private static var sScreen:ScreenSetup;

        private var _activeScene:Scene;
        private var _safeAreaOverlay:SafeAreaOverlay;

        public function Root()
        {
            addEventListener(Menu.START_GAME, onStartGame);
            addEventListener(Game.GAME_OVER,  onGameOver);
            
            // not more to do here -- Startup will call "start" immediately.
        }
        
        public function start(assets:AssetManager, screen:ScreenSetup):void
        {
            // the safe area overlay just shows us where the interactive content of our app
            // should be. Of course, this should be removed later. ;)

            _safeAreaOverlay = new SafeAreaOverlay();
            addChild(_safeAreaOverlay);

            // Asset manager and screen setup are saved as static variables; this allows us to
            // easily access them from everywhere by simply calling "Root.assets" or "Root.screen".
            // Especially important for the "safe area"!

            sAssets = assets;
            sScreen = screen;
            showScene(Menu);

            // If you don't want to support auto-orientation, you can delete this event handler.
            // Don't forget to update the AIR XML accordingly ("aspectRatio" and "autoOrients").
            stage.addEventListener(Event.RESIZE, onResize);
        }

        private function showScene(scene:Class):void
        {
            if (_activeScene) _activeScene.removeFromParent(true);
            _activeScene = new scene() as Scene;

            if (_activeScene == null)
                throw new ArgumentError("Invalid scene: " + scene);

            addChild(_activeScene);
            _activeScene.init();
            updatePositions();
        }

        public function onResize():void
        {
            Starling.current.viewPort = sScreen.viewPort;
            stage.stageWidth  = sScreen.stageWidth;
            stage.stageHeight = sScreen.stageHeight;
            updatePositions();
        }

        private function updatePositions():void
        {
            const safeArea:Rectangle = sScreen.safeArea;
            if (_activeScene)
            {
                _activeScene.x = safeArea.x;
                _activeScene.y = safeArea.y;
                _activeScene.setSize(safeArea.width, safeArea.height);
            }

            _safeAreaOverlay.x = safeArea.x;
            _safeAreaOverlay.y = safeArea.y;
            _safeAreaOverlay.setSize(safeArea.width, safeArea.height);
        }

        private function onGameOver(event:Event, score:int):void
        {
            trace("Game Over! Score: " + score);
            showScene(Menu);
        }
        
        private function onStartGame(event:Event, gameMode:String):void
        {
            trace("Game starts! Mode: " + gameMode);
            showScene(Game);
        }
        
        public static function get assets():AssetManager { return sAssets; }
        public static function get screen():ScreenSetup { return sScreen; }
    }
}