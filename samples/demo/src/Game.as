package 
{
    import flash.ui.Keyboard;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
    import scenes.AnimationScene;
    import scenes.BenchmarkScene;
    import scenes.CustomHitTestScene;
    import scenes.MovieScene;
    import scenes.RenderTextureScene;
    import scenes.Scene;
    import scenes.TextScene;
    import scenes.TextureScene;
    import scenes.TouchScene;
    
    import starling.core.Starling;
    import starling.display.BlendMode;
    import starling.display.Button;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.VAlign;

    public class Game extends Sprite
    {
        private var mMainMenu:Sprite;
        private var mCurrentScene:Scene;
        
        public function Game()
        {
            // The following settings are for mobile development (iOS, Android):
            //
            // You develop your game in a *fixed* coordinate system of 320x480; the game might 
            // then run on a device with a different resolution, and the assets class will
            // provide textures in the most suitable format.
            
            Starling.current.stage.stageWidth  = 320;
            Starling.current.stage.stageHeight = 480;
            Assets.contentScaleFactor = Starling.current.contentScaleFactor;
            
            // load general assets
            
            Assets.prepareSounds();
            Assets.loadBitmapFonts();
            
            // create and show menu screen
            
            var bg:Image = new Image(Assets.getTexture("Background"));
            bg.blendMode = BlendMode.NONE;
            addChild(bg);
            
            mMainMenu = new Sprite();
            addChild(mMainMenu);
            
            var logo:Image = new Image(Assets.getTexture("Logo"));
            mMainMenu.addChild(logo);
            
            var scenesToCreate:Array = [
                ["Textures", TextureScene],
                ["Multitouch", TouchScene],
                ["TextFields", TextScene],
                ["Animations", AnimationScene],
                ["Custom hit-test", CustomHitTestScene],
                ["Movie Clip", MovieScene],
                ["Benchmark", BenchmarkScene],
                ["Render Texture", RenderTextureScene]
            ];
            
            var buttonTexture:Texture = Assets.getTexture("ButtonBig");
            var count:int = 0;
            
            for each (var sceneToCreate:Array in scenesToCreate)
            {
                var sceneTitle:String = sceneToCreate[0];
                var sceneClass:Class  = sceneToCreate[1];
                
                var button:Button = new Button(buttonTexture, sceneTitle);
                button.x = count % 2 == 0 ? 28 : 167;
                button.y = 180 + int(count / 2) * 52;
                button.name = getQualifiedClassName(sceneClass);
                button.addEventListener(Event.TRIGGERED, onButtonTriggered);
                mMainMenu.addChild(button);
                ++count;
            }
            
            addEventListener(Scene.CLOSING, onSceneClosing);
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            
            // show information about rendering method (hardware/software)
            
            var driverInfo:String = Starling.context.driverInfo;
            var infoText:TextField = new TextField(310, 64, driverInfo, "Verdana", 10);
            infoText.x = 5;
            infoText.y = 475 - infoText.height;
            infoText.vAlign = VAlign.BOTTOM;
            infoText.touchable = false;
            mMainMenu.addChild(infoText);
        }
        
        private function onAddedToStage(event:Event):void
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
        }
        
        private function onRemovedFromStage(event:Event):void
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
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
            showScene(button.name);
        }
        
        private function onSceneClosing(event:Event):void
        {
            mCurrentScene.removeFromParent(true);
            mCurrentScene = null;
            mMainMenu.visible = true;
        }
        
        private function showScene(name:String):void
        {
            if (mCurrentScene) return;
            
            var sceneClass:Class = getDefinitionByName(name) as Class;
            mCurrentScene = new sceneClass() as Scene;
            mMainMenu.visible = false;
            addChild(mCurrentScene);
        }
    }
}