package 
{
    import flash.geom.Rectangle;
    import flash.system.System;
    import flash.ui.Keyboard;
    import flash.utils.getDefinitionByName;
    
    import scenes.Scene;
    
    import starling.core.Starling;
    import starling.display.Button;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.events.TouchEvent;
    import starling.filters.ColorMatrixFilter;
    import starling.textures.Texture;
    import starling.utils.AssetManager;
    
    import utils.ProgressBar;

    public class Game extends Sprite
    {
        // Embed the Ubuntu Font. Beware: the 'embedAsCFF'-part IS REQUIRED!!!
        [Embed(source="../../demo/assets/fonts/Ubuntu-R.ttf", embedAsCFF="false", fontFamily="Ubuntu")]
        private static const UbuntuRegular:Class;
        
        private var mLoadingProgress:ProgressBar;
        private var mMainMenu:MainMenu;
        private var mCurrentScene:Scene;
        private var _container:Sprite;
        
        private static var sAssets:AssetManager;
        
        public function Game()
        {
            // nothing to do here -- Startup will call "start" immediately.
        }
                
        private function addFilterQuad( _x:Number, _y:Number ):void 
        {
            var quad:Quad = new Quad( 160, 160, 0xffffff * Math.random() );
            quad.x = _x;
            quad.y = _y;
            quad.filter = new ColorMatrixFilter();
            
            _container.addChild(quad);
            
            quad.addEventListener(TouchEvent.TOUCH, function (e:TouchEvent):void
            {
                quad.y += 5;
            });
        }
        
        public function start(background:Texture, assets:AssetManager):void
        {
            this.x = 100;
            this.y = 100;
            
            _container = new Sprite();
            addChild(_container);
            
            addFilterQuad(0, 0.1);
//            addFilterQuad(0, 160);
//            addFilterQuad(0, 320);
//            addFilterQuad(0, 480.1);
            
            _container.clipRect = new Rectangle( 0, 0, 484, 480.2 );
            
            
            
            return;
            
            sAssets = assets;
            
            // The background is passed into this method for two reasons:
            // 
            // 1) we need it right away, otherwise we have an empty frame
            // 2) the Startup class can decide on the right image, depending on the device.
            
            addChild(new Image(background));
            
            // The AssetManager contains all the raw asset data, but has not created the textures
            // yet. This takes some time (the assets might be loaded from disk or even via the
            // network), during which we display a progress indicator. 
            
            mLoadingProgress = new ProgressBar(175, 20);
            mLoadingProgress.x = (background.width  - mLoadingProgress.width) / 2;
            mLoadingProgress.y = background.height * 0.7;
            addChild(mLoadingProgress);
            
            assets.loadQueue(function(ratio:Number):void
            {
                mLoadingProgress.ratio = ratio;

                // a progress bar should always show the 100% for a while,
                // so we show the main menu only after a short delay. 
                
                if (ratio == 1)
                    Starling.juggler.delayCall(function():void
                    {
                        mLoadingProgress.removeFromParent(true);
                        mLoadingProgress = null;
                        showMainMenu();
                    }, 0.15);
            });
            
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