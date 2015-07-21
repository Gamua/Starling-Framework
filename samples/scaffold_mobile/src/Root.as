package
{
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.utils.AssetManager;

    /** The Root class is the topmost display object in your game. It loads all the assets
     *  and displays a progress bar while this is happening. Later, it is responsible for
     *  switching between game and menu. For this, it listens to "START_GAME" and "GAME_OVER"
     *  events fired by the Menu and Game classes. Keep this class rather lightweight: it 
     *  controls the high level behaviour of your game. */
    public class Root extends Sprite
    {
        private static var sAssets:AssetManager;
        
        private var mActiveScene:Sprite;
        
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
            addChild(new Image(assets.getTexture("background")));
            showScene(Menu);
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
        
        private function showScene(screen:Class):void
        {
            if (mActiveScene) mActiveScene.removeFromParent(true);
            mActiveScene = new screen();
            addChild(mActiveScene);
        }
        
        public static function get assets():AssetManager { return sAssets; }
    }
}