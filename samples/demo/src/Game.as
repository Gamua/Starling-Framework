package 
{
    import flash.system.System;
    import flash.ui.Keyboard;
    import flash.utils.getDefinitionByName;
    
    import scenes.Scene;
    
    import starling.core.Starling;
    import starling.display.Button;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.utils.AssetManager;

    public class Game extends Sprite
    {
        // Embed the Ubuntu Font. Beware: the 'embedAsCFF'-part IS REQUIRED!!!
        [Embed(source="../../demo/assets/fonts/Ubuntu-R.ttf", embedAsCFF="false", fontFamily="Ubuntu")]
        private static const UbuntuRegular:Class;
        
        private var mMainMenu:MainMenu;
        private var mCurrentScene:Scene;
        
        private static var sAssets:AssetManager;
        
        public function Game()
        {
            // nothing to do here -- Startup will call "start" immediately.
        }
        
        public function start(assets:AssetManager):void
        {
            sAssets = assets;
            addChild(new Image(assets.getTexture("background")));
            showMainMenu();

            addEventListener(Event.TRIGGERED, onButtonTriggered);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
        }
        
        private function showMainMenu():void
        {
            // now would be a good time for a clean-up 
            System.pauseForGCIfCollectionImminent(0);
            System.gc();
            
            if (mMainMenu == null)
                mMainMenu = new MainMenu();
            
            addChild(mMainMenu);
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.SPACE)
                Starling.current.showStats = !Starling.current.showStats;
            else if (event.keyCode == Keyboard.X)
                Starling.context.dispose();
        }
        
        private function onButtonTriggered(event:Event):void
        {
            var button:Button = event.target as Button;
            
            if (button.name == "backButton")
                closeScene();
            else
                showScene(button.name);
        }
        
        private function closeScene():void
        {
            mCurrentScene.removeFromParent(true);
            mCurrentScene = null;
            showMainMenu();
        }
        
        private function showScene(name:String):void
        {
            if (mCurrentScene) return;
            
            var sceneClass:Class = getDefinitionByName(name) as Class;
            mCurrentScene = new sceneClass() as Scene;
            mMainMenu.removeFromParent();
            addChild(mCurrentScene);
        }
        
        public static function get assets():AssetManager { return sAssets; }
    }
}