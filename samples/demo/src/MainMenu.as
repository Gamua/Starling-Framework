package
{
    import flash.utils.getQualifiedClassName;
    
    import scenes.AnimationScene;
    import scenes.BenchmarkScene;
    import scenes.BlendModeScene;
    import scenes.CustomHitTestScene;
    import scenes.FilterScene;
    import scenes.MaskScene;
    import scenes.MovieScene;
    import scenes.RenderTextureScene;
    import scenes.TextScene;
    import scenes.TextureScene;
    import scenes.TouchScene;
    
    import starling.core.Starling;
    import starling.display.Button;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.VAlign;

    public class MainMenu extends Sprite
    {
        public function MainMenu()
        {
            init();
        }
        
        private function init():void
        {
            var logo:Image = new Image(Game.assets.getTexture("logo"));
            addChild(logo);
            
            var scenesToCreate:Array = [
                ["Textures", TextureScene],
                ["Multitouch", TouchScene],
                ["TextFields", TextScene],
                ["Animations", AnimationScene],
                ["Custom hit-test", CustomHitTestScene],
                ["Movie Clip", MovieScene],
                ["Filters", FilterScene],
                ["Blend Modes", BlendModeScene],
                ["Render Texture", RenderTextureScene],
                ["Benchmark", BenchmarkScene],
                ["Clipping", MaskScene]
            ];
            
            var buttonTexture:Texture = Game.assets.getTexture("button_medium");
            var count:int = 0;
            
            for each (var sceneToCreate:Array in scenesToCreate)
            {
                var sceneTitle:String = sceneToCreate[0];
                var sceneClass:Class  = sceneToCreate[1];
                
                var button:Button = new Button(buttonTexture, sceneTitle);
                button.x = count % 2 == 0 ? 28 : 167;
                button.y = 155 + int(count / 2) * 46;
                button.name = getQualifiedClassName(sceneClass);
                addChild(button);
                
                if (scenesToCreate.length % 2 != 0 && count % 2 == 1)
                    button.y += 24;
                
                ++count;
            }
            
            // show information about rendering method (hardware/software)
            
            var driverInfo:String = Starling.context.driverInfo;
            var infoText:TextField = new TextField(310, 64, driverInfo, "Verdana", 10);
            infoText.x = 5;
            infoText.y = 475 - infoText.height;
            infoText.vAlign = VAlign.BOTTOM;
            infoText.addEventListener(TouchEvent.TOUCH, onInfoTextTouched);
            addChildAt(infoText, 0);
        }
        
        private function onInfoTextTouched(event:TouchEvent):void
        {
            if (event.getTouch(this, TouchPhase.ENDED))
                Starling.current.showStats = !Starling.current.showStats;
        }
    }
}