package
{
    import starling.assets.AssetManager;
    import starling.core.Starling;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.ResizeEvent;

    /** The Root class is the topmost display object in your game.
     *  It is responsible for switching between game and menu. For this, it listens to
     *  "START_GAME" and "GAME_OVER" events fired by the Menu and Game classes.
     *  In other words, this class is supposed to control the high level behaviour of your game.
     */
    public class Root extends Sprite
    {
        private static var sAssets:AssetManager;

        private var _activeScene:Scene;
        
        public function Root()
        {
            addEventListener(Menu.START_GAME, onStartGame);
            addEventListener(Game.GAME_OVER,  onGameOver);
            
            // not more to do here -- Startup will call "start" immediately.
        }
        
        public function start(assets:AssetManager):void
        {
            // the asset manager is saved as a static variable; this allows us to easily access
            // all the assets from everywhere by simply calling "Root.assets"

            sAssets = assets;
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
            _activeScene.init(stage.stageWidth, stage.stageHeight);
        }

        public function onResize(event:ResizeEvent):void
        {
            var current:Starling = Starling.current;
            var scale:Number = current.contentScaleFactor;

            stage.stageWidth  = event.width  / scale;
            stage.stageHeight = event.height / scale;

            current.viewPort.width  = stage.stageWidth  * scale;
            current.viewPort.height = stage.stageHeight * scale;

            if (_activeScene)
                _activeScene.resizeTo(stage.stageWidth, stage.stageHeight);
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
    }
}